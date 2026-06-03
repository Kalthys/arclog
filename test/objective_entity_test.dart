import 'package:flutter_test/flutter_test.dart';
import 'package:arclog/domain/entities/objective.dart';

Objective _obj({
  bool completed = false,
  int? targetQuantity,
  int currentQuantity = 0,
}) =>
    Objective(
      gameId: 1,
      title: 'Quest',
      createdAt: DateTime(2024),
      isCompleted: completed,
      targetQuantity: targetQuantity,
      currentQuantity: currentQuantity,
    );

void main() {
  group('Objective.hasQuantity', () {
    test('null → false', () => expect(_obj().hasQuantity, false));
    test('0 → false', () => expect(_obj(targetQuantity: 0).hasQuantity, false));
    test('positif → true',
        () => expect(_obj(targetQuantity: 10).hasQuantity, true));
  });

  group('Objective.quantityProgress', () {
    test('sans quantité, non complété → 0.0', () {
      expect(_obj().quantityProgress, 0.0);
    });

    test('sans quantité, complété → 1.0', () {
      expect(_obj(completed: true).quantityProgress, 1.0);
    });

    test('5 / 10 → 0.5', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 5).quantityProgress,
        0.5,
      );
    });

    test('10 / 10 → 1.0', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 10).quantityProgress,
        1.0,
      );
    });

    test('dépassement clampé → 1.0', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 15).quantityProgress,
        1.0,
      );
    });

    test('0 / 10 → 0.0', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 0).quantityProgress,
        0.0,
      );
    });
  });

  group('Objective.isQuantityReached', () {
    test('sans quantité cible → false', () {
      expect(_obj(currentQuantity: 100).isQuantityReached, false);
    });

    test('en dessous → false', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 9).isQuantityReached,
        false,
      );
    });

    test('exactement atteint → true', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 10).isQuantityReached,
        true,
      );
    });

    test('dépassé → true', () {
      expect(
        _obj(targetQuantity: 10, currentQuantity: 12).isQuantityReached,
        true,
      );
    });
  });

  group('Objective equality', () {
    test('égaux si même id + gameId', () {
      final a = Objective(
          id: 1, gameId: 1, title: 'A', createdAt: DateTime(2024));
      final b = Objective(
          id: 1, gameId: 1, title: 'B', createdAt: DateTime(2025));
      expect(a, b);
    });

    test('différents si gameId différent', () {
      final a = Objective(
          id: 1, gameId: 1, title: 'A', createdAt: DateTime(2024));
      final b = Objective(
          id: 1, gameId: 2, title: 'A', createdAt: DateTime(2024));
      expect(a, isNot(b));
    });
  });
}
