import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../widgets/sheet_utils.dart';

class ActionChooserSheet extends StatelessWidget {
  const ActionChooserSheet({
    super.key,
    required this.onAddGame,
    required this.onQuickSession,
    required this.onChrono,
    required this.onDeleteGames,
  });

  final VoidCallback onAddGame;
  final VoidCallback onQuickSession;
  final VoidCallback onChrono;
  final VoidCallback onDeleteGames;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          _ActionButton(
            icon: Icons.videogame_asset_outlined,
            label: 'AJOUTER UN JEU',
            sublabel: 'Créer une nouvelle fiche de jeu',
            color: ArclogColors.cyanGlow,
            onTap: onAddGame,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.flash_on_outlined,
            label: 'SESSION RAPIDE',
            sublabel: 'Saisir une durée manuellement',
            color: ArclogColors.electricYellow,
            onTap: onQuickSession,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.timer_outlined,
            label: 'CHRONOMÈTRE',
            sublabel: 'Lancer un timer en direct',
            color: ArclogColors.success,
            onTap: onChrono,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.delete_sweep_outlined,
            label: 'SUPPRIMER DES JEUX',
            sublabel: 'Sélectionner et supprimer plusieurs jeux',
            color: ArclogColors.error,
            onTap: onDeleteGames,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    color: ArclogColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
