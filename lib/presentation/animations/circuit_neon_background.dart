import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'circuit_painter.dart';

/// Backup du fond PCB (circuit imprimé animé).
/// Pour revenir à ce fond, remplacer AnimatedNeonBackground par
/// CircuitNeonBackground dans dashboard_page.dart et game_detail_page.dart.
class CircuitNeonBackground extends StatefulWidget {
  const CircuitNeonBackground({super.key, required this.child});

  final Widget child;

  @override
  State<CircuitNeonBackground> createState() => _CircuitNeonBackgroundState();
}

class _CircuitNeonBackgroundState extends State<CircuitNeonBackground>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _sparkCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sparkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseCtrl, _sparkCtrl]),
            builder: (_, __) {
              final glowIntensity =
                  (math.sin(_pulseCtrl.value * 2 * math.pi) + 1) / 2;
              return CustomPaint(
                painter: CircuitPainter(
                  glowIntensity: glowIntensity,
                  sparkTime: _sparkCtrl.value,
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
