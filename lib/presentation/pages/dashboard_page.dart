import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/game.dart';
import '../animations/animated_neon_background.dart';
import '../state/active_session_provider.dart';
import '../state/game_providers.dart';
import '../state/player_providers.dart';
import '../state/player_providers.dart' show steamAvatarProvider;
import '../state/steam_providers.dart';
import '../widgets/arclog_error_view.dart';
import '../widgets/circuit_timeline.dart';
import '../widgets/energy_progress_bar.dart';
import '../widgets/game_badges.dart';
import '../widgets/neon_card.dart';
import '../sheets/action_chooser_sheet.dart';
import '../sheets/add_game_sheet.dart';
import '../sheets/game_delete_picker_sheet.dart';
import '../sheets/steam_game_picker_sheet.dart';
import '../sheets/steam_settings_sheet.dart';
import '../sheets/chrono_start_sheet.dart';
import '../sheets/chrono_stop_sheet.dart';
import '../sheets/quick_add_session_sheet.dart';
import 'game_detail_page.dart';

// ── Tri du carousel ──────────────────────────────────────────────────────────

enum CarouselSort { recent, playTime, progress }

final carouselSortProvider =
    StateProvider<CarouselSort>((ref) => CarouselSort.recent);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);
    final isChronoRunning =
        ref.watch(activeSessionProvider.select((s) => s.isRunning));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          AnimatedNeonBackground(
            child: gamesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: ArclogColors.cyanGlow),
              ),
              error: (e, _) => ArclogErrorView(
                error: e,
                onRetry: () => ref.invalidate(gamesProvider),
              ),
              data: (games) => _DashboardBody(games: games),
            ),
          ),
          if (isChronoRunning)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ActiveSessionBanner(
                onStop: () => _showChronoStop(context, ref),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isChronoRunning ? 100 : 0),
        child: FloatingActionButton(
          onPressed: () => _showActionChooser(context, ref),
          backgroundColor: ArclogColors.cyanGlow,
          foregroundColor: ArclogColors.deepBlack,
          tooltip: 'Ajouter',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showChronoStop(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => const ChronoStopSheet(),
    );
  }

  void _showActionChooser(BuildContext context, WidgetRef ref) {
    final steamId = ref.read(steamIdProvider).valueOrNull ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => ActionChooserSheet(
        steamConnected: steamId.isNotEmpty,
        onAddGame: () {
          Navigator.pop(context);
          _openSheet(context, const AddGameSheet());
        },
        onQuickSession: () {
          Navigator.pop(context);
          _openSheet(context, const QuickAddSessionSheet());
        },
        onChrono: () {
          Navigator.pop(context);
          _openSheet(context, const ChronoStartSheet());
        },
        onDeleteGames: () {
          Navigator.pop(context);
          _openDeletePicker(context, ref);
        },
        onImportSteam: () {
          Navigator.pop(context);
          _fetchAndOpenPicker(context, ref);
        },
      ),
    );
  }

  Future<void> _fetchAndOpenPicker(
      BuildContext context, WidgetRef ref) async {
    // Réinitialise l'état et charge la liste Steam directement
    ref.read(steamSyncProvider.notifier).reset();
    await ref.read(steamSyncProvider.notifier).fetchGames();

    if (!context.mounted) return;
    final games = ref.read(steamSyncProvider).availableGames;
    if (games.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SteamGamePickerSheet(games: games),
    );
    ref.read(steamSyncProvider.notifier).clearGames();
  }

  void _openDeletePicker(BuildContext context, WidgetRef ref) {
    final games = ref.read(gamesProvider).valueOrNull ?? [];
    if (games.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameDeletePickerSheet(games: games),
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => sheet,
    );
  }
}

// =============================================================================
// Body
// =============================================================================

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.games});

  final List<Game> games;

  List<ActivityEntry> _recentActivity() {
    final entries = <ActivityEntry>[];

    for (final g in games) {
      for (final s in g.sessions) {
        entries.add(SessionActivity(session: s, game: g));
      }
      for (final a in g.achievements) {
        if (a.isUnlocked && a.unlockedAt != null) {
          entries.add(AchievementActivity(achievement: a, game: g));
        }
      }
      for (final o in g.objectives) {
        if (o.isCompleted && o.completedAt != null) {
          entries.add(ObjectiveActivity(objective: o, game: g));
        }
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(8).toList();
  }

  static double _ratio(Game g) => g.objectiveRatio;

  List<Game> _sorted(List<Game> src, CarouselSort sort) {
    final list = List<Game>.from(src);
    switch (sort) {
      case CarouselSort.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case CarouselSort.playTime:
        list.sort(
            (a, b) => b.totalPlayTimeMinutes.compareTo(a.totalPlayTimeMinutes));
      case CarouselSort.progress:
        list.sort((a, b) => _ratio(b).compareTo(_ratio(a)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(carouselSortProvider);
    final totalMinutes =
        games.fold<int>(0, (sum, g) => sum + g.totalPlayTimeMinutes);
    final totalAchievements =
        games.fold<int>(0, (sum, g) => sum + g.completedObjectivesCount);
    final recent = _recentActivity();
    final sortedGames = _sorted(games, sort);

    return CustomScrollView(
      slivers: [
        // ── AppBar ───────────────────────────────────────────────────────────
        SliverAppBar(
          pinned: false,
          floating: false,
          expandedHeight: 110,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          forceMaterialTransparency: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            title: Image.asset(
              'asset/Images/Logo_Arclog_transparent.png',
              height: 44,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),

        // ── Gamer Stats card ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _GamerStatsCard(
              totalMinutes: totalMinutes,
              gamesCount: games.length,
              achievements: totalAchievements,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _SectionHeader(
            label: 'EN CE MOMENT',
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          ),
        ),

        SliverToBoxAdapter(child: _SortChips(current: sort)),

        // ── Carousel horizontal de jaquettes ─────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: sortedGames.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: NeonCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Aucun jeu — appuyez sur + pour commencer',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    itemCount: sortedGames.length,
                    itemBuilder: (_, i) => _GameCarouselCard(
                      game: sortedGames[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GameDetailPage(gameId: sortedGames[i].id!),
                        ),
                      ),
                      onDelete: () =>
                          _confirmDelete(context, ref, sortedGames[i]),
                    ),
                  ),
          ),
        ),

        SliverToBoxAdapter(
          child: _SectionHeader(
            label: 'ACTIVITÉ RÉCENTE',
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            child: CircuitTimeline(
              entries: recent,
              onTapEntry: (entry) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameDetailPage(
                    gameId: entry.game.id!,
                    initialTab: entry is AchievementActivity ? 1 : 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: const Text('Supprimer le jeu ?',
            style: TextStyle(color: ArclogColors.textPrimary)),
        content: Text(
          'Toutes les sessions et trophées de "${game.title}" seront effacés.',
          style: const TextStyle(color: ArclogColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: ArclogColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: ArclogColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && game.id != null) {
      await ref.read(gamesProvider.notifier).removeGame(game.id!);
    }
  }
}

// =============================================================================
// Gamer Stats Card — Level + XP + mini-stats
// =============================================================================

class _GamerStatsCard extends ConsumerWidget {
  const _GamerStatsCard({
    required this.totalMinutes,
    required this.gamesCount,
    required this.achievements,
  });

  final int totalMinutes;
  final int gamesCount;
  final int achievements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerName = ref.watch(playerNameProvider).valueOrNull ?? 'PLAYER 1';
    final avatarUrl  = ref.watch(steamAvatarProvider).valueOrNull ?? '';

    return NeonCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _editName(context, ref, playerName),
            child: Row(
              children: [
                // Avatar Steam ou icône par défaut
                avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_outline,
                            color: ArclogColors.cyanGlow,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: ArclogColors.cyanGlow,
                        size: 28,
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ArclogColors.cyanGlow,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  color: ArclogColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: ArclogColors.circuitLine),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                value: '$gamesCount',
                label: 'JEUX',
                icon: Icons.videogame_asset_outlined,
              ),
              _MiniStat(
                value: ArclogFormatters.playTime(totalMinutes),
                label: 'JOUÉ',
                icon: Icons.timer_outlined,
              ),
              _MiniStat(
                value: '$achievements',
                label: 'QUÊTES',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: ArclogColors.circuitLine),
          const SizedBox(height: 12),
          _SteamSyncButton(onSettingsTap: () => _openSteamSettings(context, ref)),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => _PlayerNameDialog(initial: current),
    );
    if (result != null && context.mounted) {
      ref.read(playerNameProvider.notifier).setName(result);
    }
  }

  void _openSteamSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => const SteamSettingsSheet(),
    );
  }
}

class _SteamSyncButton extends ConsumerWidget {
  const _SteamSyncButton({required this.onSettingsTap});
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState    = ref.watch(steamSyncProvider);
    final steamId      = ref.watch(steamIdProvider).valueOrNull ?? '';
    final isConfigured = steamId.isNotEmpty;

    if (!isConfigured) {
      return _SteamChip(
        label: 'SE CONNECTER À STEAM',
        icon: Icons.sports_esports,
        color: ArclogColors.electricYellow,
        borderColor: ArclogColors.electricYellow.withValues(alpha: 0.6),
        onTap: onSettingsTap,
      );
    }

    final isSyncing = syncState.isSyncing;

    return Row(
      children: [
        // ── Choisir / importer des jeux ──────────────────────────────────
        Expanded(
          child: _SteamChip(
            label: 'MON COMPTE STEAM',
            icon: Icons.add_circle_outline,
            color: ArclogColors.cyanGlow,
            borderColor: ArclogColors.cyanGlow.withValues(alpha: 0.4),
            onTap: syncState.isLoading ? null : onSettingsTap,
            settingsIcon: true,
            onSettingsTap: onSettingsTap,
          ),
        ),
        const SizedBox(width: 8),
        // ── Sync rapide (jeux déjà liés) ─────────────────────────────────
        Expanded(
          child: _SteamChip(
            label: isSyncing
                ? 'SYNC…'
                : syncState.status == SteamSyncStatus.success
                    ? 'SYNCHRO OK'
                    : syncState.status == SteamSyncStatus.error
                        ? 'SYNC ERREUR'
                        : 'SYNC STEAM',
            icon: syncState.status == SteamSyncStatus.success
                ? Icons.check_circle_outline
                : syncState.status == SteamSyncStatus.error
                    ? Icons.error_outline
                    : Icons.sync,
            color: syncState.status == SteamSyncStatus.success
                ? ArclogColors.success
                : syncState.status == SteamSyncStatus.error
                    ? ArclogColors.error
                    : ArclogColors.electricYellow,
            borderColor: (syncState.status == SteamSyncStatus.success
                    ? ArclogColors.success
                    : syncState.status == SteamSyncStatus.error
                        ? ArclogColors.error
                        : ArclogColors.electricYellow)
                .withValues(alpha: 0.45),
            loading: isSyncing,
            onTap: isSyncing
                ? null
                : () => ref.read(steamSyncProvider.notifier).syncAll(),
          ),
        ),
      ],
    );
  }
}

class _SteamChip extends StatelessWidget {
  const _SteamChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.loading = false,
    this.settingsIcon = false,
    this.onSettingsTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool loading;
  final bool settingsIcon;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: color),
                  )
                : Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (settingsIcon && onSettingsTap != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onSettingsTap,
                child: Icon(Icons.settings_outlined,
                    size: 10, color: color.withValues(alpha: 0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerNameDialog extends StatefulWidget {
  const _PlayerNameDialog({required this.initial});
  final String initial;

  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial == 'PLAYER 1' ? '' : widget.initial,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.pop(context, _ctrl.text.trim());
  void _cancel() => Navigator.pop(context, null);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArclogColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ArclogColors.circuitLine),
      ),
      title: const Text(
        'NOM DU JOUEUR',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 14,
          color: ArclogColors.cyanGlow,
          letterSpacing: 2,
        ),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        maxLength: 20,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          color: ArclogColors.textPrimary,
        ),
        cursorColor: ArclogColors.cyanGlow,
        decoration: InputDecoration(
          hintText: 'PLAYER 1',
          hintStyle: const TextStyle(color: ArclogColors.textSecondary),
          counterStyle: const TextStyle(
              color: ArclogColors.textSecondary, fontSize: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: ArclogColors.circuitLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: ArclogColors.cyanGlow, width: 1.5),
          ),
          filled: true,
          fillColor: ArclogColors.deepBlack,
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('ANNULER',
              style: TextStyle(color: ArclogColors.textSecondary)),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text('VALIDER',
              style: TextStyle(color: ArclogColors.cyanGlow)),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: ArclogColors.electricYellow),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ArclogColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              color: ArclogColors.electricYellow,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Chips de tri du carousel
// =============================================================================

class _SortChips extends ConsumerWidget {
  const _SortChips({required this.current});
  final CarouselSort current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 14),
      child: Row(
        children: [
          _SortChip(
            label: 'RÉCENT',
            icon: Icons.history,
            active: current == CarouselSort.recent,
            onTap: () => ref.read(carouselSortProvider.notifier).state =
                CarouselSort.recent,
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'TEMPS DE JEU',
            icon: Icons.timer_outlined,
            active: current == CarouselSort.playTime,
            onTap: () => ref.read(carouselSortProvider.notifier).state =
                CarouselSort.playTime,
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'PROGRESSION',
            icon: Icons.trending_up,
            active: current == CarouselSort.progress,
            onTap: () => ref.read(carouselSortProvider.notifier).state =
                CarouselSort.progress,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? ArclogColors.cyanGlow : ArclogColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? ArclogColors.cyanGlow.withValues(alpha: 0.14)
              : ArclogColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? ArclogColors.cyanGlow
                : ArclogColors.cyanGlow.withValues(alpha: 0.28),
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: ArclogColors.cyanGlow.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: color.withValues(alpha: active ? 1.0 : 0.70),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color.withValues(alpha: active ? 1.0 : 0.70),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Section header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.padding});
  final String label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: ArclogColors.electricYellow,
              boxShadow: [
                BoxShadow(
                  color: ArclogColors.electricYellow.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ArclogColors.cyanGlow,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Carte jaquette pour le carousel horizontal
// =============================================================================

class _GameCarouselCard extends StatelessWidget {
  const _GameCarouselCard({
    required this.game,
    required this.onTap,
    required this.onDelete,
  });

  final Game game;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Widget _steamOrPlaceholder(Game g) {
    // Priorité : image portrait 600×900 (parfaite pour les cartes)
    // Fallback : header paysage 460×215
    if (g.steamAppId != null) {
      return Image.network(
        'https://cdn.cloudflare.steamstatic.com/steam/apps/${g.steamAppId}/library_600x900.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => g.steamCoverUrl != null
            ? Image.network(
                g.steamCoverUrl!,
                fit: BoxFit.cover,
                // Recadrage haut pour les headers paysage dans une carte portrait
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) =>
                    _PlaceholderCover(title: g.title),
              )
            : _PlaceholderCover(title: g.title),
      );
    }
    if (g.steamCoverUrl != null) {
      return Image.network(
        g.steamCoverUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => _PlaceholderCover(title: g.title),
      );
    }
    return _PlaceholderCover(title: g.title);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ArclogColors.cyanGlow.withValues(alpha: 0.18),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              game.coverImagePath != null
                  ? Image.file(
                      File(game.coverImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _steamOrPlaceholder(game),
                    )
                  : _steamOrPlaceholder(game),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.35, 1],
                      colors: [
                        ArclogColors.deepBlack.withValues(alpha: 0),
                        ArclogColors.deepBlack.withValues(alpha: 0.7),
                        ArclogColors.deepBlack.withValues(alpha: 0.97),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ArclogColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 11,
                              color: ArclogColors.electricYellow),
                          const SizedBox(width: 3),
                          Text(
                            ArclogFormatters.playTime(
                                game.totalPlayTimeMinutes),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 10,
                              color: ArclogColors.electricYellow,
                            ),
                          ),
                          if (game.achievements.isNotEmpty) ...[
                            const Spacer(),
                            const Icon(Icons.emoji_events_outlined,
                                size: 11,
                                color: ArclogColors.electricYellow),
                            const SizedBox(width: 3),
                            Text(
                              '${game.unlockedAchievementsCount}/${game.achievements.length}',
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                color: ArclogColors.electricYellow,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (game.objectives.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.flag_outlined,
                                size: 11,
                                color: ArclogColors.cyanGlow),
                            const SizedBox(width: 3),
                            Text(
                              '${game.completedObjectivesCount}/${game.objectives.length}',
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                color: ArclogColors.cyanGlow,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      EnergyProgressBar(
                          value: game.achievementRatio, height: 4),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 4,
                        runSpacing: 3,
                        children: [
                          GameStatusBadge(
                              status: game.status, compact: true),
                          if (game.platform != null &&
                              game.platform!.isNotEmpty)
                            PlatformBadge(
                                platform: game.platform!, compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ArclogColors.cyanGlow.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArclogColors.surfaceDark, Color(0xFF0A1A26)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: GridPaper(
                color: ArclogColors.cyanGlow,
                divisions: 1,
                subdivisions: 1,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videogame_asset_outlined,
                  color: ArclogColors.cyanGlow.withValues(alpha: 0.5),
                  size: 40,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      color: ArclogColors.cyanGlow.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bandeau session en cours (chronomètre)
// =============================================================================

class _ActiveSessionBanner extends ConsumerWidget {
  const _ActiveSessionBanner({required this.onStop});
  final VoidCallback onStop;

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    if (!session.isRunning) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, _) {
        final elapsed = session.elapsed;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF050A0E).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: ArclogColors.success.withValues(alpha: 0.6),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: ArclogColors.success.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.radio_button_on,
                  color: ArclogColors.success, size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (session.gameTitle ?? '').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ArclogColors.textSecondary,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _fmt(elapsed),
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: ArclogColors.success,
                        height: 1.1,
                        shadows: [
                          Shadow(
                              color:
                                  ArclogColors.success.withValues(alpha: 0.8),
                              blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: ArclogColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: ArclogColors.error.withValues(alpha: 0.7)),
                    boxShadow: [
                      BoxShadow(
                          color: ArclogColors.error.withValues(alpha: 0.2),
                          blurRadius: 8),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop, color: ArclogColors.error, size: 22),
                      SizedBox(height: 2),
                      Text(
                        'STOP',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: ArclogColors.error,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
