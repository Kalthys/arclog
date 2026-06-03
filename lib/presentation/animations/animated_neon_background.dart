import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'hud_background_painter.dart';

/// Fond HUD animé — dégradé bleu/violet, frame arrondie, icônes fantômes,
/// barres néon, grilles de points et étincelles.
class AnimatedNeonBackground extends StatefulWidget {
  const AnimatedNeonBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedNeonBackground> createState() =>
      _AnimatedNeonBackgroundState();
}

class _AnimatedNeonBackgroundState extends State<AnimatedNeonBackground>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl; // 5 s — pulsation luminosité
  late final AnimationController _animCtrl;  // 3 s — étincelles, barres

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseCtrl, _animCtrl]),
            builder: (_, __) {
              final glowIntensity =
                  (math.sin(_pulseCtrl.value * 2 * math.pi) + 1) / 2;
              return CustomPaint(
                painter: HudBackgroundPainter(
                  pulseIntensity: glowIntensity,
                  animTime: _animCtrl.value,
                ),
                isComplex: true,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}
