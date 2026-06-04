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

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ArclogColors.electricYellow,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          body,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            color: ArclogColors.textPrimary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
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

class _SteamSettingsSheetState extends ConsumerState<SteamSettingsSheet> {
  late final TextEditingController _steamIdCtrl;

  @override
  void initState() {
    super.initState();
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

    if (!mounted) return;
    final games = ref.read(steamSyncProvider).availableGames;
    if (games.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SteamGamePickerSheet(games: games),
    );

    if (mounted) ref.read(steamSyncProvider.notifier).clearGames();
  }

  // ── Aide ─────────────────────────────────────────────────────────────────

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ArclogColors.cyanGlow, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.help_outline,
                color: ArclogColors.cyanGlow, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Comment lier votre compte Steam ?',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ArclogColors.cyanGlow,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpSection(
                title: '🔑  Votre ID',
                body: 'Entrez votre SteamID classique (17 chiffres) OU votre nom d\'URL personnalisée.',
              ),
              SizedBox(height: 14),
              _HelpSection(
                title: '📍  Où le trouver ?',
                body: 'Dans Steam, allez dans Détails du compte (pour l\'ID) ou sur votre page de profil (pour voir votre URL personnalisée).',
              ),
              SizedBox(height: 14),
              _HelpSection(
                title: '🔓  Visibilité',
                body: 'Dans Modifier le profil > Paramètres de confidentialité, assurez-vous que Mon profil et Détails des jeux sont sur « Public » pour qu\'Arclog puisse récupérer vos données.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('COMPRIS',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  color: ArclogColors.cyanGlow,
                )),
          ),
        ],
      ),
    );
  }

  // ── Déconnexion Steam ──────────────────────────────────────────────────────

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: const Text('Se déconnecter de Steam ?',
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                color: ArclogColors.textPrimary)),
        content: const Text(
          'Ton Steam ID et ton avatar seront effacés. '
          'Les jeux importés restent dans ta bibliothèque.',
          style: TextStyle(
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
            child: const Text('DÉCONNECTER',
                style: TextStyle(color: ArclogColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(steamIdProvider.notifier).setId('');
    await ref.read(steamAvatarProvider.notifier).setUrl('');
    ref.read(steamSyncProvider.notifier).reset();
    setState(() => _steamIdCtrl.clear());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(steamSyncProvider);
    final steamId  = ref.watch(steamIdProvider).valueOrNull ?? '';
    final tt = Theme.of(context).textTheme;
    final isConnected = steamId.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),

          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36, height: 36,
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
              Expanded(
                child: Text('SYNCHRONISATION STEAM', style: tt.titleLarge),
              ),
              // Bouton déconnexion (visible si déjà connecté)
              if (isConnected)
                TextButton.icon(
                  onPressed: syncState.isLoading ? null : _disconnect,
                  style: TextButton.styleFrom(
                    foregroundColor: ArclogColors.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.logout, size: 14),
                  label: const Text('DÉCO',
                      style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Steam ID ──────────────────────────────────────────────────────
          Row(
            children: [
              const Text('Steam ID ou pseudo',
                  style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: ArclogColors.electricYellow,
                      letterSpacing: 2)),
              const Spacer(),
              GestureDetector(
                onTap: _showHelp,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ArclogColors.cyanGlow.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: ArclogColors.cyanGlow.withValues(alpha: 0.45)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline,
                          size: 12, color: ArclogColors.cyanGlow),
                      SizedBox(width: 5),
                      Text('COMMENT FAIRE ?',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: ArclogColors.cyanGlow,
                            letterSpacing: 0.5,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SheetField(
            ctrl: _steamIdCtrl,
            label: '',
            hint: 'monpseudo  ou  76561198XXXXXXXXX',
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

          // ── Bouton principal — plus visible ───────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: syncState.isLoading ? null : _fetchAndPick,
              style: ElevatedButton.styleFrom(
                // Jaune électrique pour ressortir sur le fond sombre
                backgroundColor: ArclogColors.electricYellow,
                foregroundColor: ArclogColors.deepBlack,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 4,
                shadowColor:
                    ArclogColors.electricYellow.withValues(alpha: 0.5),
              ),
              icon: syncState.isLoadingGames
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ArclogColors.deepBlack))
                  : const Icon(Icons.sports_esports, size: 20),
              label: Text(
                syncState.isLoadingGames
                    ? 'CHARGEMENT…'
                    : isConnected
                        ? 'AJOUTER DES JEUX STEAM'
                        : 'SE CONNECTER À STEAM',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
