import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/game.dart';

class SessionReadSheet extends StatelessWidget {
  const SessionReadSheet({
    super.key,
    required this.session,
    required this.game,
    required this.onEdit,
  });

  final Session session;
  final Game game;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasScreenshot = session.screenshotPath != null &&
        File(session.screenshotPath!).existsSync();
    final hasNotes = session.notes != null && session.notes!.isNotEmpty;
    final hasTags = session.tags.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: hasNotes ? 0.85 : 0.50,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: ArclogColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: ArclogColors.circuitLine),
            left: BorderSide(color: ArclogColors.circuitLine),
            right: BorderSide(color: ArclogColors.circuitLine),
          ),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: ArclogColors.circuitLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── En-tête rapport ───────────────────────────────────────────────
            Row(
              children: [
                // Indicateur vertical coloré
                Container(
                  width: 3, height: 42,
                  decoration: BoxDecoration(
                    color: ArclogColors.cyanGlow,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(
                      color: ArclogColors.cyanGlow.withValues(alpha: 0.5),
                      blurRadius: 6,
                    )],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RAPPORT DE SESSION',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: ArclogColors.cyanGlow,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        game.title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ArclogColors.textPrimary,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  ArclogFormatters.absoluteDate(session.startedAt),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: ArclogColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 1, color: ArclogColors.circuitLine),
            const SizedBox(height: 14),

            // ── Badge durée ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: ArclogColors.electricYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ArclogColors.electricYellow.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: ArclogColors.electricYellow),
                      const SizedBox(width: 7),
                      Text(
                        ArclogFormatters.playTime(session.durationMinutes),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ArclogColors.electricYellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Tags ──────────────────────────────────────────────────────────
            if (hasTags) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: session.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: ArclogColors.cyanGlow.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: ArclogColors.cyanGlow.withValues(alpha: 0.40)),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ArclogColors.cyanGlow,
                    ),
                  ),
                )).toList(),
              ),
            ],

            // ── Screenshot ────────────────────────────────────────────────────
            if (hasScreenshot) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(session.screenshotPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            // ── Notes — style "citation rapport" ─────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bordure gauche lumineuse (lieu de la boîte grise)
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ArclogColors.cyanGlow.withValues(alpha: 0.8),
                          ArclogColors.cyanGlow.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectableText(
                      session.notes!,
                      style: tt.bodyLarge?.copyWith(
                        color: ArclogColors.textPrimary,
                        height: 1.9,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Aucune note pour cette session.',
                  style: tt.bodyMedium
                      ?.copyWith(color: ArclogColors.textSecondary),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Bouton modifier ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ArclogColors.cyanGlow),
                  foregroundColor: ArclogColors.cyanGlow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'MODIFIER CETTE SESSION',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
