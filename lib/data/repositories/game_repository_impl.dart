import '../../domain/entities/achievement.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_status.dart';
import '../../domain/entities/objective.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/game_repository.dart';
import '../services/steam_service.dart';
import '../sources/local_game_source.dart';

class GameRepositoryImpl implements GameRepository {
  final LocalGameSource _source;

  GameRepositoryImpl({LocalGameSource? source})
      : _source = source ?? LocalGameSource();

  // ── Games ──────────────────────────────────────────────────────────────────

  @override
  Future<List<Game>> getAllGames() async {
    final games = await _source.getAllGames();
    return Future.wait(games.map(_hydrate));
  }

  @override
  Future<Game?> getGameById(int id) async {
    final game = await _source.getGameById(id);
    return game == null ? null : _hydrate(game);
  }

  @override
  Future<int> insertGame(Game game) => _source.insertGame(game);

  @override
  Future<void> updateGame(Game game) =>
      _source.updateGame(game.copyWith(updatedAt: DateTime.now()));

  @override
  Future<void> deleteGame(int id) => _source.deleteGame(id);

  // ── Sessions ───────────────────────────────────────────────────────────────

  @override
  Future<List<Session>> getSessionsForGame(int gameId) =>
      _source.getSessionsForGame(gameId);

  @override
  Future<int> insertSession(Session session) =>
      _source.insertSession(session);

  @override
  Future<void> updateSession(Session session) =>
      _source.updateSession(session);

  @override
  Future<void> deleteSession(int id) => _source.deleteSession(id);

  // ── Achievements ───────────────────────────────────────────────────────────

  @override
  Future<List<Achievement>> getAchievementsForGame(int gameId) =>
      _source.getAchievementsForGame(gameId);

  @override
  Future<int> insertAchievement(Achievement achievement) =>
      _source.insertAchievement(achievement);

  @override
  Future<void> updateAchievement(Achievement achievement) =>
      _source.updateAchievement(achievement);

  @override
  Future<void> deleteAchievement(int id) => _source.deleteAchievement(id);

  // ── Objectives ─────────────────────────────────────────────────────────────

  @override
  Future<List<Objective>> getObjectivesForGame(int gameId) =>
      _source.getObjectivesForGame(gameId);

  @override
  Future<int> insertObjective(Objective objective) =>
      _source.insertObjective(objective);

  @override
  Future<void> updateObjective(Objective objective) =>
      _source.updateObjective(objective);

  @override
  Future<void> deleteObjective(int id) => _source.deleteObjective(id);

  // ── Steam ──────────────────────────────────────────────────────────────────

  @override
  Future<void> updateSteamPlaytime(int gameId, int steamMinutes) =>
      _source.updateSteamPlaytime(gameId, steamMinutes);

  @override
  Future<void> upsertSteamAchievement(Achievement achievement) =>
      _source.upsertSteamAchievement(achievement);

  /// Rafraîchit le playtime et les succès de tous les jeux déjà liés à Steam
  /// (ceux qui ont un steamAppId). N'importe aucun nouveau jeu.
  Future<SteamSyncResult> refreshAllLinked({
    required SteamService steamService,
    required String steamId,
  }) async {
    int updatedGames = 0;
    int updatedAchievements = 0;
    final errors = <String>[];

    final linkedGames = (await _source.getAllGames())
        .where((g) => g.id != null && g.steamAppId != null)
        .toList();

    if (linkedGames.isEmpty) {
      return SteamSyncResult(
        errors: ['Aucun jeu lié à Steam. Importe d\'abord des jeux via "Choisir les jeux Steam".'],
      );
    }

    final List<SteamGame> steamGames;
    try {
      steamGames = (await steamService.fetchOwnedGames(steamId)).games;
    } catch (e) {
      return SteamSyncResult(errors: ['Impossible de contacter Steam : $e']);
    }

    final steamByAppId = {for (final g in steamGames) g.appId: g};

    for (final local in linkedGames) {
      final steam = steamByAppId[local.steamAppId];
      if (steam == null) continue;

      // Construire l'URL header si pas encore sauvegardée
      if (local.steamCoverUrl == null) {
        final coverUrl =
            'https://cdn.cloudflare.steamstatic.com/steam/apps/${steam.appId}/header.jpg';
        await _source.updateGame(local.copyWith(steamCoverUrl: coverUrl));
      }

      if (steam.playtimeMinutes > local.steamPlaytimeMinutes) {
        await _source.updateSteamPlaytime(local.id!, steam.playtimeMinutes);
        updatedGames++;
      }

      try {
        final achs = await steamService.fetchAchievements(steamId, local.steamAppId!);
        for (final a in achs) {
          await _source.upsertSteamAchievement(Achievement(
            gameId:       local.id!,
            title:        a.name,
            description:  a.description,
            isUnlocked:   a.unlocked,
            unlockedAt:   a.unlockedAt,
            steamApiName: a.apiName,
          ));
          updatedAchievements++;
        }
      } catch (e) {
        errors.add('${local.title} — succès : $e');
      }
    }

    return SteamSyncResult(
      updatedGames: updatedGames,
      updatedAchievements: updatedAchievements,
      errors: errors,
    );
  }

  /// Importe uniquement les jeux [selectedGames] choisis par l'utilisateur.
  Future<SteamSyncResult> importSelectedGames({
    required SteamService steamService,
    required String steamId,
    required List<SteamGame> selectedGames,
  }) =>
      syncWithSteam(steamService, steamId,
          filterAppIds: selectedGames.map((g) => g.appId).toSet());

  /// Synchronise la bibliothèque Steam :
  /// - Les jeux déjà liés (steamAppId connu) ont leur playtime mis à jour.
  /// - Les jeux Steam inconnus en local sont créés automatiquement.
  /// - Les succès sont importés/mis à jour pour tous les jeux avec du playtime.
  /// Seuls les jeux avec playtime > 0 sont importés (évite les jeux jamais joués).
  Future<SteamSyncResult> syncWithSteam(
    SteamService steamService,
    String steamId, {
    Set<int>? filterAppIds,
  }) async {
    int importedGames = 0;
    int updatedGames = 0;
    int updatedAchievements = 0;
    final errors = <String>[];

    // 1. Récupérer tous les jeux possédés sur Steam
    final List<SteamGame> steamGames;
    try {
      steamGames = (await steamService.fetchOwnedGames(steamId)).games;
    } catch (e) {
      return SteamSyncResult(
        errors: ['Impossible de récupérer les jeux Steam : $e'],
      );
    }

    if (steamGames.isEmpty) {
      return SteamSyncResult(
        errors: ['Aucun jeu trouvé. Vérifie que ton profil Steam est public.'],
      );
    }

    // 2. Construire un index des jeux locaux par steamAppId (O(1) lookup)
    final localGames = await _source.getAllGames();
    final localByAppId = <int, Game>{
      for (final g in localGames)
        if (g.steamAppId != null) g.steamAppId!: g,
    };

    final now = DateTime.now();

    // 3. Traiter chaque jeu Steam (filtrés si appIds fournis)
    final toProcess = steamGames.where((g) =>
        g.playtimeMinutes > 0 &&
        (filterAppIds == null || filterAppIds.contains(g.appId)));
    for (final steam in toProcess) {
      int gameId;

      if (localByAppId.containsKey(steam.appId)) {
        // ── Jeu déjà connu localement : mise à jour du playtime ───────────
        final local = localByAppId[steam.appId]!;
        gameId = local.id!;

        if (steam.playtimeMinutes > local.steamPlaytimeMinutes) {
          await _source.updateSteamPlaytime(gameId, steam.playtimeMinutes);
          updatedGames++;
        }
      } else {
        // ── Nouveau jeu Steam → création d'une fiche locale ───────────────
        final newGame = Game(
          title: steam.name,
          createdAt: now,
          updatedAt: now,
          status: GameStatus.playing,
          platform: 'PC',
          steamAppId: steam.appId,
          steamPlaytimeMinutes: steam.playtimeMinutes,
          // Header officiel Steam (460×215) — pas besoin d'API, URL connue
          steamCoverUrl:
              'https://cdn.cloudflare.steamstatic.com/steam/apps/${steam.appId}/header.jpg',
        );
        gameId = await _source.insertGame(newGame);
        importedGames++;
      }

      // ── Synchronisation des succès ──────────────────────────────────────
      List<SteamAchievement> steamAchs;
      try {
        steamAchs =
            await steamService.fetchAchievements(steamId, steam.appId);
      } catch (e) {
        errors.add('${steam.name} — succès : $e');
        continue;
      }

      for (final sa in steamAchs) {
        await _source.upsertSteamAchievement(Achievement(
          gameId:       gameId,
          title:        sa.name,
          description:  sa.description,
          isUnlocked:   sa.unlocked,
          unlockedAt:   sa.unlockedAt,
          steamApiName: sa.apiName,
        ));
        updatedAchievements++;
      }
    }

    return SteamSyncResult(
      importedGames:       importedGames,
      updatedGames:        updatedGames,
      updatedAchievements: updatedAchievements,
      errors:              errors,
    );
  }

  // ── Hydratation ────────────────────────────────────────────────────────────

  Future<Game> _hydrate(Game game) async {
    final results = await Future.wait([
      _source.getSessionsForGame(game.id!),
      _source.getAchievementsForGame(game.id!),
      _source.getObjectivesForGame(game.id!),
    ]);
    return game.copyWith(
      sessions:     results[0] as List<Session>,
      achievements: results[1] as List<Achievement>,
      objectives:   results[2] as List<Objective>,
    );
  }
}
