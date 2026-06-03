import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';

/// Éclairs doux en arrière-plan — version sans flash epileptique.
/// 2 éclairs par cycle de 6 s, décalés de 3 s.
/// Fondu entrant sur 0.35 s, tenue 1.5 s, fondu sortant 1.0 s.
/// Pas de flash écran. Alpha max : 0.35.
class SubtleLightningPainter extends CustomPainter {
  const SubtleLightningPainter({required this.time});

  final double time;

  static const int _boltCount = 2;
  static const double _cycleSeconds = 6.0;

  // Durées en fractions du cycle
  static const double _fadeIn  = 0.35 / _cycleSeconds; // 0.058
  static const double _hold    = 1.85 / _cycleSeconds; // 0.308  (fin de tenue)
  static const double _fadeOut = 2.85 / _cycleSeconds; // 0.475  (fin de fade)

  static const double _maxAlpha = 0.35;

  // ── Hash déterministe ─────────────────────────────────────────────────────

  static double _h(int seed, int idx) {
    int n = ((seed ^ 0xABCD1234) * 1664525 + idx * 22695477 + 1013904223).abs();
    return (n % 100000) / 100000.0;
  }

  // ── Alpha progressif (sans saut) ─────────────────────────────────────────

  static double _alpha(double phase) {
    if (phase < _fadeIn)   return (phase / _fadeIn) * _maxAlpha;
    if (phase < _hold)     return _maxAlpha;
    if (phase < _fadeOut)  return _maxAlpha * (1.0 - (phase - _hold) / (_fadeOut - _hold));
    return 0.0;
  }

  // ── Génération du chemin (subdivision point médian) ──────────────────────

  List<Offset> _bolt(Offset a, Offset b, int seed, int depth) {
    if (depth == 0) return [a, b];
    final mx = (a.dx + b.dx) / 2;
    final my = (a.dy + b.dy) / 2;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return [a, b];
    final disp = (_h(seed, depth) - 0.5) * len * 0.42;
    final nx = -dy / len;
    final ny =  dx / len;
    final mid = Offset(mx + nx * disp, my + ny * disp);
    final l = _bolt(a, mid, seed * 2 + 3, depth - 1);
    final r = _bolt(mid, b, seed * 2 + 7, depth - 1);
    return [...l, ...r.sublist(1)];
  }

  // ── Dessin du chemin (glow doux, pas de blanc aveuglant) ──────────────────

  void _draw(Canvas canvas, List<Offset> pts, double a) {
    if (pts.length < 2) return;
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) p.lineTo(pts[i].dx, pts[i].dy);

    // 1 seul halo flou (au lieu de 4 niveaux) — gain majeur sur GPU mobile
    canvas.drawPath(p, Paint()
      ..color = ArclogColors.cyanGlow.withValues(alpha: a * 0.28)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Noyau net
    canvas.drawPath(p, Paint()
      ..color = Colors.white.withValues(alpha: a * 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  // ── Éclair complet ────────────────────────────────────────────────────────

  void _paint(Canvas canvas, Size size, int idx, double phase) {
    final a = _alpha(phase);
    if (a <= 0) return;

    final seed = idx * 91337 + 42;
    final startX = size.width * (0.18 + _h(seed, 1) * 0.64);
    final endX   = size.width * (0.10 + _h(seed, 2) * 0.80);
    final pts    = _bolt(Offset(startX, -8), Offset(endX, size.height + 8), seed, 5);

    _draw(canvas, pts, a);
  }

  // ── Paint principal ───────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _boltCount; i++) {
      final phase = (time + i / _boltCount) % 1.0;
      if (phase < _fadeOut) _paint(canvas, size, i, phase);
    }
  }

  @override
  bool shouldRepaint(SubtleLightningPainter old) => old.time != time;
}
