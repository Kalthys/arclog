import 'dart:math' as math;

abstract final class ArclogFormatters {
  // ---------------------------------------------------------------------------
  // Play time
  // ---------------------------------------------------------------------------

  static String playTime(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // ---------------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------------

  static String relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    return _dmy(dt);
  }

  static String absoluteDate(DateTime dt) => _dmy(dt);

  static String _dmy(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  // ---------------------------------------------------------------------------
  // Level / XP  — 1 XP = 1 minute, level n needs n² × 120 minutes
  //   Level 1 → 2 h, Level 2 → 8 h, Level 3 → 18 h, Level 5 → 50 h …
  // ---------------------------------------------------------------------------

  static int level(int totalMinutes) {
    // Solve n² × 120 ≤ totalMinutes → n ≤ sqrt(totalMinutes / 120)
    return (math.sqrt(totalMinutes / 120) + 1).floor().clamp(1, 99);
  }

  /// Progress [0.0 – 1.0] toward the next level.
  static double xpProgress(int totalMinutes) {
    final lvl = level(totalMinutes);
    final xpCurrent = (lvl - 1) * (lvl - 1) * 120;
    final xpNext = lvl * lvl * 120;
    if (xpNext == xpCurrent) return 1.0;
    return ((totalMinutes - xpCurrent) / (xpNext - xpCurrent)).clamp(0.0, 1.0);
  }

  /// XP remaining to next level (in minutes).
  static int xpToNextLevel(int totalMinutes) {
    final lvl = level(totalMinutes);
    return lvl * lvl * 120 - totalMinutes;
  }
}
