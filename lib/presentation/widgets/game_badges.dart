import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/game_status.dart';

// =============================================================================
// Extension présentation sur GameStatus
// =============================================================================

extension GameStatusPresentation on GameStatus {
  Color get color => switch (this) {
        GameStatus.backlog => ArclogColors.textSecondary,
        GameStatus.playing => ArclogColors.cyanGlow,
        GameStatus.completed => ArclogColors.success,
        GameStatus.mastered => ArclogColors.electricYellow,
        GameStatus.dropped => ArclogColors.error,
      };

  IconData get icon => switch (this) {
        GameStatus.backlog => Icons.schedule_outlined,
        GameStatus.playing => Icons.play_circle_outline,
        GameStatus.completed => Icons.check_circle_outline,
        GameStatus.mastered => Icons.workspace_premium_outlined,
        GameStatus.dropped => Icons.cancel_outlined,
      };
}

// =============================================================================
// Badge statut (tag néon coloré)
// =============================================================================

class GameStatusBadge extends StatelessWidget {
  const GameStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final GameStatus status;

  /// compact = true → petit tag pour le carousel card
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final fontSize = compact ? 7.0 : 9.0;
    final iconSize = compact ? 9.0 : 11.0;
    final hPad = compact ? 5.0 : 8.0;
    final vPad = compact ? 2.0 : 4.0;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.18), blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: iconSize, color: color),
          SizedBox(width: compact ? 3 : 5),
          Text(
            status.tag,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Badge plateforme (couleur + icône selon la plateforme)
// =============================================================================

class PlatformBadge extends StatelessWidget {
  const PlatformBadge({
    super.key,
    required this.platform,
    this.compact = false,
  });

  final String platform;
  final bool compact;

  static const _psBlue = Color(0xFF4B9DFF);
  static const _neonPurple = Color(0xFFB06FFF);

  Color get _color => switch (platform.trim().toLowerCase()) {
        'pc' => ArclogColors.cyanGlow,
        'ps5' || 'ps4' || 'ps3' || 'ps2' => _psBlue,
        'xbox' => ArclogColors.success,
        'switch' => ArclogColors.error,
        'mobile' || 'ios' || 'android' => ArclogColors.electricYellow,
        _ => _neonPurple,
      };

  IconData get _icon => switch (platform.trim().toLowerCase()) {
        'pc' => Icons.computer_outlined,
        'ps5' || 'ps4' || 'ps3' || 'ps2' => Icons.sports_esports_outlined,
        'xbox' => Icons.sports_esports_outlined,
        'switch' => Icons.videogame_asset_outlined,
        'mobile' || 'ios' || 'android' => Icons.smartphone_outlined,
        _ => Icons.devices_other_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final fontSize = compact ? 7.0 : 9.0;
    final iconSize = compact ? 9.0 : 11.0;
    final hPad = compact ? 5.0 : 8.0;
    final vPad = compact ? 2.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: iconSize, color: color),
          SizedBox(width: compact ? 3 : 5),
          Text(
            platform.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sélecteur de statut (chips horizontales)
// =============================================================================

class StatusSelectorRow extends StatelessWidget {
  const StatusSelectorRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final GameStatus selected;
  final ValueChanged<GameStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: GameStatus.values.map((s) {
          final active = s == selected;
          final color = s.color;
          return GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? color.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? color : ArclogColors.circuitLine,
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.22),
                            blurRadius: 7)
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon,
                      size: 11,
                      color: active
                          ? color
                          : ArclogColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: active
                          ? color
                          : ArclogColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Chips rapides de plateforme
// =============================================================================

class PlatformQuickChips extends StatelessWidget {
  const PlatformQuickChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _platforms = [
    'PC', 'PS5', 'PS4', 'Xbox', 'Switch', 'Mobile', 'Autre'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _platforms.map((p) {
          return GestureDetector(
            onTap: () => onSelected(p),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ArclogColors.circuitLine),
                color: ArclogColors.circuitLine.withValues(alpha: 0.35),
              ),
              child: Text(
                p,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  color: ArclogColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
