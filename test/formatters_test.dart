import 'package:flutter_test/flutter_test.dart';
import 'package:arclog/core/utils/formatters.dart';

void main() {
  group('ArclogFormatters.playTime', () {
    test('0 minutes → "0m"', () {
      expect(ArclogFormatters.playTime(0), '0m');
    });

    test('moins d\'une heure → minutes seules', () {
      expect(ArclogFormatters.playTime(30), '30m');
      expect(ArclogFormatters.playTime(59), '59m');
    });

    test('heure ronde → sans minutes', () {
      expect(ArclogFormatters.playTime(60), '1h');
      expect(ArclogFormatters.playTime(120), '2h');
    });

    test('heures + minutes', () {
      expect(ArclogFormatters.playTime(90), '1h 30m');
      expect(ArclogFormatters.playTime(125), '2h 5m');
    });
  });

  group('ArclogFormatters.level', () {
    test('0 minute → niveau 1 (minimum)', () {
      expect(ArclogFormatters.level(0), 1);
    });

    test('119 minutes → toujours niveau 1', () {
      expect(ArclogFormatters.level(119), 1);
    });

    test('120 minutes (1² × 120) → niveau 2', () {
      expect(ArclogFormatters.level(120), 2);
    });

    test('480 minutes (2² × 120) → niveau 3', () {
      expect(ArclogFormatters.level(480), 3);
    });

    test('1080 minutes (3² × 120) → niveau 4', () {
      expect(ArclogFormatters.level(1080), 4);
    });
  });

  group('ArclogFormatters.xpProgress', () {
    test('0 minute → progression 0.0', () {
      expect(ArclogFormatters.xpProgress(0), 0.0);
    });

    test('60 minutes (mi-chemin du niveau 1) → 0.5', () {
      expect(ArclogFormatters.xpProgress(60), 0.5);
    });

    test('120 minutes (début du niveau 2) → 0.0', () {
      expect(ArclogFormatters.xpProgress(120), 0.0);
    });

    test('300 minutes (mi-chemin niveau 2 : 120–480) → 0.5', () {
      expect(ArclogFormatters.xpProgress(300), 0.5);
    });

    test('résultat toujours dans [0.0 – 1.0]', () {
      for (final m in [0, 60, 120, 300, 1000, 9999]) {
        final p = ArclogFormatters.xpProgress(m);
        expect(p, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('ArclogFormatters.xpToNextLevel', () {
    test('0 minute → 120 minutes restantes', () {
      expect(ArclogFormatters.xpToNextLevel(0), 120);
    });

    test('60 minutes → 60 restantes', () {
      expect(ArclogFormatters.xpToNextLevel(60), 60);
    });

    test('120 minutes (début niveau 2) → 360 restantes (480 − 120)', () {
      expect(ArclogFormatters.xpToNextLevel(120), 360);
    });
  });

  group('ArclogFormatters.absoluteDate', () {
    test('formate en DD/MM/YYYY avec padding', () {
      expect(
        ArclogFormatters.absoluteDate(DateTime(2024, 3, 5)),
        '05/03/2024',
      );
    });
  });
}
