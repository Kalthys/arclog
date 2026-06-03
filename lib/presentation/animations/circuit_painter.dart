import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';

/// Peint un circuit imprimé (PCB) animé.
/// [glowIntensity] ∈ [0,1] : pulse de luminosité des traces (lent, ~5 s).
/// [sparkTime]     ∈ [0,1] : position des étincelles (rapide, ~2.5 s).
class CircuitPainter extends CustomPainter {
  const CircuitPainter({
    required this.glowIntensity,
    required this.sparkTime,
  });

  final double glowIntensity;
  final double sparkTime;

  // ── Pistes horizontales ───────────────────────────────────────────────────

  static const _hSegs = <List<Offset>>[
    [Offset(0.00, 0.07), Offset(0.22, 0.07)],
    [Offset(0.32, 0.07), Offset(0.52, 0.07)],
    [Offset(0.65, 0.07), Offset(0.82, 0.07)],
    [Offset(0.90, 0.07), Offset(1.00, 0.07)],
    [Offset(0.00, 0.17), Offset(0.08, 0.17)],
    [Offset(0.22, 0.17), Offset(0.40, 0.17)],
    [Offset(0.52, 0.17), Offset(0.65, 0.17)],
    [Offset(0.78, 0.17), Offset(1.00, 0.17)],
    [Offset(0.00, 0.27), Offset(0.18, 0.27)],
    [Offset(0.30, 0.27), Offset(0.50, 0.27)],
    [Offset(0.65, 0.27), Offset(0.80, 0.27)],
    [Offset(0.90, 0.27), Offset(1.00, 0.27)],
    [Offset(0.08, 0.37), Offset(0.26, 0.37)],
    [Offset(0.40, 0.37), Offset(0.58, 0.37)],
    [Offset(0.72, 0.37), Offset(0.88, 0.37)],
    [Offset(0.00, 0.47), Offset(0.18, 0.47)],
    [Offset(0.32, 0.47), Offset(0.52, 0.47)],
    [Offset(0.66, 0.47), Offset(0.84, 0.47)],
    [Offset(0.94, 0.47), Offset(1.00, 0.47)],
    [Offset(0.10, 0.57), Offset(0.28, 0.57)],
    [Offset(0.42, 0.57), Offset(0.60, 0.57)],
    [Offset(0.76, 0.57), Offset(0.94, 0.57)],
    [Offset(0.00, 0.67), Offset(0.14, 0.67)],
    [Offset(0.28, 0.67), Offset(0.48, 0.67)],
    [Offset(0.62, 0.67), Offset(0.78, 0.67)],
    [Offset(0.92, 0.67), Offset(1.00, 0.67)],
    [Offset(0.06, 0.77), Offset(0.22, 0.77)],
    [Offset(0.36, 0.77), Offset(0.56, 0.77)],
    [Offset(0.70, 0.77), Offset(0.88, 0.77)],
    [Offset(0.00, 0.87), Offset(0.16, 0.87)],
    [Offset(0.30, 0.87), Offset(0.50, 0.87)],
    [Offset(0.64, 0.87), Offset(0.80, 0.87)],
    [Offset(0.92, 0.87), Offset(1.00, 0.87)],
    [Offset(0.10, 0.95), Offset(0.28, 0.95)],
    [Offset(0.44, 0.95), Offset(0.62, 0.95)],
    [Offset(0.78, 0.95), Offset(1.00, 0.95)],
  ];

  // ── Pistes verticales ─────────────────────────────────────────────────────

  static const _vSegs = <List<Offset>>[
    [Offset(0.08, 0.17), Offset(0.08, 0.27)],
    [Offset(0.08, 0.37), Offset(0.08, 0.47)],
    [Offset(0.18, 0.27), Offset(0.18, 0.37)],
    [Offset(0.18, 0.47), Offset(0.18, 0.57)],
    [Offset(0.18, 0.87), Offset(0.18, 0.95)],
    [Offset(0.22, 0.07), Offset(0.22, 0.17)],
    [Offset(0.22, 0.77), Offset(0.22, 0.87)],
    [Offset(0.28, 0.57), Offset(0.28, 0.67)],
    [Offset(0.28, 0.87), Offset(0.28, 0.95)],
    [Offset(0.30, 0.27), Offset(0.30, 0.37)],
    [Offset(0.32, 0.07), Offset(0.32, 0.17)],
    [Offset(0.32, 0.47), Offset(0.32, 0.57)],
    [Offset(0.36, 0.67), Offset(0.36, 0.77)],
    [Offset(0.40, 0.17), Offset(0.40, 0.27)],
    [Offset(0.40, 0.37), Offset(0.40, 0.47)],
    [Offset(0.44, 0.87), Offset(0.44, 0.95)],
    [Offset(0.48, 0.67), Offset(0.48, 0.77)],
    [Offset(0.50, 0.27), Offset(0.50, 0.37)],
    [Offset(0.50, 0.87), Offset(0.50, 0.95)],
    [Offset(0.52, 0.07), Offset(0.52, 0.17)],
    [Offset(0.52, 0.47), Offset(0.52, 0.57)],
    [Offset(0.56, 0.77), Offset(0.56, 0.87)],
    [Offset(0.62, 0.87), Offset(0.62, 0.95)],
    [Offset(0.65, 0.07), Offset(0.65, 0.17)],
    [Offset(0.65, 0.27), Offset(0.65, 0.37)],
    [Offset(0.66, 0.47), Offset(0.66, 0.57)],
    [Offset(0.70, 0.67), Offset(0.70, 0.77)],
    [Offset(0.72, 0.37), Offset(0.72, 0.47)],
    [Offset(0.78, 0.17), Offset(0.78, 0.27)],
    [Offset(0.78, 0.67), Offset(0.78, 0.77)],
    [Offset(0.80, 0.27), Offset(0.80, 0.37)],
    [Offset(0.80, 0.87), Offset(0.80, 0.95)],
    [Offset(0.82, 0.07), Offset(0.82, 0.17)],
    [Offset(0.84, 0.47), Offset(0.84, 0.57)],
    [Offset(0.88, 0.37), Offset(0.88, 0.47)],
    [Offset(0.88, 0.77), Offset(0.88, 0.87)],
    [Offset(0.90, 0.07), Offset(0.90, 0.17)],
    [Offset(0.90, 0.27), Offset(0.90, 0.37)],
    [Offset(0.92, 0.67), Offset(0.92, 0.77)],
    [Offset(0.92, 0.87), Offset(0.92, 0.95)],
    [Offset(0.94, 0.47), Offset(0.94, 0.57)],
  ];

  // ── Nœuds de jonction ─────────────────────────────────────────────────────

  static const _vias = <Offset>[
    Offset(0.22, 0.07), Offset(0.52, 0.07), Offset(0.65, 0.07),
    Offset(0.82, 0.07), Offset(0.32, 0.07), Offset(0.90, 0.07),
    Offset(0.08, 0.17), Offset(0.22, 0.17), Offset(0.32, 0.17),
    Offset(0.40, 0.17), Offset(0.52, 0.17), Offset(0.65, 0.17),
    Offset(0.78, 0.17), Offset(0.82, 0.17), Offset(0.90, 0.17),
    Offset(0.08, 0.27), Offset(0.18, 0.27), Offset(0.30, 0.27),
    Offset(0.40, 0.27), Offset(0.50, 0.27), Offset(0.65, 0.27),
    Offset(0.78, 0.27), Offset(0.80, 0.27), Offset(0.90, 0.27),
    Offset(0.08, 0.37), Offset(0.18, 0.37), Offset(0.26, 0.37),
    Offset(0.30, 0.37), Offset(0.40, 0.37), Offset(0.50, 0.37),
    Offset(0.58, 0.37), Offset(0.65, 0.37), Offset(0.72, 0.37),
    Offset(0.80, 0.37), Offset(0.88, 0.37), Offset(0.90, 0.37),
    Offset(0.08, 0.47), Offset(0.18, 0.47), Offset(0.32, 0.47),
    Offset(0.40, 0.47), Offset(0.52, 0.47), Offset(0.66, 0.47),
    Offset(0.72, 0.47), Offset(0.84, 0.47), Offset(0.88, 0.47),
    Offset(0.94, 0.47),
    Offset(0.10, 0.57), Offset(0.18, 0.57), Offset(0.28, 0.57),
    Offset(0.32, 0.57), Offset(0.42, 0.57), Offset(0.52, 0.57),
    Offset(0.60, 0.57), Offset(0.66, 0.57), Offset(0.76, 0.57),
    Offset(0.84, 0.57), Offset(0.94, 0.57),
    Offset(0.14, 0.67), Offset(0.28, 0.67), Offset(0.36, 0.67),
    Offset(0.48, 0.67), Offset(0.62, 0.67), Offset(0.70, 0.67),
    Offset(0.78, 0.67), Offset(0.92, 0.67),
    Offset(0.06, 0.77), Offset(0.22, 0.77), Offset(0.36, 0.77),
    Offset(0.48, 0.77), Offset(0.56, 0.77), Offset(0.70, 0.77),
    Offset(0.78, 0.77), Offset(0.88, 0.77), Offset(0.92, 0.77),
    Offset(0.16, 0.87), Offset(0.18, 0.87), Offset(0.22, 0.87),
    Offset(0.30, 0.87), Offset(0.44, 0.87), Offset(0.50, 0.87),
    Offset(0.56, 0.87), Offset(0.62, 0.87), Offset(0.64, 0.87),
    Offset(0.80, 0.87), Offset(0.88, 0.87), Offset(0.92, 0.87),
    Offset(0.18, 0.95), Offset(0.28, 0.95), Offset(0.44, 0.95),
    Offset(0.50, 0.95), Offset(0.62, 0.95), Offset(0.78, 0.95),
    Offset(0.80, 0.95), Offset(0.92, 0.95),
  ];

  // ── Puces CI ──────────────────────────────────────────────────────────────

  static const _icRects = <Rect>[
    Rect.fromLTRB(0.66, 0.09, 0.84, 0.22),
    Rect.fromLTRB(0.32, 0.39, 0.52, 0.52),
    Rect.fromLTRB(0.58, 0.63, 0.76, 0.75),
  ];

  // ── Chemins des 5 étincelles ──────────────────────────────────────────────

  // Étincelle 1 : haut, gauche → droite
  static const _spark1 = <Offset>[
    Offset(0.00, 0.07), Offset(0.22, 0.07), Offset(0.22, 0.17),
    Offset(0.40, 0.17), Offset(0.40, 0.27), Offset(0.50, 0.27),
    Offset(0.50, 0.37), Offset(0.65, 0.37), Offset(0.65, 0.27),
    Offset(0.78, 0.27), Offset(0.78, 0.17), Offset(1.00, 0.17),
  ];

  // Étincelle 2 : milieu, gauche → droite
  static const _spark2 = <Offset>[
    Offset(0.00, 0.47), Offset(0.18, 0.47), Offset(0.18, 0.57),
    Offset(0.28, 0.57), Offset(0.28, 0.67), Offset(0.48, 0.67),
    Offset(0.48, 0.77), Offset(0.56, 0.77), Offset(0.56, 0.87),
    Offset(0.64, 0.87), Offset(0.64, 0.77), Offset(0.70, 0.77),
    Offset(0.70, 0.67), Offset(0.78, 0.67), Offset(0.78, 0.77),
    Offset(0.88, 0.77), Offset(0.88, 0.87), Offset(1.00, 0.87),
  ];

  // Étincelle 3 : bas, droite → gauche
  static const _spark3 = <Offset>[
    Offset(1.00, 0.95), Offset(0.78, 0.95), Offset(0.78, 0.87),
    Offset(0.64, 0.87), Offset(0.62, 0.95), Offset(0.44, 0.95),
    Offset(0.44, 0.87), Offset(0.30, 0.87), Offset(0.30, 0.77),
    Offset(0.22, 0.77), Offset(0.22, 0.87), Offset(0.16, 0.87),
    Offset(0.16, 0.77), Offset(0.06, 0.77), Offset(0.00, 0.77),
  ];

  // Étincelle 4 : diagonale gauche-centre descendante
  static const _spark4 = <Offset>[
    Offset(0.00, 0.27), Offset(0.18, 0.27), Offset(0.18, 0.37),
    Offset(0.30, 0.37), Offset(0.30, 0.47), Offset(0.40, 0.47),
    Offset(0.40, 0.57), Offset(0.52, 0.57), Offset(0.52, 0.67),
    Offset(0.62, 0.67), Offset(0.70, 0.67), Offset(0.70, 0.77),
    Offset(0.88, 0.77), Offset(0.88, 0.87), Offset(1.00, 0.87),
  ];

  // Étincelle 5 : diagonale droite descendante
  static const _spark5 = <Offset>[
    Offset(1.00, 0.27), Offset(0.90, 0.27), Offset(0.90, 0.37),
    Offset(0.80, 0.37), Offset(0.80, 0.47), Offset(0.72, 0.47),
    Offset(0.66, 0.47), Offset(0.66, 0.57), Offset(0.60, 0.57),
    Offset(0.48, 0.57), Offset(0.48, 0.67), Offset(0.36, 0.67),
    Offset(0.28, 0.67), Offset(0.14, 0.67), Offset(0.00, 0.67),
  ];

  // ── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final g = glowIntensity;

    // 1. Glow des pistes — large trait semi-transparent (sans saveLayer/blur)
    final glowTrace = Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: 0.06 + g * 0.08)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final s in _hSegs) {
      canvas.drawLine(
        Offset(s[0].dx * size.width, s[0].dy * size.height),
        Offset(s[1].dx * size.width, s[1].dy * size.height),
        glowTrace,
      );
    }
    for (final s in _vSegs) {
      canvas.drawLine(
        Offset(s[0].dx * size.width, s[0].dy * size.height),
        Offset(s[1].dx * size.width, s[1].dy * size.height),
        glowTrace,
      );
    }

    // 2. Pistes nettes au-dessus du glow
    final cyanTrace = Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: 0.28 + g * 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    for (final s in _hSegs) {
      canvas.drawLine(
        Offset(s[0].dx * size.width, s[0].dy * size.height),
        Offset(s[1].dx * size.width, s[1].dy * size.height),
        cyanTrace,
      );
    }
    for (final s in _vSegs) {
      canvas.drawLine(
        Offset(s[0].dx * size.width, s[0].dy * size.height),
        Offset(s[1].dx * size.width, s[1].dy * size.height),
        cyanTrace,
      );
    }

    // 3. Rails d'alimentation jaunes
    _drawPowerRails(canvas, size, g);

    // 4. Puces CI
    _drawIcChips(canvas, size, g);

    // 5. Vias — halo semi-transparent + ring + dot (pas de saveLayer)
    final nodeAlpha = 0.45 + g * 0.35;
    final nodeHalo = Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: nodeAlpha * 0.12)
      ..style = PaintingStyle.fill;
    final nodeRing = Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: nodeAlpha * 0.55)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final nodeSolid = Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: nodeAlpha)
      ..style = PaintingStyle.fill;
    for (final v in _vias) {
      final pos = Offset(v.dx * size.width, v.dy * size.height);
      canvas.drawCircle(pos, 6.0, nodeHalo);  // halo large
      canvas.drawCircle(pos, 3.6, nodeRing);   // anneau
      canvas.drawCircle(pos, 1.9, nodeSolid);  // point central
    }

    // 6. 3 étincelles
    _drawSpark(canvas, size, _spark1, sparkTime,                ArclogColors.electricYellow);
    _drawSpark(canvas, size, _spark2, (sparkTime + 0.33) % 1.0, ArclogColors.cyanGlow);
    _drawSpark(canvas, size, _spark3, (sparkTime + 0.67) % 1.0, ArclogColors.electricYellow);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _drawPowerRails(Canvas canvas, Size size, double g) {
    // Glow du rail (large, semi-transparent)
    final railGlow = Paint()
      ..color = ArclogColors.electricYellow.withValues(alpha: 0.05 + g * 0.07)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(4, 0), Offset(4, size.height), railGlow);
    canvas.drawLine(Offset(size.width - 4, 0),
        Offset(size.width - 4, size.height), railGlow);
    // Trait net du rail
    final rail = Paint()
      ..color = ArclogColors.electricYellow.withValues(alpha: 0.22 + g * 0.16)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(4, 0), Offset(4, size.height), rail);
    canvas.drawLine(
        Offset(size.width - 4, 0), Offset(size.width - 4, size.height), rail);
  }

  void _drawIcChips(Canvas canvas, Size size, double g) {
    final icAlpha = 0.28 + g * 0.18;
    final icPaint = Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: icAlpha)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final r in _icRects) {
      final sr = Rect.fromLTRB(
        r.left * size.width, r.top * size.height,
        r.right * size.width, r.bottom * size.height,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(sr, const Radius.circular(3)), icPaint);
      _drawIcLegs(canvas, sr, icPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: 'IC',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            color: ArclogColors.cyanGlow.withValues(alpha: icAlpha * 0.7),
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center = sr.center;
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawIcLegs(Canvas canvas, Rect r, Paint p) {
    const legLen = 9.0;
    for (final t in [0.20, 0.50, 0.80]) {
      final x = r.left + r.width * t;
      canvas.drawLine(Offset(x, r.top), Offset(x, r.top - legLen), p);
      canvas.drawLine(Offset(x, r.bottom), Offset(x, r.bottom + legLen), p);
    }
    for (final t in [0.30, 0.70]) {
      final y = r.top + r.height * t;
      canvas.drawLine(Offset(r.left, y), Offset(r.left - legLen, y), p);
      canvas.drawLine(Offset(r.right, y), Offset(r.right + legLen, y), p);
    }
  }

  /// Calcule la position sur un chemin normalisé à t ∈ [0,1].
  Offset _posOnPath(List<Offset> path, double t, Size size) {
    final pts = [
      for (final o in path) Offset(o.dx * size.width, o.dy * size.height)
    ];
    double total = 0;
    for (int i = 1; i < pts.length; i++) {
      total += (pts[i] - pts[i - 1]).distance;
    }
    double dist = t * total;
    for (int i = 1; i < pts.length; i++) {
      final seg = (pts[i] - pts[i - 1]).distance;
      if (dist <= seg) return Offset.lerp(pts[i - 1], pts[i], dist / seg)!;
      dist -= seg;
    }
    return pts.last;
  }

  void _drawSpark(
    Canvas canvas,
    Size size,
    List<Offset> path,
    double t,
    Color color,
  ) {
    final a = 0.65 + glowIntensity * 0.35;
    final pos = _posOnPath(path, t, size);

    // 1 seul halo flou (au lieu de 3) — beaucoup plus léger sur GPU
    canvas.drawCircle(
      pos, 10,
      Paint()
        ..color = color.withValues(alpha: a * 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Noyau net
    canvas.drawCircle(pos, 2.8, Paint()..color = color.withValues(alpha: a));
    canvas.drawCircle(pos, 1.3,
        Paint()..color = Colors.white.withValues(alpha: a * 0.90));
  }

  @override
  bool shouldRepaint(CircuitPainter old) =>
      old.glowIntensity != glowIntensity || old.sparkTime != sparkTime;
}
