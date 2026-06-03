import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../state/player_providers.dart';
import '../state/steam_providers.dart';
import '../widgets/sheet_utils.dart';
import 'steam_game_picker_sheet.dart';

class SteamSettingsSheet extends ConsumerStatefulWidget {
  const SteamSettingsSheet({super.key});

  @override
  ConsumerState<SteamSettingsSheet> createState() =>
      _SteamSettingsSheetState();
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Orbitron', fontSize: 9, color: color)),
            ),
          ],
        ),
      );
}

class _SteamSettingsSheetState
    extends ConsumerState<SteamSettingsSheet> {
  late final TextEditingController _steamIdCtrl;

  @override
  void initState() {
    super.initState();
    // Valeurs en cache (peuvent être vides si les providers chargent encore)
    _steamIdCtrl = TextEditingController(
      text: ref.read(steamIdProvider).valueOrNull ?? '',
    );
    if (_steamIdCtrl.text.isEmpty) _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final steamId = await ref.read(steamIdProvider.future);
    if (!mounted) return;
    if (_steamIdCtrl.text.isEmpty && steamId.isNotEmpty) {
      _steamIdCtrl.text = steamId;
    }
  }

  @override
  void dispose() {
    _steamIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final id = _steamIdCtrl.text.trim();
    if (id.isNotEmpty) await ref.read(steamIdProvider.notifier).setId(id);
  }

  Future<void> _fetchAndPick() async {
    await _saveSettings();
    ref.read(steamSyncProvider.notifier).reset();
    await ref.read(steamSyncProvider.notifier).fetchGames();

    // Ouvre le picker si des jeux ont été récupérés
    if (!mounted) return;
    final games = ref.read(steamSyncProvider).availableGames;
    if (games.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SteamGamePickerSheet(games: games),
    );

    // Après fermeture du picker, vider la liste
    if (mounted) ref.read(steamSyncProvider.notifier).clearGames();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(steamSyncProvider);
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ArclogColors.cyanGlow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: ArclogColors.cyanGlow.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.sports_esports,
                    color: ArclogColors.cyanGlow, size: 20),
              ),
              const SizedBox(width: 12),
              Text('SYNCHRONISATION STEAM', style: tt.titleLarge),
            ],
          ),
          const SizedBox(height: 20),

          // ── Steam ID ──────────────────────────────────────────────────────
          SheetField(
            ctrl: _steamIdCtrl,
            label: 'Steam ID ou pseudo',
            hint: 'monpseudo  ou  76561198XXXXXXXXX',
          ),
          const SizedBox(height: 4),
          const Text(
            'Pseudo Steam ou SteamID64 (steamid.io) — profil Steam doit être Public',
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 9,
                color: ArclogColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Résultat ──────────────────────────────────────────────────────
          if (syncState.status == SteamSyncStatus.success &&
              syncState.result != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ArclogColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: ArclogColors.success.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: ArclogColors.success, size: 16),
                      const SizedBox(width: 8),
                      const Text('IMPORTATION TERMINÉE',
                          style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ArclogColors.success)),
                    ],
                  ),
                  if (syncState.result!.importedGames > 0)
                    _ResultRow(
                      icon: Icons.add_circle_outline,
                      label:
                          '${syncState.result!.importedGames} jeu(x) importé(s)',
                      color: ArclogColors.cyanGlow,
                    ),
                  if (syncState.result!.updatedGames > 0)
                    _ResultRow(
                      icon: Icons.update,
                      label:
                          '${syncState.result!.updatedGames} jeu(x) mis à jour',
                      color: ArclogColors.success,
                    ),
                  if (syncState.result!.updatedAchievements > 0)
                    _ResultRow(
                      icon: Icons.emoji_events_outlined,
                      label:
                          '${syncState.result!.updatedAchievements} succès synchronisé(s)',
                      color: ArclogColors.electricYellow,
                    ),
                  if (!syncState.result!.hasChanges)
                    const _ResultRow(
                      icon: Icons.info_outline,
                      label: 'Tout est déjà à jour',
                      color: ArclogColors.textSecondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Erreur ────────────────────────────────────────────────────────
          if (syncState.status == SteamSyncStatus.error &&
              syncState.errorMessage != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ArclogColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: ArclogColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: ArclogColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncState.errorMessage!,
                      style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: ArclogColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Boutons ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: syncState.isLoading ? null : _saveSettings,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ArclogColors.circuitLine),
                    foregroundColor: ArclogColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ENREGISTRER',
                      style:
                          TextStyle(fontFamily: 'Orbitron', fontSize: 10)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: syncState.isLoading ? null : _fetchAndPick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArclogColors.cyanGlow,
                    foregroundColor: ArclogColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: syncState.isLoadingGames
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ArclogColors.deepBlack))
                      : const Icon(Icons.sports_esports, size: 16),
                  label: Text(
                    syncState.isLoadingGames
                        ? 'CHARGEMENT…'
                        : 'CHOISIR LES JEUX',
                    style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
