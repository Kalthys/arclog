import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fond HUD animé inspiré d'une interface gaming cyberpunk.
/// Éléments : dégradé bleu→violet, frame arrondie, icônes fantômes,
/// barres néon sur les bords, grilles de points, étincelles, arc bas.
class HudBackgroundPainter extends CustomPainter {
  const HudBackgroundPainter({
    required this.pulseIntensity,
    required this.animTime,
  });

  final double pulseIntensity; // 0–1 sinusoïdal (5 s)
  final double animTime;        // 0–1 monotone  (3 s)

  // ── Palette ───────────────────────────────────────────────────────────────

  static const Color _bgBase    = Color(0xFF030D1A);
  static const Color _blue      = Color(0xFF1252A3);
  static const Color _purple    = Color(0xFF5B0DAA);
  static const Color _purpleHi  = Color(0xFFBB22FF);
  static const Color _cyanDim   = Color(0xFF0A3D72);
  static const Color _iconColor = Color(0xFF0D2A50);

  // ── Paint principal ───────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final p = pulseIntensity;
    final t = animTime;

    _drawBackground(canvas, size, p);
    _drawHudFrame(canvas, size, p);
    _drawCorners(canvas, size, p);
    _drawLeftEdgeMarks(canvas, size, p);
    _drawRightEdgeBars(canvas, size, p, t);
    _drawDotPatterns(canvas, size, p);
    _drawIcons(canvas, size, p);
    _drawSparkles(canvas, size, t);
    _drawBottomArc(canvas, size, p, t);
  }

  // ── Fond dégradé ──────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size, double p) {
    // Base sombre
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _bgBase,
    );

    // Halo violet côté droit
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(1.15, 0.35),
          radius: 0.95,
          colors: [
            _purple.withValues(alpha: 0.42 + p * 0.10),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    // Halo violet bas-gauche
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, 1.25),
          radius: 0.65,
          colors: [
            const Color(0xFF4A0B8C).withValues(alpha: 0.50 + p * 0.08),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    // Légère teinte bleue au centre haut
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.3),
          radius: 0.8,
          colors: [
            _blue.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  // ── Frame HUD (grand rectangle arrondi) ───────────────────────────────────

  void _drawHudFrame(Canvas canvas, Size size, double p) {
    final m = size.width * 0.04;
    final rect = Rect.fromLTRB(m, m * 0.6, size.width - m, size.height - m * 0.6);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(52));

    // Glow semi-transparent (large)
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _cyanDim.withValues(alpha: 0.12 + p * 0.08)
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke,
    );
    // Trait net
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _cyanDim.withValues(alpha: 0.35 + p * 0.15)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  // ── Brackets de coins ─────────────────────────────────────────────────────

  void _drawCorners(Canvas canvas, Size size, double p) {
    final m  = size.width * 0.04;
    final len = 28.0;
    final paint = Paint()
      ..color = _blue.withValues(alpha: 0.55 + p * 0.25)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
    }

    corner(m,                 m * 0.6,           len, len);
    corner(size.width - m,    m * 0.6,           -len, len);
    corner(m,                 size.height - m * 0.6, len, -len);
    corner(size.width - m,    size.height - m * 0.6, -len, -len);
  }

  // ── Tirets gauche ─────────────────────────────────────────────────────────

  void _drawLeftEdgeMarks(Canvas canvas, Size size, double p) {
    final x = size.width * 0.04;
    final paint = Paint()
      ..color = _blue.withValues(alpha: 0.45 + p * 0.20)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final frac in [0.25, 0.32, 0.42, 0.52, 0.62, 0.72, 0.80]) {
      final y = size.height * frac;
      canvas.drawLine(Offset(x - 8, y), Offset(x + 6, y), paint);
    }
    // Points supplémentaires (tirets courts)
    final dotPaint = Paint()
      ..color = _blue.withValues(alpha: 0.30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (final frac in [0.27, 0.30, 0.44, 0.54, 0.64]) {
      canvas.drawLine(
        Offset(x - 4, size.height * frac),
        Offset(x + 3, size.height * frac),
        dotPaint,
      );
    }
  }

  // ── Barres néon droite ────────────────────────────────────────────────────

  void _drawRightEdgeBars(Canvas canvas, Size size, double p, double t) {
    final x = size.width * 0.96;

    const segs = [
      [0.10, 0.20],
      [0.32, 0.48],
      [0.58, 0.68],
      [0.78, 0.87],
    ];

    for (int i = 0; i < segs.length; i++) {
      final y0 = size.height * segs[i][0];
      final y1 = size.height * segs[i][1];
      final pulse = 0.55 + 0.35 * math.sin(t * 2 * math.pi + i * 0.9);

      // Glow large
      canvas.drawLine(
        Offset(x, y0), Offset(x, y1),
        Paint()
          ..color = _purpleHi.withValues(alpha: 0.10 + p * 0.10)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      // Trait net pulsé
      canvas.drawLine(
        Offset(x, y0), Offset(x, y1),
        Paint()
          ..color = _purpleHi.withValues(alpha: 0.30 + pulse * 0.35)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Grilles de points ─────────────────────────────────────────────────────

  void _drawDotPatterns(Canvas canvas, Size size, double p) {
    // Grille haut-gauche (petits points denses)
    final smallDot = Paint()
      ..color = _blue.withValues(alpha: 0.35 + p * 0.15)
      ..style = PaintingStyle.fill;

    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        canvas.drawCircle(
          Offset(size.width * 0.05 + col * 5.5, size.height * 0.025 + row * 5.5),
          1.0,
          smallDot,
        );
      }
    }

    // Blocs pixels côté droit (plus grands, violets)
    final pixPaint = Paint()
      ..color = _purple.withValues(alpha: 0.30 + p * 0.18)
      ..style = PaintingStyle.fill;

    const pixels = [
      [0.83, 0.26], [0.87, 0.26], [0.91, 0.26],
      [0.83, 0.29], [0.87, 0.29],
      [0.83, 0.32], [0.87, 0.32], [0.91, 0.32],
      [0.83, 0.35], [0.91, 0.35],
      [0.83, 0.38], [0.87, 0.38],
    ];
    for (final px in pixels) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width * px[0], size.height * px[1]),
          width: 5.5, height: 5.5,
        ),
        pixPaint,
      );
    }

    // Petits points bas-droite
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(size.width * 0.85 + j * 6, size.height * 0.88 + i * 6),
          1.2,
          Paint()
            ..color = _purple.withValues(alpha: 0.25 + p * 0.12)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  // ── Icônes fantômes ───────────────────────────────────────────────────────

  void _drawIcons(Canvas canvas, Size size, double p) {
    final color = _iconColor.withValues(alpha: 0.38 + p * 0.12);
    _icon(canvas, Offset(size.width * 0.13, size.height * 0.11),
        Icons.sports_esports_outlined, color, 42);
    _icon(canvas, Offset(size.width * 0.13, size.height * 0.35),
        Icons.emoji_events_outlined, color, 38);
    _icon(canvas, Offset(size.width * 0.13, size.height * 0.57),
        Icons.auto_stories_outlined, color, 36);
    _icon(canvas, Offset(size.width * 0.13, size.height * 0.76),
        Icons.flag_outlined, color, 34);
    _icon(canvas, Offset(size.width * 0.85, size.height * 0.46),
        Icons.gps_fixed, color, 36);
  }

  void _icon(Canvas canvas, Offset center, IconData icon, Color color, double sz) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: sz,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Étincelles ────────────────────────────────────────────────────────────

  void _drawSparkles(Canvas canvas, Size size, double t) {
    const positions = [
      [0.20, 0.025], [0.60, 0.018], [0.72, 0.065],
      [0.88, 0.19],  [0.15, 0.30],  [0.82, 0.42],
      [0.10, 0.55],  [0.91, 0.62],  [0.28, 0.78],
      [0.52, 0.88],  [0.70, 0.92],  [0.38, 0.96],
      [0.05, 0.85],  [0.78, 0.82],
    ];

    for (int i = 0; i < positions.length; i++) {
      final bri = (math.sin(t * 2 * math.pi * 1.3 + i * 1.7) + 1) / 2;
      if (bri < 0.25) continue;

      final x = size.width  * positions[i][0];
      final y = size.height * positions[i][1];
      final a = bri * 0.85;
      final arm = 3.5 + bri * 2;

      final sp = Paint()
        ..color = Colors.white.withValues(alpha: a)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x - arm, y), Offset(x + arm, y), sp);
      canvas.drawLine(Offset(x, y - arm), Offset(x, y + arm), sp);
      canvas.drawCircle(Offset(x, y), 1.2,
          Paint()..color = Colors.white.withValues(alpha: a * 0.8));
    }
  }

  // ── Arc lumineux bas ──────────────────────────────────────────────────────

  void _drawBottomArc(Canvas canvas, Size size, double p, double t) {
    final pulsed = 0.25 + p * 0.20 + 0.08 * math.sin(t * 2 * math.pi);

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.93)
      ..quadraticBezierTo(
        size.width * 0.35, size.height * 0.98,
        size.width * 0.65, size.height * 0.93,
      );

    // Glow
    canvas.drawPath(path, Paint()
      ..color = _purpleHi.withValues(alpha: pulsed * 0.35)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
    // Trait net
    canvas.drawPath(path, Paint()
      ..color = _purpleHi.withValues(alpha: pulsed)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(HudBackgroundPainter old) =>
      old.pulseIntensity != pulseIntensity || old.animTime != animTime;
}
