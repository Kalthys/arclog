import 'package:flutter/material.dart';
import 'arclog_colors.dart';

abstract final class ArclogShadows {
  static List<BoxShadow> cyanGlow({double spread = 8, double blur = 20}) => [
    BoxShadow(
      color: ArclogColors.cyanGlow.withValues(alpha: 0.35),
      blurRadius: blur,
      spreadRadius: spread,
    ),
    BoxShadow(
      color: ArclogColors.cyanGlow.withValues(alpha: 0.15),
      blurRadius: blur * 2.5,
      spreadRadius: spread * 0.5,
    ),
  ];

  static List<BoxShadow> yellowGlow({double spread = 6, double blur = 18}) => [
    BoxShadow(
      color: ArclogColors.electricYellow.withValues(alpha: 0.35),
      blurRadius: blur,
      spreadRadius: spread,
    ),
    BoxShadow(
      color: ArclogColors.electricYellow.withValues(alpha: 0.15),
      blurRadius: blur * 2.5,
      spreadRadius: spread * 0.5,
    ),
  ];

  static List<BoxShadow> cardGlow = [
    BoxShadow(
      color: ArclogColors.cyanGlow.withValues(alpha: 0.12),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];
}
