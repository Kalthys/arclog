import 'package:sqflite/sqflite.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_status.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/objective.dart';
import '../database/arclog_database.dart';

class LocalGameSource {
  final ArclogDatabase _db;

  LocalGameSource({ArclogDatabase? db}) : _db = db ?? ArclogDatabase.instance;

  Future<Database> get _database => _db.database;

  // ── Games ──────────────────────────────────────────────────────────────────

  Future<List<Game>> getAllGames() async {
    final rows =
        await (await _database).query('games', orderBy: 'updated_at DESC');
    return rows.map(_gameFromRow).toList();
  }

  Future<Game?> getGameById(int id) async {
    final rows = await (await _database)
        .query('games', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _gameFromRow(rows.first);
  }

  Future<int> insertGame(Game game) async =>
      (await _database).insert('games', _gameToRow(game));

  Future<void> updateGame(Game game) async =>
      (await _database).update('games', _gameToRow(game),
          where: 'id = ?', whereArgs: [game.id]);

  Future<void> deleteGame(int id) async =>
      (await _database).delete('games', where: 'id = ?', whereArgs: [id]);

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<List<Session>> getSessionsForGame(int gameId) async {
    final rows = await (await _database).query('sessions',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'started_at DESC');
    return rows.map(_sessionFromRow).toList();
  }

  Future<int> insertSession(Session session) async =>
      (await _database).insert('sessions', _sessionToRow(session));

  Future<void> updateSession(Session session) async =>
      (await _database).update('sessions', _sessionToRow(session),
          where: 'id = ?', whereArgs: [session.id]);

  Future<void> deleteSession(int id) async =>
      (await _database).delete('sessions', where: 'id = ?', whereArgs: [id]);

  // ── Achievements (trophées officiels) ──────────────────────────────────────

  Future<List<Achievement>> getAchievementsForGame(int gameId) async {
    final rows = await (await _database).query('achievements',
        where: 'game_id = ?', whereArgs: [gameId], orderBy: 'id ASC');
    return rows.map(_achievementFromRow).toList();
  }

  Future<int> insertAchievement(Achievement a) async =>
      (await _database).insert('achievements', _achievementToRow(a));

  Future<void> updateAchievement(Achievement a) async =>
      (await _database).update('achievements', _achievementToRow(a),
          where: 'id = ?', whereArgs: [a.id]);

  Future<void> deleteAchievement(int id) async => (await _database)
      .delete('achievements', where: 'id = ?', whereArgs: [id]);

  // ── Objectives (quêtes personnelles) ──────────────────────────────────────

  Future<List<Objective>> getObjectivesForGame(int gameId) async {
    final rows = await (await _database).query('objectives',
        where: 'game_id = ?', whereArgs: [gameId], orderBy: 'id ASC');
    return rows.map(_objectiveFromRow).toList();
  }

  Future<int> insertObjective(Objective o) async =>
      (await _database).insert('objectives', _objectiveToRow(o));

  Future<void> updateObjective(Objective o) async =>
      (await _database).update('objectives', _objectiveToRow(o),
          where: 'id = ?', whereArgs: [o.id]);

  Future<void> deleteObjective(int id) async =>
      (await _database).delete('objectives', where: 'id = ?', whereArgs: [id]);

  // ── Steam ──────────────────────────────────────────────────────────────────

  /// Règle d'or : met à jour steam_playtime_minutes seulement si [steamMinutes]
  /// est supérieur à la valeur stockée.
  Future<void> updateSteamPlaytime(int gameId, int steamMinutes) async {
    final db = await _database;
    final rows = await db.query('games',
        columns: ['steam_playtime_minutes'],
        where: 'id = ?',
        whereArgs: [gameId]);
    if (rows.isEmpty) return;

    final current = (rows.first['steam_playtime_minutes'] as int?) ?? 0;
    if (steamMinutes <= current) return;

    await db.update(
      'games',
      {
        'steam_playtime_minutes': steamMinutes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [gameId],
    );
  }

  /// Insère ou met à jour un trophée Steam identifié par (gameId, steamApiName).
  Future<void> upsertSteamAchievement(Achievement a) async {
    final db = await _database;
    final existing = await db.query(
      'achievements',
      where: 'game_id = ? AND steam_api_name = ?',
      whereArgs: [a.gameId, a.steamApiName],
    );

    if (existing.isEmpty) {
      await db.insert('achievements', _achievementToRow(a));
    } else {
      final existingId = existing.first['id'] as int;
      await db.update(
        'achievements',
        _achievementToRow(a.copyWith(id: existingId)),
        where: 'id = ?',
        whereArgs: [existingId],
      );
    }
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  Game _gameFromRow(Map<String, Object?> r) => Game(
        id: r['id'] as int,
        title: r['title'] as String,
        coverImagePath: r['cover_path'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
        status: GameStatus.fromDbKey(r['status'] as String?),
        platform: r['platform'] as String?,
        steamAppId: r['steam_app_id'] as int?,
        steamPlaytimeMinutes: (r['steam_playtime_minutes'] as int?) ?? 0,
        steamCoverUrl: r['steam_cover_url'] as String?,
      );

  Map<String, Object?> _gameToRow(Game g) => {
        if (g.id != null) 'id': g.id,
        'title': g.title,
        'cover_path': g.coverImagePath,
        'created_at': g.createdAt.toIso8601String(),
        'updated_at': g.updatedAt.toIso8601String(),
        'status': g.status.dbKey,
        'platform': g.platform,
        'steam_app_id': g.steamAppId,
        'steam_playtime_minutes': g.steamPlaytimeMinutes,
        'steam_cover_url': g.steamCoverUrl,
      };

  Session _sessionFromRow(Map<String, Object?> r) => Session(
        id: r['id'] as int,
        gameId: r['game_id'] as int,
        startedAt: DateTime.parse(r['started_at'] as String),
        durationMinutes: r['duration_minutes'] as int,
        notes: r['notes'] as String?,
        screenshotPath: r['screenshot_path'] as String?,
        tags: _parseTags(r['tags'] as String?),
      );

  Map<String, Object?> _sessionToRow(Session s) => {
        if (s.id != null) 'id': s.id,
        'game_id': s.gameId,
        'started_at': s.startedAt.toIso8601String(),
        'duration_minutes': s.durationMinutes,
        'notes': s.notes,
        'screenshot_path': s.screenshotPath,
        'tags': s.tags.join(','),
      };

  static List<String> _parseTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',').where((t) => t.isNotEmpty).toList();
  }

  Achievement _achievementFromRow(Map<String, Object?> r) => Achievement(
        id: r['id'] as int,
        gameId: r['game_id'] as int,
        title: r['title'] as String,
        description: r['description'] as String?,
        isUnlocked: (r['is_unlocked'] as int) == 1,
        unlockedAt: r['unlocked_at'] != null
            ? DateTime.parse(r['unlocked_at'] as String)
            : null,
        steamApiName: r['steam_api_name'] as String?,
        iconUrl: r['icon_url'] as String?,
        isFavorite: (r['is_favorite'] as int?) == 1,
      );

  Map<String, Object?> _achievementToRow(Achievement a) => {
        if (a.id != null) 'id': a.id,
        'game_id': a.gameId,
        'title': a.title,
        'description': a.description,
        'is_unlocked': a.isUnlocked ? 1 : 0,
        'unlocked_at': a.unlockedAt?.toIso8601String(),
        'steam_api_name': a.steamApiName,
        'icon_url': a.iconUrl,
        'is_favorite': a.isFavorite ? 1 : 0,
      };

  Objective _objectiveFromRow(Map<String, Object?> r) => Objective(
        id: r['id'] as int,
        gameId: r['game_id'] as int,
        title: r['title'] as String,
        description: r['description'] as String?,
        isCompleted: (r['is_completed'] as int) == 1,
        completedAt: r['completed_at'] != null
            ? DateTime.parse(r['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(r['created_at'] as String),
        targetQuantity: r['target_quantity'] as int?,
        currentQuantity: (r['current_quantity'] as int?) ?? 0,
        isFavorite: (r['is_favorite'] as int?) == 1,
      );

  Map<String, Object?> _objectiveToRow(Objective o) => {
        if (o.id != null) 'id': o.id,
        'game_id': o.gameId,
        'title': o.title,
        'description': o.description,
        'is_completed': o.isCompleted ? 1 : 0,
        'completed_at': o.completedAt?.toIso8601String(),
        'created_at': o.createdAt.toIso8601String(),
        'target_quantity': o.targetQuantity,
        'current_quantity': o.currentQuantity,
        'is_favorite': o.isFavorite ? 1 : 0,
      };
}
