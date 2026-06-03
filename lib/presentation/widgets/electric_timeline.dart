import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/theme/arclog_shadows.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/game.dart';
import '../sheets/session_read_sheet.dart';

typedef SessionEntry = ({Session session, Game game});

class ElectricTimeline extends StatelessWidget {
  const ElectricTimeline({
    super.key,
    required this.entries,
    this.onDeleteSession,
    this.onEditSession,
    /// false dans la page détail d'un jeu (titre redondant)
    this.showGameTitle = true,
  });

  final List<SessionEntry> entries;
  final void Function(Session)? onDeleteSession;
  final void Function(Session)? onEditSession;
  final bool showGameTitle;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Aucune session — lancez une partie !',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      children: List.generate(
        entries.length,
        (i) => _TimelineItem(
          entry: entries[i],
          isLast: i == entries.length - 1,
          showGameTitle: showGameTitle,
          onDelete: onDeleteSession != null
              ? () => onDeleteSession!(entries[i].session)
              : null,
          onEdit: onEditSession != null
              ? () => onEditSession!(entries[i].session)
              : null,
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.isLast,
    required this.showGameTitle,
    this.onDelete,
    this.onEdit,
  });

  final SessionEntry entry;
  final bool isLast;
  final bool showGameTitle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: const Text('Supprimer la session ?',
            style: TextStyle(color: ArclogColors.textPrimary)),
        content: const Text('Cette session sera définitivement effacée.',
            style: TextStyle(color: ArclogColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: ArclogColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: ArclogColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final session = entry.session;
    final game = entry.game;
    final hasNotes = session.notes != null && session.notes!.isNotEmpty;

    // ── Carte session ─────────────────────────────────────────────────────────
    final card = GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SessionReadSheet(
          session: session,
          game: game,
          onEdit: onEdit ?? () {},
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        decoration: BoxDecoration(
          color: ArclogColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ArclogColors.cyanGlow.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: ArclogColors.cyanGlow.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              children: [
                // Titre du jeu (optionnel)
                if (showGameTitle)
                  Expanded(
                    child: Text(
                      game.title,
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                // Date
                Text(
                  ArclogFormatters.relativeDate(session.startedAt),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    color: ArclogColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                // Edit
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          size: 14, color: ArclogColors.cyanGlow),
                    ),
                  ),
                // Delete
                if (onDelete != null)
                  GestureDetector(
                    onTap: () async {
                      if (await _confirmDelete(context)) onDelete!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          size: 14,
                          color: ArclogColors.error.withValues(alpha: 0.75)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),

            // ── Badge durée + tags ─────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Durée
                _Badge(
                  icon: Icons.timer_outlined,
                  label: ArclogFormatters.playTime(session.durationMinutes),
                  color: ArclogColors.electricYellow,
                ),
                // Tags
                ...session.tags.map((tag) => _Badge(
                      label: tag,
                      color: ArclogColors.cyanGlow,
                    )),
              ],
            ),

            // ── Aperçu des notes ───────────────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      session.notes!,
                      style: tt.bodyMedium?.copyWith(
                        color: ArclogColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new,
                      size: 11, color: ArclogColors.cyanGlow),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    // ── Swipe-to-delete ───────────────────────────────────────────────────────
    Widget item = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ligne temporelle
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ArclogColors.cyanGlow,
                      boxShadow: ArclogShadows.cyanGlow(spread: 1, blur: 6),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 1,
                          color: ArclogColors.cyanGlow.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: card),
          ],
        ),
      ),
    );

    if (onDelete != null) {
      item = Dismissible(
        key: Key('session_${session.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => onDelete!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          decoration: BoxDecoration(
            color: ArclogColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: ArclogColors.error.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SUPPRIMER',
                  style: TextStyle(
                      fontFamily: 'Orbitron', fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ArclogColors.error, letterSpacing: 1)),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: ArclogColors.error, size: 20),
            ],
          ),
        ),
        child: item,
      );
    }

    return item;
  }
}

// ── Badge durée / tag ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
