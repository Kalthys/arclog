abstract final class AppConstants {
  static const String appName = 'ARCLOG';

  // Limits
  static const int maxGameTitleLength = 60;
  static const int maxAchievementTitleLength = 80;
  static const int maxNotesLength = 500;
  static const int recentSessionsLimit = 8;

  // XP formula: level n costs n² × xpPerLevel minutes
  static const int xpPerLevel = 120; // minutes (= 2 h)

  // Tier thresholds (achievement ratio)
  static const double tierApprentice = 0.25;
  static const double tierVeteran = 0.50;
  static const double tierLegend = 0.75;
}
