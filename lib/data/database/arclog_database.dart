import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ArclogDatabase {
  ArclogDatabase._();
  static final ArclogDatabase instance = ArclogDatabase._();

  static const _dbName = 'arclog.db';
  static const _dbVersion = 10;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Création fraîche (v2) ────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games (
        id                     INTEGER PRIMARY KEY AUTOINCREMENT,
        title                  TEXT    NOT NULL,
        cover_path             TEXT,
        created_at             TEXT    NOT NULL,
        updated_at             TEXT    NOT NULL,
        status                 TEXT    NOT NULL DEFAULT 'backlog',
        platform               TEXT,
        steam_app_id           INTEGER,
        steam_playtime_minutes INTEGER NOT NULL DEFAULT 0,
        steam_cover_url        TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id          INTEGER NOT NULL,
        started_at       TEXT    NOT NULL,
        duration_minutes  INTEGER NOT NULL,
        notes             TEXT,
        screenshot_path   TEXT,
        tags              TEXT    NOT NULL DEFAULT '',
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');

    // Trophées officiels (API Steam à venir)
    await db.execute('''
      CREATE TABLE achievements (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id         INTEGER NOT NULL,
        title           TEXT    NOT NULL,
        description     TEXT,
        is_unlocked     INTEGER NOT NULL DEFAULT 0,
        unlocked_at     TEXT,
        steam_api_name  TEXT,
        icon_url        TEXT,
        is_favorite     INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');

    // Objectifs personnels de l'utilisateur
    await db.execute('''
      CREATE TABLE objectives (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id          INTEGER NOT NULL,
        title            TEXT    NOT NULL,
        description      TEXT,
        is_completed     INTEGER NOT NULL DEFAULT 0,
        completed_at     TEXT,
        created_at       TEXT    NOT NULL,
        target_quantity  INTEGER,
        current_quantity INTEGER NOT NULL DEFAULT 0,
        is_favorite      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_sessions_game     ON sessions(game_id)');
    await db.execute('CREATE INDEX idx_achievements_game ON achievements(game_id)');
    await db.execute('CREATE INDEX idx_objectives_game   ON objectives(game_id)');
  }

  // ── Migration v1 → v2 ────────────────────────────────────────────────────────
  //
  // v1 : table achievements = succès créés manuellement par l'utilisateur
  // v2 : ces données deviennent des "objectives" ; achievements = trophées Steam

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Créer la table objectives avec la structure de l'ancienne achievements
      await db.execute('''
        CREATE TABLE objectives (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          game_id      INTEGER NOT NULL,
          title        TEXT    NOT NULL,
          description  TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          created_at   TEXT    NOT NULL,
          FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
        )
      ''');

      // 2. Migrer les anciennes achievements → objectives
      //    (is_unlocked → is_completed, unlocked_at → completed_at)
      await db.execute('''
        INSERT INTO objectives (id, game_id, title, description,
                                is_completed, completed_at, created_at)
        SELECT id, game_id, title, description,
               is_unlocked, unlocked_at, datetime('now')
        FROM achievements
      ''');

      // 3. Supprimer l'ancienne table
      await db.execute('DROP TABLE achievements');

      // 4. Recréer achievements avec le nouveau schéma (champs Steam)
      await db.execute('''
        CREATE TABLE achievements (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          game_id         INTEGER NOT NULL,
          title           TEXT    NOT NULL,
          description     TEXT,
          is_unlocked     INTEGER NOT NULL DEFAULT 0,
          unlocked_at     TEXT,
          steam_api_name  TEXT,
          icon_url        TEXT,
          FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
          'CREATE INDEX idx_achievements_game ON achievements(game_id)');
      await db.execute(
          'CREATE INDEX idx_objectives_game   ON objectives(game_id)');
    }

    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE objectives ADD COLUMN target_quantity INTEGER');
      await db.execute(
          'ALTER TABLE objectives ADD COLUMN current_quantity INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE objectives ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE achievements ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 5) {
      await db.execute(
          "ALTER TABLE games ADD COLUMN status TEXT NOT NULL DEFAULT 'backlog'");
      await db.execute('ALTER TABLE games ADD COLUMN platform TEXT');
    }

    if (oldVersion < 6) {
      await db
          .execute('ALTER TABLE sessions ADD COLUMN screenshot_path TEXT');
    }

    if (oldVersion < 7) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sessions_game ON sessions(game_id)');
    }

    if (oldVersion < 8) {
      await db.execute('ALTER TABLE games ADD COLUMN steam_app_id INTEGER');
      await db.execute(
          'ALTER TABLE games ADD COLUMN steam_playtime_minutes INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 9) {
      await db.execute('ALTER TABLE games ADD COLUMN steam_cover_url TEXT');
    }

    if (oldVersion < 10) {
      await db.execute(
          "ALTER TABLE sessions ADD COLUMN tags TEXT NOT NULL DEFAULT ''");
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
