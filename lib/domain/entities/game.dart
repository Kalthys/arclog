import 'dart:math' as math;
import 'session.dart';
import 'achievement.dart';
import 'objective.dart';
import 'game_status.dart';

class Game {
  final int? id;
  final String title;
  final String? coverImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Session> sessions;
  final List<Achievement> achievements;
  final List<Objective> objectives;
  final GameStatus status;
  final String? platform;

  // ── Champs Steam ─────────────────────────────────────────────────────────
  final int? steamAppId;
  /// Dernier temps de jeu connu depuis Steam (en minutes).
  final int steamPlaytimeMinutes;
  /// URL de l'image de couverture Steam (header 460×215).
  final String? steamCoverUrl;

  const Game({
    this.id,
    required this.title,
    this.coverImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.sessions = const [],
    this.achievements = const [],
    this.objectives = const [],
    this.status = GameStatus.backlog,
    this.platform,
    this.steamAppId,
    this.steamCoverUrl,
    this.steamPlaytimeMinutes = 0,
  });

  // ── Temps de jeu ─────────────────────────────────────────────────────────

  int get _sessionMinutes =>
      sessions.fold(0, (sum, s) => sum + s.durationMinutes);

  /// Règle d'or : on prend le maximum entre les sessions manuelles et Steam.
  int get totalPlayTimeMinutes => math.max(_sessionMinutes, steamPlaytimeMinutes);

  // ── Achievements ──────────────────────────────────────────────────────────

  int get unlockedAchievementsCount =>
      achievements.where((a) => a.isUnlocked).length;

  double get achievementRatio => achievements.isEmpty
      ? 0.0
      : unlockedAchievementsCount / achievements.length;

  // ── Objectives ────────────────────────────────────────────────────────────

  int get completedObjectivesCount =>
      objectives.where((o) => o.isCompleted).length;

  double get objectiveRatio => objectives.isEmpty
      ? 0.0
      : completedObjectivesCount / objectives.length;

  // ── Progression globale ───────────────────────────────────────────────────

  double get progressRatio =>
      achievements.isNotEmpty ? achievementRatio : objectiveRatio;

  // ── copyWith ──────────────────────────────────────────────────────────────

  Game copyWith({
    int? id,
    String? title,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Session>? sessions,
    List<Achievement>? achievements,
    List<Objective>? objectives,
    GameStatus? status,
    String? platform,
    int? steamAppId,
    int? steamPlaytimeMinutes,
    String? steamCoverUrl,
  }) =>
      Game(
        id: id ?? this.id,
        title: title ?? this.title,
        coverImagePath: coverImagePath ?? this.coverImagePath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        sessions: sessions ?? this.sessions,
        achievements: achievements ?? this.achievements,
        objectives: objectives ?? this.objectives,
        status: status ?? this.status,
        platform: platform ?? this.platform,
        steamAppId: steamAppId ?? this.steamAppId,
        steamPlaytimeMinutes: steamPlaytimeMinutes ?? this.steamPlaytimeMinutes,
        steamCoverUrl: steamCoverUrl ?? this.steamCoverUrl,
      );

  @override
  bool operator ==(Object other) => other is Game && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
