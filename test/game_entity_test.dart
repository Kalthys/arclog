import 'package:flutter_test/flutter_test.dart';
import 'package:arclog/domain/entities/achievement.dart';
import 'package:arclog/domain/entities/game.dart';
import 'package:arclog/domain/entities/game_status.dart';
import 'package:arclog/domain/entities/objective.dart';
import 'package:arclog/domain/entities/session.dart';

Game _makeGame({
  List<Session> sessions = const [],
  List<Achievement> achievements = const [],
  List<Objective> objectives = const [],
}) =>
    Game(
      id: 1,
      title: 'Test Game',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      sessions: sessions,
      achievements: achievements,
      objectives: objectives,
    );

Session _session(int minutes) => Session(
      gameId: 1,
      startedAt: DateTime(2024),
      durationMinutes: minutes,
    );

Achievement _achievement({required bool unlocked}) => Achievement(
      gameId: 1,
      title: 'Trophy',
      isUnlocked: unlocked,
    );

Objective _objective({required bool completed}) => Objective(
      gameId: 1,
      title: 'Quest',
      createdAt: DateTime(2024),
      isCompleted: completed,
    );

void main() {
  group('Game.totalPlayTimeMinutes', () {
    test('aucune session → 0', () {
      expect(_makeGame().totalPlayTimeMinutes, 0);
    });

    test('somme des durées', () {
      final game = _makeGame(sessions: [_session(30), _session(90)]);
      expect(game.totalPlayTimeMinutes, 120);
    });
  });

  group('Game.achievementRatio', () {
    test('aucun trophée → 0.0', () {
      expect(_makeGame().achievementRatio, 0.0);
    });

    test('tous débloqués → 1.0', () {
      final game = _makeGame(achievements: [
        _achievement(unlocked: true),
        _achievement(unlocked: true),
      ]);
      expect(game.achievementRatio, 1.0);
    });

    test('moitié débloquée → 0.5', () {
      final game = _makeGame(achievements: [
        _achievement(unlocked: true),
        _achievement(unlocked: false),
      ]);
      expect(game.achievementRatio, 0.5);
    });

    test('aucun débloqué → 0.0', () {
      final game = _makeGame(achievements: [
        _achievement(unlocked: false),
      ]);
      expect(game.achievementRatio, 0.0);
    });
  });

  group('Game.objectiveRatio', () {
    test('aucun objectif → 0.0', () {
      expect(_makeGame().objectiveRatio, 0.0);
    });

    test('tous complétés → 1.0', () {
      final game = _makeGame(objectives: [
        _objective(completed: true),
        _objective(completed: true),
      ]);
      expect(game.objectiveRatio, 1.0);
    });

    test('aucun complété → 0.0', () {
      final game = _makeGame(objectives: [
        _objective(completed: false),
      ]);
      expect(game.objectiveRatio, 0.0);
    });
  });

  group('Game.progressRatio', () {
    test('sans trophées → utilise objectiveRatio', () {
      final game = _makeGame(objectives: [
        _objective(completed: true),
        _objective(completed: false),
      ]);
      expect(game.progressRatio, game.objectiveRatio);
    });

    test('avec trophées → utilise achievementRatio', () {
      final game = _makeGame(
        achievements: [_achievement(unlocked: true)],
        objectives: [_objective(completed: false)],
      );
      expect(game.progressRatio, game.achievementRatio);
    });
  });

  group('Game.completedObjectivesCount / unlockedAchievementsCount', () {
    test('compte les objectifs complétés', () {
      final game = _makeGame(objectives: [
        _objective(completed: true),
        _objective(completed: false),
        _objective(completed: true),
      ]);
      expect(game.completedObjectivesCount, 2);
    });

    test('compte les trophées débloqués', () {
      final game = _makeGame(achievements: [
        _achievement(unlocked: true),
        _achievement(unlocked: false),
      ]);
      expect(game.unlockedAchievementsCount, 1);
    });
  });

  group('Game equality', () {
    test('égaux si même id', () {
      final a = Game(
          id: 42,
          title: 'A',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024));
      final b = Game(
          id: 42,
          title: 'B',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025));
      expect(a, b);
    });

    test('différents si ids différents', () {
      final a = Game(
          id: 1,
          title: 'A',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024));
      final b = Game(
          id: 2,
          title: 'A',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024));
      expect(a, isNot(b));
    });
  });

  group('Game.copyWith', () {
    test('les champs non spécifiés restent inchangés', () {
      final original = _makeGame();
      final copy = original.copyWith(title: 'Nouveau titre');
      expect(copy.title, 'Nouveau titre');
      expect(copy.id, original.id);
      expect(copy.status, original.status);
    });

    test('peut changer le statut', () {
      final game = _makeGame().copyWith(status: GameStatus.completed);
      expect(game.status, GameStatus.completed);
    });
  });
}
