import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_status.dart';
import '../../domain/entities/objective.dart';
import '../../domain/entities/session.dart';
import '../../data/services/steam_service.dart';
import 'game_providers.dart';
import 'player_providers.dart';
import 'steam_providers.dart';

class GameDetailNotifier extends FamilyAsyncNotifier<Game, int> {
  @override
  Future<Game> build(int gameId) async {
    final game = await ref.read(gameRepositoryProvider).getGameById(gameId);
    if (game == null) throw StateError('Game #$gameId not found');
    return game;
  }

  // ── Infos du jeu ───────────────────────────────────────────────────────────

  Future<void> updateGameInfo({
    required String title,
    String? newCoverPath,
    GameStatus? status,
    String? platform,
    int? steamAppId,
    bool clearSteamAppId = false,
  }) async {
    final game = await future;
    await ref.read(gameRepositoryProvider).updateGame(
          Game(
            id: game.id,
            title: title.trim(),
            coverImagePath: newCoverPath ?? game.coverImagePath,
            createdAt: game.createdAt,
            updatedAt: DateTime.now(),
            status: status ?? game.status,
            platform: platform != null
                ? (platform.trim().isEmpty ? null : platform.trim())
                : game.platform,
            steamAppId: clearSteamAppId ? null : (steamAppId ?? game.steamAppId),
            steamPlaytimeMinutes: game.steamPlaytimeMinutes,
          ),
        );
    _refresh();
  }

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<void> addSession({
    required int durationMinutes,
    String? notes,
    DateTime? startedAt,
    String? screenshotPath,
    List<String> tags = const [],
  }) async {
    final game = await future;
    await ref.read(gameRepositoryProvider).insertSession(
          Session(
            gameId: game.id!,
            startedAt: startedAt ?? DateTime.now(),
            durationMinutes: durationMinutes,
            notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
            screenshotPath: screenshotPath,
            tags: tags,
          ),
        );
    _refresh();
  }

  Future<void> updateSession({
    required Session original,
    required DateTime startedAt,
    required int durationMinutes,
    String? notes,
    String? screenshotPath,
    List<String> tags = const [],
  }) async {
    await ref.read(gameRepositoryProvider).updateSession(
          Session(
            id: original.id,
            gameId: original.gameId,
            startedAt: startedAt,
            durationMinutes: durationMinutes,
            notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
            screenshotPath: screenshotPath ?? original.screenshotPath,
            tags: tags,
          ),
        );
    _refresh();
  }

  Future<void> deleteSession(int sessionId) async {
    await ref.read(gameRepositoryProvider).deleteSession(sessionId);
    _refresh();
  }

  // ── Objectives (quêtes personnelles) ──────────────────────────────────────

  Future<void> addObjective(
    String title, {
    String? description,
    int? targetQuantity,
  }) async {
    final game = await future;
    await ref.read(gameRepositoryProvider).insertObjective(
          Objective(
            gameId: game.id!,
            title: title.trim(),
            description: description?.trim().isEmpty == true
                ? null
                : description?.trim(),
            createdAt: DateTime.now(),
            targetQuantity:
                (targetQuantity != null && targetQuantity > 0)
                    ? targetQuantity
                    : null,
          ),
        );
    _refresh();
  }

  Future<void> updateObjectiveInfo(
    Objective original, {
    required String title,
    String? description,
    int? targetQuantity,
  }) async {
    final newTarget =
        (targetQuantity != null && targetQuantity > 0) ? targetQuantity : null;
    final newQty =
        newTarget != null ? original.currentQuantity.clamp(0, newTarget) : 0;
    final completed = newTarget != null
        ? newQty >= newTarget
        : (newTarget == null && original.hasQuantity
            ? false
            : original.isCompleted);

    await ref.read(gameRepositoryProvider).updateObjective(
          Objective(
            id: original.id,
            gameId: original.gameId,
            title: title.trim(),
            description: description?.trim().isEmpty == true
                ? null
                : description?.trim(),
            isCompleted: completed,
            completedAt: completed
                ? (original.completedAt ?? DateTime.now())
                : null,
            createdAt: original.createdAt,
            targetQuantity: newTarget,
            currentQuantity: newQty,
            isFavorite: original.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> toggleObjective(Objective o) async {
    if (o.hasQuantity) return;
    final completing = !o.isCompleted;
    await ref.read(gameRepositoryProvider).updateObjective(
          Objective(
            id: o.id,
            gameId: o.gameId,
            title: o.title,
            description: o.description,
            isCompleted: completing,
            completedAt: completing ? DateTime.now() : null,
            createdAt: o.createdAt,
            targetQuantity: o.targetQuantity,
            currentQuantity: o.currentQuantity,
            isFavorite: o.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> incrementObjective(Objective o) async {
    if (!o.hasQuantity) return;
    final newQty = (o.currentQuantity + 1).clamp(0, o.targetQuantity!);
    final nowCompleted = newQty >= o.targetQuantity!;
    await ref.read(gameRepositoryProvider).updateObjective(
          Objective(
            id: o.id,
            gameId: o.gameId,
            title: o.title,
            description: o.description,
            isCompleted: nowCompleted,
            completedAt:
                nowCompleted && !o.isCompleted ? DateTime.now() : o.completedAt,
            createdAt: o.createdAt,
            targetQuantity: o.targetQuantity,
            currentQuantity: newQty,
            isFavorite: o.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> decrementObjective(Objective o) async {
    if (!o.hasQuantity || o.currentQuantity <= 0) return;
    final newQty = o.currentQuantity - 1;
    await ref.read(gameRepositoryProvider).updateObjective(
          Objective(
            id: o.id,
            gameId: o.gameId,
            title: o.title,
            description: o.description,
            isCompleted: false,
            completedAt: null,
            createdAt: o.createdAt,
            targetQuantity: o.targetQuantity,
            currentQuantity: newQty,
            isFavorite: o.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> toggleFavoriteObjective(Objective o) async {
    await ref.read(gameRepositoryProvider).updateObjective(
          Objective(
            id: o.id,
            gameId: o.gameId,
            title: o.title,
            description: o.description,
            isCompleted: o.isCompleted,
            completedAt: o.completedAt,
            createdAt: o.createdAt,
            targetQuantity: o.targetQuantity,
            currentQuantity: o.currentQuantity,
            isFavorite: !o.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> deleteObjective(int objectiveId) async {
    await ref.read(gameRepositoryProvider).deleteObjective(objectiveId);
    _refresh();
  }

  // ── Achievements (trophées officiels) ──────────────────────────────────────

  Future<void> addAchievement(String title, {String? description}) async {
    final game = await future;
    await ref.read(gameRepositoryProvider).insertAchievement(
          Achievement(
            gameId: game.id!,
            title: title.trim(),
            description: description?.trim().isEmpty == true
                ? null
                : description?.trim(),
          ),
        );
    _refresh();
  }

  Future<void> toggleAchievement(Achievement a) async {
    final unlocking = !a.isUnlocked;
    await ref.read(gameRepositoryProvider).updateAchievement(
          Achievement(
            id: a.id,
            gameId: a.gameId,
            title: a.title,
            description: a.description,
            isUnlocked: unlocking,
            unlockedAt: unlocking ? DateTime.now() : null,
            steamApiName: a.steamApiName,
            iconUrl: a.iconUrl,
            isFavorite: a.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> toggleFavoriteAchievement(Achievement a) async {
    await ref.read(gameRepositoryProvider).updateAchievement(
          Achievement(
            id: a.id,
            gameId: a.gameId,
            title: a.title,
            description: a.description,
            isUnlocked: a.isUnlocked,
            unlockedAt: a.unlockedAt,
            steamApiName: a.steamApiName,
            iconUrl: a.iconUrl,
            isFavorite: !a.isFavorite,
          ),
        );
    _refresh();
  }

  Future<void> deleteAchievement(int achievementId) async {
    await ref.read(gameRepositoryProvider).deleteAchievement(achievementId);
    _refresh();
  }

  // ── Rafraîchissement Steam ─────────────────────────────────────────────────

  /// Re-synchronise le temps de jeu et les succès depuis Steam pour ce jeu.
  /// Ne fait rien si le jeu n'a pas de steamAppId ou si Steam n'est pas configuré.
  Future<void> refreshFromSteam() async {
    final game = await future;
    if (game.steamAppId == null) return;

    final url     = await ref.read(vercelUrlProvider.future);
    final steamId = await ref.read(steamIdProvider.future);
    if (url.isEmpty || steamId.isEmpty) return;
    final service = SteamService(vercelBaseUrl: url);

    final repo = ref.read(gameRepositoryProvider);

    // ── Playtime ─────────────────────────────────────────────────────────
    try {
      final steamGames = (await service.fetchOwnedGames(steamId)).games;
      final steamGame = steamGames
          .where((g) => g.appId == game.steamAppId)
          .firstOrNull;
      if (steamGame != null &&
          steamGame.playtimeMinutes > game.steamPlaytimeMinutes) {
        await repo.updateSteamPlaytime(game.id!, steamGame.playtimeMinutes);
      }
    } catch (_) {
      // Erreur réseau : on continue sans bloquer
    }

    // ── Succès ────────────────────────────────────────────────────────────
    try {
      final steamAchs =
          await service.fetchAchievements(steamId, game.steamAppId!);
      for (final a in steamAchs) {
        await repo.upsertSteamAchievement(Achievement(
          gameId:       game.id!,
          title:        a.name,
          description:  a.description,
          isUnlocked:   a.unlocked,
          unlockedAt:   a.unlockedAt,
          steamApiName: a.apiName,
        ));
      }
    } catch (_) {
      // Jeu sans succès Steam : pas grave
    }

    _refresh();
  }

  // ── Interne ────────────────────────────────────────────────────────────────

  void _refresh() {
    ref.invalidateSelf();
    ref.invalidate(gamesProvider);
  }
}

final gameDetailProvider =
    AsyncNotifierProvider.family<GameDetailNotifier, Game, int>(
  GameDetailNotifier.new,
);
