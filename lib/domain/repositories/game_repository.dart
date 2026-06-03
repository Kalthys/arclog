import '../entities/game.dart';
import '../entities/session.dart';
import '../entities/achievement.dart';
import '../entities/objective.dart';

abstract interface class GameRepository {
  // ── Games ──────────────────────────────────────────────────────────────────
  Future<List<Game>> getAllGames();
  Future<Game?> getGameById(int id);
  Future<int> insertGame(Game game);
  Future<void> updateGame(Game game);
  Future<void> deleteGame(int id);

  // ── Sessions ───────────────────────────────────────────────────────────────
  Future<List<Session>> getSessionsForGame(int gameId);
  Future<int> insertSession(Session session);
  Future<void> updateSession(Session session);
  Future<void> deleteSession(int id);

  // ── Achievements (trophées officiels — API Steam) ─────────────────────────
  Future<List<Achievement>> getAchievementsForGame(int gameId);
  Future<int> insertAchievement(Achievement achievement);
  Future<void> updateAchievement(Achievement achievement);
  Future<void> deleteAchievement(int id);

  // ── Objectives (quêtes personnelles utilisateur) ───────────────────────────
  Future<List<Objective>> getObjectivesForGame(int gameId);
  Future<int> insertObjective(Objective objective);
  Future<void> updateObjective(Objective objective);
  Future<void> deleteObjective(int id);

  // ── Steam ─────────────────────────────────────────────────────────────────

  /// Met à jour le steamPlaytimeMinutes d'un jeu (règle d'or : seulement si
  /// la valeur Steam est supérieure à l'actuelle).
  Future<void> updateSteamPlaytime(int gameId, int steamMinutes);

  /// Insère ou met à jour un trophée Steam identifié par [steamApiName].
  /// Si un achievement avec le même (gameId, steamApiName) existe déjà,
  /// il est mis à jour — sinon il est créé.
  Future<void> upsertSteamAchievement(Achievement achievement);
}
