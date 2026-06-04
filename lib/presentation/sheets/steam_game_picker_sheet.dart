import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/steam_service.dart';
import '../state/steam_providers.dart';

class SteamGamePickerSheet extends ConsumerStatefulWidget {
  const SteamGamePickerSheet({super.key, required this.games});

  final List<SteamGame> games;

  @override
  ConsumerState<SteamGamePickerSheet> createState() =>
      _SteamGamePickerSheetState();
}

class _SteamGamePickerSheetState
    extends ConsumerState<SteamGamePickerSheet> {
  final _searchCtrl = TextEditingController();
  final _selected = <int>{};
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SteamGame> get _filtered {
    if (_query.isEmpty) return widget.games;
    final q = _query.toLowerCase();
    return widget.games.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  void _toggleAll() {
    final filtered = _filtered;
    final allSelected = filtered.every((g) => _selected.contains(g.appId));
    setState(() {
      if (allSelected) {
        for (final g in filtered) _selected.remove(g.appId);
      } else {
        for (final g in filtered) _selected.add(g.appId);
      }
    });
  }

  bool get _allFilteredSelected =>
      _filtered.isNotEmpty &&
      _filtered.every((g) => _selected.contains(g.appId));

  Future<void> _import() async {
    if (_selected.isEmpty) return;
    await ref
        .read(steamSyncProvider.notifier)
        .importSelected(_selected.toList());
    if (mounted) {
      // Ferme le picker ET la sheet des paramètres pour revenir au dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(steamSyncProvider);
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
            // ── Handle + header ───────────────────────────────────────────
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
                      const Icon(Icons.sports_esports,
                          color: ArclogColors.cyanGlow, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('IMPORTER DES JEUX STEAM',
                            style: tt.titleLarge),
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

                  // ── Barre de recherche ───────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    style: tt.bodyLarge,
                    cursorColor: ArclogColors.cyanGlow,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un jeu…',
                      hintStyle: tt.bodyMedium,
                      prefixIcon: const Icon(Icons.search,
                          color: ArclogColors.cyanGlow, size: 18),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: ArclogColors.textSecondary, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: ArclogColors.circuitLine),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: ArclogColors.cyanGlow, width: 1.5),
                      ),
                      filled: true,
                      fillColor: ArclogColors.deepBlack,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Actions rapides ───────────────────────────────────────
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
                              color: ArclogColors.cyanGlow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _allFilteredSelected
                                  ? 'TOUT DÉSÉLECTIONNER'
                                  : 'TOUT SÉLECTIONNER',
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 9,
                                color: ArclogColors.cyanGlow,
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
                      child: Text(
                        'Aucun jeu trouvé',
                        style: tt.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final game = filtered[i];
                        final isSelected = _selected.contains(game.appId);
                        return _GameTile(
                          game: game,
                          selected: isSelected,
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selected.remove(game.appId);
                            } else {
                              _selected.add(game.appId);
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
                  // Compteur de sélection
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selected.length} sélectionné(s)',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ArclogColors.cyanGlow,
                          ),
                        ),
                        if (_selected.isEmpty)
                          const Text(
                            'Sélectionne au moins un jeu',
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
                  // Bouton importer
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: (_selected.isEmpty || syncState.isSyncing)
                          ? null
                          : _import,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected.isEmpty
                            ? ArclogColors.circuitLine
                            : ArclogColors.cyanGlow,
                        foregroundColor: ArclogColors.deepBlack,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      icon: syncState.isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArclogColors.deepBlack))
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        syncState.isSyncing ? 'IMPORT…' : 'IMPORTER',
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

// ── Tuile d'un jeu Steam ──────────────────────────────────────────────────────

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final SteamGame game;
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
              ? ArclogColors.cyanGlow.withValues(alpha: 0.10)
              : ArclogColors.deepBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? ArclogColors.cyanGlow
                : ArclogColors.circuitLine,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Icône du jeu ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: game.iconUrl != null
                  ? Image.network(
                      game.iconUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
            const SizedBox(width: 12),

            // ── Nom + playtime ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? ArclogColors.textPrimary
                          : ArclogColors.textPrimary
                              .withValues(alpha: 0.80),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 10,
                          color: ArclogColors.electricYellow
                              .withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text(
                        ArclogFormatters.playTime(game.playtimeMinutes),
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: ArclogColors.electricYellow
                              .withValues(alpha: 0.8),
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
                color: selected
                    ? ArclogColors.cyanGlow
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? ArclogColors.cyanGlow
                      : ArclogColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 14, color: ArclogColors.deepBlack)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 36,
        height: 36,
        color: ArclogColors.surfaceDark,
        child: const Icon(Icons.videogame_asset_outlined,
            size: 18, color: ArclogColors.cyanGlow),
      );
}
