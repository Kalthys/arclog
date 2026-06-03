import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';

class EnergyProgressBar extends StatelessWidget {
  const EnergyProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8.0,
    this.label,
  });

  final double value; // 0.0 – 1.0
  final Color? color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? ArclogColors.cyanGlow;
    final clamped = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Track
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ArclogColors.circuitLine,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Neon fill
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withValues(alpha: 0.65),
                        barColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // 3 segment tick marks at 25 / 50 / 75 %
              Row(
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 1,
                        color: ArclogColors.deepBlack.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
