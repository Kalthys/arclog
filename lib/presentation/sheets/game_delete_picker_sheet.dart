import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/game.dart';
import '../state/game_providers.dart';
import '../widgets/game_badges.dart';

class GameDeletePickerSheet extends ConsumerStatefulWidget {
  const GameDeletePickerSheet({super.key, required this.games});

  final List<Game> games;

  @override
  ConsumerState<GameDeletePickerSheet> createState() =>
      _GameDeletePickerSheetState();
}

class _GameDeletePickerSheetState
    extends ConsumerState<GameDeletePickerSheet> {
  final _searchCtrl = TextEditingController();
  final _selected = <int>{};
  String _query = '';
  bool _deleting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Game> get _filtered {
    if (_query.isEmpty) return widget.games;
    final q = _query.toLowerCase();
    return widget.games
        .where((g) => g.title.toLowerCase().contains(q))
        .toList();
  }

  bool get _allFilteredSelected =>
      _filtered.isNotEmpty &&
      _filtered.every((g) => _selected.contains(g.id));

  void _toggleAll() {
    final filtered = _filtered;
    final allSelected = _allFilteredSelected;
    setState(() {
      if (allSelected) {
        for (final g in filtered) _selected.remove(g.id);
      } else {
        for (final g in filtered) {
          if (g.id != null) _selected.add(g.id!);
        }
      }
    });
  }

  Future<void> _delete() async {
    if (_selected.isEmpty) return;

    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: Text(
          'Supprimer $count jeu${count > 1 ? 'x' : ''} ?',
          style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              color: ArclogColors.textPrimary),
        ),
        content: Text(
          'Toutes les sessions, objectifs et trophées associés seront '
          'définitivement effacés.',
          style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: ArclogColors.textSecondary,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER',
                style: TextStyle(color: ArclogColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUPPRIMER',
                style: TextStyle(
                    color: ArclogColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    await ref
        .read(gamesProvider.notifier)
        .removeGames(_selected.toList());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
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
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ArclogColors.circuitLine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined,
                          color: ArclogColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('SUPPRIMER DES JEUX',
                            style: tt.titleLarge?.copyWith(
                                color: ArclogColors.textPrimary)),
                      ),
                      Text(
                        '${widget.games.length} jeu(x)',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: ArclogColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Barre de recherche ─────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    style: tt.bodyLarge,
                    cursorColor: ArclogColors.error,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un jeu…',
                      hintStyle: tt.bodyMedium,
                      prefixIcon: const Icon(Icons.search,
                          color: ArclogColors.textSecondary, size: 18),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: ArclogColors.textSecondary,
                                  size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: ArclogColors.circuitLine),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: ArclogColors.error, width: 1.5),
                      ),
                      filled: true,
                      fillColor: ArclogColors.deepBlack,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Tout sélectionner ──────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleAll,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _allFilteredSelected
                                  ? Icons.deselect
                                  : Icons.select_all,
                              size: 14,
                              color: ArclogColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _allFilteredSelected
                                  ? 'TOUT DÉSÉLECTIONNER'
                                  : 'TOUT SÉLECTIONNER',
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 9,
                                color: ArclogColors.error,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_query.isNotEmpty)
                        Text(
                          '${filtered.length} résultat(s)',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9,
                            color: ArclogColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: ArclogColors.circuitLine),
                ],
              ),
            ),

            // ── Liste ─────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('Aucun jeu trouvé',
                          style: tt.bodyMedium),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final game = filtered[i];
                        final isSelected = game.id != null &&
                            _selected.contains(game.id);
                        return _GameDeleteTile(
                          game: game,
                          selected: isSelected,
                          onTap: () => setState(() {
                            if (game.id == null) return;
                            if (isSelected) {
                              _selected.remove(game.id);
                            } else {
                              _selected.add(game.id!);
                            }
                          }),
                        );
                      },
                    ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: ArclogColors.circuitLine)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selected.length} sélectionné(s)',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _selected.isEmpty
                                ? ArclogColors.textSecondary
                                : ArclogColors.error,
                          ),
                        ),
                        if (_selected.isEmpty)
                          const Text(
                            'Sélectionne les jeux à supprimer',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 9,
                              color: ArclogColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_selected.isEmpty || _deleting) ? null : _delete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected.isEmpty
                            ? ArclogColors.circuitLine
                            : ArclogColors.error,
                        foregroundColor: ArclogColors.textPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      icon: _deleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArclogColors.textPrimary))
                          : const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        _deleting ? 'SUPPRESSION…' : 'SUPPRIMER',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile d'un jeu local ──────────────────────────────────────────────────────

class _GameDeleteTile extends StatelessWidget {
  const _GameDeleteTile({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final Game game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ArclogColors.error.withValues(alpha: 0.10)
              : ArclogColors.deepBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? ArclogColors.error
                : ArclogColors.circuitLine,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Cover miniature ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: game.coverImagePath != null
                  ? Image.file(
                      File(game.coverImagePath!),
                      width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36, height: 36,
                        color: ArclogColors.surfaceDark,
                        child: const Icon(Icons.videogame_asset_outlined,
                            size: 18, color: ArclogColors.textSecondary),
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      color: ArclogColors.surfaceDark,
                      child: const Icon(Icons.videogame_asset_outlined,
                          size: 18, color: ArclogColors.textSecondary),
                    ),
            ),
            const SizedBox(width: 12),

            // ── Nom + infos ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected
                          ? ArclogColors.textPrimary
                          : ArclogColors.textPrimary
                              .withValues(alpha: 0.80),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      GameStatusBadge(status: game.status, compact: true),
                      const SizedBox(width: 6),
                      Icon(Icons.timer_outlined,
                          size: 10,
                          color: ArclogColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        ArclogFormatters.playTime(
                            game.totalPlayTimeMinutes),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: ArclogColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Checkbox ────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? ArclogColors.error : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? ArclogColors.error
                      : ArclogColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 14, color: ArclogColors.textPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
