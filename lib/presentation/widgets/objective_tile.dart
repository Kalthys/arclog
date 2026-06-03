import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/objective.dart';
import 'energy_progress_bar.dart';
import 'neon_card.dart';

class ObjectiveTile extends StatelessWidget {
  const ObjectiveTile({
    super.key,
    required this.objective,
    required this.onToggle,
    this.onIncrement,
    this.onDecrement,
    this.onEdit,
  });

  final Objective objective;
  final VoidCallback onToggle;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final done = objective.isCompleted || objective.isQuantityReached;
    final accentColor =
        done ? ArclogColors.electricYellow : ArclogColors.cyanGlow;

    return NeonCard(
      glowColor: accentColor,
      onTap: objective.hasQuantity ? null : onToggle,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icône flag (avec badge favori si applicable) ──────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? ArclogColors.electricYellow.withValues(alpha: 0.15)
                      : ArclogColors.cyanGlow.withValues(alpha: 0.1),
                  border:
                      Border.all(color: accentColor, width: done ? 1.5 : 1),
                  boxShadow: done
                      ? [
                          BoxShadow(
                            color: ArclogColors.electricYellow
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  done ? Icons.flag : Icons.flag_outlined,
                  size: 22,
                  color: done
                      ? ArclogColors.electricYellow
                      : ArclogColors.cyanGlow,
                ),
              ),
              if (objective.isFavorite)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ArclogColors.electricYellow,
                      border: Border.all(
                          color: ArclogColors.surfaceDark, width: 1.5),
                    ),
                    child: const Icon(Icons.star,
                        size: 9, color: ArclogColors.deepBlack),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Contenu principal ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  objective.title,
                  style: tt.titleMedium?.copyWith(
                    color: done
                        ? ArclogColors.electricYellow
                        : ArclogColors.textPrimary,
                    decoration: (!objective.hasQuantity && done)
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: ArclogColors.electricYellow,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (objective.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    objective.description!,
                    style: tt.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // ── UI de quantité ─────────────────────────────────────────
                if (objective.hasQuantity) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: onDecrement,
                        color: objective.currentQuantity > 0
                            ? ArclogColors.cyanGlow
                            : ArclogColors.circuitLine,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${objective.currentQuantity} / ${objective.targetQuantity}',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: done
                              ? ArclogColors.electricYellow
                              : ArclogColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuantityButton(
                        icon: Icons.add,
                        onTap: done ? null : onIncrement,
                        color: done
                            ? ArclogColors.circuitLine
                            : ArclogColors.cyanGlow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  EnergyProgressBar(
                    value: objective.quantityProgress,
                    color: done
                        ? ArclogColors.electricYellow
                        : ArclogColors.cyanGlow,
                    height: 5,
                  ),
                ],

                // Date complétion (objectifs simples)
                if (!objective.hasQuantity && objective.completedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 12, color: ArclogColors.electricYellow),
                      const SizedBox(width: 4),
                      Text(
                        'Complété le ${ArclogFormatters.absoluteDate(objective.completedAt!)}',
                        style: tt.bodyMedium?.copyWith(
                          color: ArclogColors.electricYellow,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Bouton éditer ────────────────────────────────────────────────
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: ArclogColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1),
          color: color.withValues(alpha: 0.1),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
