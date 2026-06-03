import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';

/// Peint 3 éclairs animés avec ramifications.
/// [time] ∈ [0,1] : position dans le cycle (3 s).
/// Chaque éclair a une phase décalée de 1/3 et dure 0.30 du cycle.
class LightningPainter extends CustomPainter {
  const LightningPainter({required this.time});

  final double time;

  static const int _boltCount = 3;
  static const double _activeDuration = 0.30;

  // ── Hash déterministe ─────────────────────────────────────────────────────

  static double _h(int seed, int idx) {
    int n = ((seed ^ 0xDEADBEEF) * 1664525 + idx * 22695477 + 1013904223)
        .abs();
    return (n % 100000) / 100000.0;
  }

  // ── Alpha de flash (rapide entrée, tenue, fondu lent) ─────────────────────

  static double _flashAlpha(double phase) {
    if (phase < 0.04) return phase / 0.04;
    if (phase < 0.14) return 1.0;
    if (phase < _activeDuration) {
      return 1.0 - (phase - 0.14) / (_activeDuration - 0.14);
    }
    return 0.0;
  }

  // ── Génération d'un chemin d'éclair (subdivision du point médian) ─────────

  List<Offset> _generateBolt(
    Offset start,
    Offset end,
    int seed,
    int depth,
  ) {
    if (depth == 0) return [start, end];

    final mx = (start.dx + end.dx) / 2;
    final my = (start.dy + end.dy) / 2;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return [start, end];

    // Déplacement perpendiculaire proportionnel à la longueur
    final disp = (_h(seed, depth) - 0.5) * len * 0.45;
    final nx = -dy / len;
    final ny = dx / len;
    final displaced = Offset(mx + nx * disp, my + ny * disp);

    final left = _generateBolt(start, displaced, seed * 2 + 3, depth - 1);
    final right = _generateBolt(displaced, end, seed * 2 + 7, depth - 1);
    return [...left, ...right.sublist(1)];
  }

  // ── Dessin d'un chemin d'éclair (4 couches de glow) ──────────────────────

  void _drawBoltPath(
    Canvas canvas,
    List<Offset> pts,
    double alpha,
    double scale,
  ) {
    if (pts.length < 2) return;

    final dartPath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) dartPath.lineTo(pts[i].dx, pts[i].dy);

    final a = alpha * scale;

    // Halo extérieur très diffus (cyan)
    canvas.drawPath(
      dartPath,
      Paint()
        ..color = ArclogColors.cyanGlow.withValues(alpha: a * 0.09)
        ..strokeWidth = 32
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    // Glow moyen (cyan)
    canvas.drawPath(
      dartPath,
      Paint()
        ..color = ArclogColors.cyanGlow.withValues(alpha: a * 0.28)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Glow intérieur (jaune électrique, donne la chaleur du canal)
    canvas.drawPath(
      dartPath,
      Paint()
        ..color = ArclogColors.electricYellow.withValues(alpha: a * 0.55)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Noyau blanc brillant
    canvas.drawPath(
      dartPath,
      Paint()
        ..color = Colors.white.withValues(alpha: a * 0.95)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Ramifications depuis le corps principal ───────────────────────────────

  void _drawBranches(
    Canvas canvas,
    List<Offset> mainPts,
    int seed,
    double alpha,
  ) {
    const branchCount = 3;
    for (int b = 0; b < branchCount; b++) {
      // Point de départ de la ramification (dans le tiers central)
      final startFrac = 0.15 + _h(seed, 40 + b) * 0.70;
      final startIdx =
          (startFrac * (mainPts.length - 1)).round().clamp(1, mainPts.length - 2);
      final origin = mainPts[startIdx];

      // Direction de la branche : déviation par rapport à la direction du bolt
      final ahead = mainPts[startIdx + 1];
      final mainAngle = math.atan2(
        ahead.dy - origin.dy,
        ahead.dx - origin.dx,
      );
      final deviation = (_h(seed, 50 + b) - 0.5) * 1.8; // ±~51°
      final branchAngle = mainAngle + deviation;
      final branchLen = 60 + _h(seed, 60 + b) * 130;

      final branchEnd = Offset(
        origin.dx + math.cos(branchAngle) * branchLen,
        origin.dy + math.sin(branchAngle) * branchLen,
      );

      final branchPts =
          _generateBolt(origin, branchEnd, seed + b * 77 + 999, 3);
      _drawBoltPath(canvas, branchPts, alpha, 0.50);

      // Sous-ramification éventuelle
      if (_h(seed, 70 + b) > 0.45 && branchPts.length > 4) {
        final subIdx =
            (branchPts.length * 0.5).round().clamp(1, branchPts.length - 2);
        final subOrigin = branchPts[subIdx];
        final subAngle =
            branchAngle + (_h(seed, 80 + b) - 0.5) * 1.4;
        final subLen = 30 + _h(seed, 90 + b) * 60;
        final subEnd = Offset(
          subOrigin.dx + math.cos(subAngle) * subLen,
          subOrigin.dy + math.sin(subAngle) * subLen,
        );
        final subPts = _generateBolt(subOrigin, subEnd, seed + b * 13 + 555, 2);
        _drawBoltPath(canvas, subPts, alpha, 0.28);
      }
    }
  }

  // ── Dessin d'un éclair complet ────────────────────────────────────────────

  void _paintBolt(Canvas canvas, Size size, int boltIdx, double phase) {
    final alpha = _flashAlpha(phase);
    if (alpha <= 0) return;

    // Seed unique par index de bolt (forme fixe, visuelle cohérente)
    final seed = boltIdx * 91337 + 42;

    // Points de départ et d'arrivée (en coordonnées relatives)
    // Chaque bolt a une trajectoire propre et variée
    final startX = size.width *
        switch (boltIdx) {
          0 => 0.22 + _h(seed, 1) * 0.20, // centre-gauche en haut
          1 => 0.55 + _h(seed, 1) * 0.25, // centre-droite en haut
          _ => 0.05 + _h(seed, 1) * 0.18, // bord gauche en haut
        };
    final endX = size.width *
        switch (boltIdx) {
          0 => 0.40 + _h(seed, 2) * 0.30,
          1 => 0.20 + _h(seed, 2) * 0.35,
          _ => 0.60 + _h(seed, 2) * 0.32,
        };

    final start = Offset(startX, -10);
    final end = Offset(endX, size.height + 10);

    final pts = _generateBolt(start, end, seed, 5); // 33 points

    // Flash de l'écran au moment du pic
    if (phase < 0.06) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = ArclogColors.cyanGlow.withValues(alpha: alpha * 0.055),
      );
    }

    _drawBoltPath(canvas, pts, alpha, 1.0);
    _drawBranches(canvas, pts, seed, alpha);
  }

  // ── Paint principal ───────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _boltCount; i++) {
      final phase = (time + i / _boltCount) % 1.0;
      if (phase < _activeDuration) {
        _paintBolt(canvas, size, i, phase);
      }
    }
  }

  @override
  bool shouldRepaint(LightningPainter old) => old.time != time;
}
