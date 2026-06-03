import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/achievement.dart';
import 'neon_card.dart';

class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
    /// null = trophée Steam en lecture seule (pas de tap)
    this.onToggle,
  });

  final Achievement achievement;
  final VoidCallback? onToggle;

  bool get _isSteam => achievement.steamApiName != null;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final unlocked = achievement.isUnlocked;
    final accentColor =
        unlocked ? ArclogColors.electricYellow : ArclogColors.cyanGlow;

    return NeonCard(
      glowColor: accentColor,
      onTap: onToggle,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // ── Icône trophée + badge favori/Steam ─────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? ArclogColors.electricYellow.withValues(alpha: 0.18)
                      : ArclogColors.circuitLine,
                  border: Border.all(
                      color: accentColor, width: unlocked ? 1.5 : 1),
                  boxShadow: unlocked
                      ? [
                          BoxShadow(
                            color: ArclogColors.electricYellow
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  unlocked
                      ? Icons.emoji_events
                      : Icons.emoji_events_outlined,
                  size: 22,
                  color: unlocked
                      ? ArclogColors.electricYellow
                      : ArclogColors.textSecondary,
                ),
              ),
              // Badge favori
              if (achievement.isFavorite)
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
              // Badge Steam (coin bas-droite)
              if (_isSteam)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ArclogColors.cyanGlow.withValues(alpha: 0.9),
                      border: Border.all(
                          color: ArclogColors.surfaceDark, width: 1.5),
                    ),
                    child: const Icon(Icons.sports_esports,
                        size: 9, color: ArclogColors.deepBlack),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Nom + description + date ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: tt.titleMedium?.copyWith(
                    color: unlocked
                        ? ArclogColors.electricYellow
                        : ArclogColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (achievement.description != null) ...[
                  const SizedBox(height: 2),
                  Text(achievement.description!,
                      style: tt.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                if (achievement.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 12, color: ArclogColors.electricYellow),
                      const SizedBox(width: 4),
                      Text(
                        'Débloqué le ${ArclogFormatters.absoluteDate(achievement.unlockedAt!)}',
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

          // ── Indicateur lecture seule (Steam) ───────────────────────────
          if (_isSteam)
            const Icon(Icons.lock_outline,
                size: 14, color: ArclogColors.textSecondary),
        ],
      ),
    );
  }
}
