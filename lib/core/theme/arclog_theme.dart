import 'package:flutter/material.dart';
import 'arclog_colors.dart';

abstract final class ArclogTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ArclogColors.deepBlack,

    colorScheme: const ColorScheme.dark(
      surface: ArclogColors.deepBlack,
      primary: ArclogColors.cyanGlow,
      secondary: ArclogColors.electricYellow,
      error: ArclogColors.error,
      onSurface: ArclogColors.textPrimary,
      onPrimary: ArclogColors.deepBlack,
      onSecondary: ArclogColors.deepBlack,
    ),

    textTheme: _textTheme,
    cardTheme: _cardTheme,
    dividerTheme: _dividerTheme,
    iconTheme: _iconTheme,
    progressIndicatorTheme: _progressIndicatorTheme,
    appBarTheme: _appBarTheme,
  );

  // ---------------------------------------------------------------------------
  // Typography — Orbitron loaded via google_fonts in main.dart
  // ---------------------------------------------------------------------------
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: ArclogColors.cyanGlow,
      letterSpacing: 4,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: ArclogColors.textPrimary,
      letterSpacing: 2,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ArclogColors.textPrimary,
      letterSpacing: 1.5,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: ArclogColors.cyanGlow,
      letterSpacing: 1.2,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: ArclogColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: ArclogColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: ArclogColors.electricYellow,
      letterSpacing: 2,
    ),
  );

  // ---------------------------------------------------------------------------
  // Cards — fond légèrement élevé + bordure circuit
  // ---------------------------------------------------------------------------
  static final CardThemeData _cardTheme = CardThemeData(
    color: ArclogColors.surfaceDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(
        color: ArclogColors.circuitLine,
        width: 1,
      ),
    ),
    margin: EdgeInsets.zero,
  );

  // ---------------------------------------------------------------------------
  // Dividers — imitent les lignes de circuit
  // ---------------------------------------------------------------------------
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: ArclogColors.circuitLine,
    thickness: 1,
    space: 0,
  );

  // ---------------------------------------------------------------------------
  // Icônes
  // ---------------------------------------------------------------------------
  static const IconThemeData _iconTheme = IconThemeData(
    color: ArclogColors.cyanGlow,
    size: 22,
  );

  // ---------------------------------------------------------------------------
  // Progress indicators — style "jauge d'énergie"
  // ---------------------------------------------------------------------------
  static const ProgressIndicatorThemeData _progressIndicatorTheme =
      ProgressIndicatorThemeData(
    color: ArclogColors.cyanGlow,
    linearTrackColor: ArclogColors.circuitLine,
    circularTrackColor: ArclogColors.circuitLine,
    linearMinHeight: 6,
  );

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: ArclogColors.deepBlack,
    foregroundColor: ArclogColors.textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: ArclogColors.cyanGlow,
      letterSpacing: 2,
    ),
  );
}
