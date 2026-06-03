import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';

class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.glowColor = ArclogColors.cyanGlow,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color glowColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              glowColor.withValues(alpha: 0.75),
              ArclogColors.electricYellow.withValues(alpha: 0.35),
              glowColor.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        // Gradient border width
        padding: const EdgeInsets.all(1.5),
        child: Container(
          decoration: BoxDecoration(
            color: ArclogColors.surfaceDark,
            borderRadius: BorderRadius.circular(10.5),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
