import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/objective.dart';
import '../../domain/entities/session.dart';
import '../animations/animated_neon_background.dart';
import '../state/game_detail_providers.dart';
import '../state/game_providers.dart';
import '../widgets/achievement_tile.dart';
import '../widgets/arclog_error_view.dart';
import '../widgets/electric_timeline.dart';
import '../widgets/game_badges.dart';
import '../widgets/neon_card.dart';
import '../widgets/objective_tile.dart';
import '../sheets/add_achievement_sheet.dart';
import '../sheets/add_objective_sheet.dart';
import '../sheets/add_session_sheet.dart';
import '../sheets/edit_game_sheet.dart';
import '../sheets/edit_objective_sheet.dart';
import '../sheets/edit_session_sheet.dart';

class GameDetailPage extends ConsumerWidget {
  const GameDetailPage({super.key, required this.gameId, this.initialTab = 0});
  final int gameId;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));

    // ── Actions AppBar définies localement ────────────────────────────────────
    Future<void> confirmDelete(Game game) async {
      final ok = await showDialog<bool>(
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
            style: const TextStyle(color: ArclogColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler',
                  style: TextStyle(color: ArclogColors.textSecondary))),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: ArclogColors.error))),
          ],
        ),
      );
      if ((ok ?? false) && game.id != null && context.mounted) {
        await ref.read(gamesProvider.notifier).removeGame(game.id!);
        if (context.mounted) Navigator.pop(context);
      }
    }

    void showEdit(Game game) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: ArclogColors.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: ArclogColors.circuitLine),
        ),
        builder: (_) => EditGameSheet(
          gameId: gameId,
          currentTitle: game.title,
          currentCoverPath: game.coverImagePath,
          currentStatus: game.status,
          currentPlatform: game.platform,
          currentSteamAppId: game.steamAppId,
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: gameAsync.whenOrNull(
          data: (game) => AppBar(
            backgroundColor: ArclogColors.deepBlack.withValues(alpha: 0.82),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: ArclogColors.cyanGlow),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              game.title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ArclogColors.cyanGlow,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: ArclogColors.error),
                tooltip: 'Supprimer le jeu',
                onPressed: () => confirmDelete(game),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: ArclogColors.cyanGlow),
                tooltip: 'Modifier le jeu',
                onPressed: () => showEdit(game),
              ),
            ],
          ),
        ),
        body: AnimatedNeonBackground(
          child: gameAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ArclogColors.cyanGlow),
            ),
            error: (e, _) => ArclogErrorView(
              error: e,
              onRetry: () => ref.invalidate(gameDetailProvider(gameId)),
            ),
            data: (game) => _DetailBody(game: game, gameId: gameId),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Corps principal avec NestedScrollView
// =============================================================================

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.game, required this.gameId});
  final Game game;
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionEntries = game.sessions
        .map((s) => (session: s, game: game))
        .toList()
      ..sort((a, b) => b.session.startedAt.compareTo(a.session.startedAt));

    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _OverviewCard(game: game),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionHeader(
            label: 'SESSIONS',
            actionLabel: '+ SESSION',
            onAction: () => _showAddSessionSheet(context),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElectricTimeline(
              entries: sessionEntries,
              showGameTitle: false,
              onDeleteSession: (s) =>
                  _confirmDeleteSession(context, ref, s),
              onEditSession: (s) => _showEditSessionSheet(context, s),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              tabs: const [
                Tab(text: 'OBJECTIFS'),
                Tab(text: 'TROPHÉES'),
              ],
              labelColor: ArclogColors.cyanGlow,
              unselectedLabelColor: ArclogColors.textSecondary,
              indicatorColor: ArclogColors.cyanGlow,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        children: [
          _ObjectivesTab(gameId: gameId),
          _AchievementsTab(gameId: gameId),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Game game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => EditGameSheet(
        gameId: gameId,
        currentTitle: game.title,
        currentCoverPath: game.coverImagePath,
        currentStatus: game.status,
        currentPlatform: game.platform,
        currentSteamAppId: game.steamAppId,
      ),
    );
  }

  void _showAddSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => AddSessionSheet(gameId: gameId),
    );
  }

  void _showEditSessionSheet(BuildContext context, Session session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => EditSessionSheet(gameId: gameId, session: session),
    );
  }

  Future<void> _confirmDeleteSession(
      BuildContext context, WidgetRef ref, Session s) async {
    if (s.id != null) {
      await ref
          .read(gameDetailProvider(gameId).notifier)
          .deleteSession(s.id!);
    }
  }

  Future<void> _confirmDeleteGame(
      BuildContext context, WidgetRef ref, Game game) async {
    final ok = await _confirmDialog(
      context,
      title: 'Supprimer le jeu ?',
      content:
          'Toutes les sessions et trophées de "${game.title}" seront effacés.',
    );
    if (ok && game.id != null && context.mounted) {
      await ref.read(gamesProvider.notifier).removeGame(game.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<bool> _confirmDialog(BuildContext context,
      {required String title, required String content}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: Text(title,
            style: const TextStyle(color: ArclogColors.textPrimary)),
        content: Text(content,
            style: const TextStyle(color: ArclogColors.textSecondary)),
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
    return result ?? false;
  }
}

// =============================================================================
// Overview card (cover + temps + tier)
// =============================================================================

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.game});
  final Game game;

  Widget _steamThumb(Game g) {
    if (g.steamAppId != null) {
      return Image.network(
        'https://cdn.cloudflare.steamstatic.com/steam/apps/${g.steamAppId}/library_600x900.jpg',
        width: 72, height: 72, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => g.steamCoverUrl != null
            ? Image.network(g.steamCoverUrl!,
                width: 72, height: 72, fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink())
            : const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = game.achievementRatio;

    return NeonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (game.coverImagePath != null || game.steamAppId != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: game.coverImagePath != null
                      ? Image.file(File(game.coverImagePath!),
                          width: 72, height: 72, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _steamThumb(game))
                      : _steamThumb(game),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: ArclogColors.electricYellow),
                    const SizedBox(width: 5),
                    Text(
                      ArclogFormatters.playTime(game.totalPlayTimeMinutes),
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ArclogColors.electricYellow,
                      ),
                    ),
                    const Spacer(),
                    _TierBadge(ratio: ratio),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              GameStatusBadge(status: game.status),
              if (game.platform != null && game.platform!.isNotEmpty)
                PlatformBadge(platform: game.platform!),
            ],
          ),
          const SizedBox(height: 14),
          _TierProgressBar(ratio: ratio),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${game.completedObjectivesCount}/${game.objectives.length} objectifs',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: ArclogColors.cyanGlow,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${game.unlockedAchievementsCount}/${game.achievements.length} trophées',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: ArclogColors.electricYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Onglet OBJECTIFS
// =============================================================================

class _ObjectivesTab extends ConsumerWidget {
  const _ObjectivesTab({required this.gameId});
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));

    return gameAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: ArclogColors.cyanGlow)),
      error: (e, _) => ArclogErrorView(error: e),
      data: (game) {
        final objectives = (game.objectives.toList()
          ..sort(
              (a, b) => (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0)));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            _AddButton(
              label: '+ OBJECTIF',
              onTap: () => _showAddObjectiveSheet(context),
            ),
            const SizedBox(height: 12),
            if (objectives.isEmpty)
              const _EmptyState(
                icon: Icons.flag_outlined,
                message: 'Aucun objectif — créez votre première quête !',
              )
            else
              ...objectives.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: Key('obj_${o.id}'),
                    direction: DismissDirection.horizontal,
                    background: _SwipeFavoriteBackground(
                        isFavorite: o.isFavorite),
                    secondaryBackground:
                        const _SwipeDeleteBackground(),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await ref
                            .read(gameDetailProvider(gameId).notifier)
                            .toggleFavoriteObjective(o);
                        return false;
                      }
                      return true;
                    },
                    onDismissed: (_) => ref
                        .read(gameDetailProvider(gameId).notifier)
                        .deleteObjective(o.id!),
                    child: ObjectiveTile(
                      objective: o,
                      onToggle: () => ref
                          .read(gameDetailProvider(gameId).notifier)
                          .toggleObjective(o),
                      onIncrement: () => ref
                          .read(gameDetailProvider(gameId).notifier)
                          .incrementObjective(o),
                      onDecrement: () => ref
                          .read(gameDetailProvider(gameId).notifier)
                          .decrementObjective(o),
                      onEdit: () => _showEditObjectiveSheet(context, o),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddObjectiveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => AddObjectiveSheet(gameId: gameId),
    );
  }

  void _showEditObjectiveSheet(BuildContext context, Objective o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArclogColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: ArclogColors.circuitLine),
      ),
      builder: (_) => EditObjectiveSheet(gameId: gameId, objective: o),
    );
  }
}

// =============================================================================
// Onglet TROPHÉES
// =============================================================================

class _AchievementsTab extends ConsumerStatefulWidget {
  const _AchievementsTab({required this.gameId});
  final int gameId;

  @override
  ConsumerState<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends ConsumerState<_AchievementsTab> {
  bool _refreshing = false;

  Future<void> _refreshSteam() async {
    setState(() => _refreshing = true);
    try {
      await ref
          .read(gameDetailProvider(widget.gameId).notifier)
          .refreshFromSteam();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(gameDetailProvider(widget.gameId));

    return gameAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: ArclogColors.cyanGlow)),
      error: (e, _) => ArclogErrorView(error: e),
      data: (game) {
        final hasSteam = game.steamAppId != null;
        final achievements = (game.achievements.toList()
          ..sort((a, b) {
            final fav = (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0);
            if (fav != 0) return fav;
            return (b.steamApiName != null ? 1 : 0) -
                (a.steamApiName != null ? 1 : 0);
          }));
        final steamCount =
            achievements.where((a) => a.steamApiName != null).length;
        final manualCount = achievements.length - steamCount;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // ── Bannière statut Steam ─────────────────────────────────────
            if (hasSteam)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ArclogColors.cyanGlow.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          ArclogColors.cyanGlow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports,
                        size: 14, color: ArclogColors.cyanGlow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steamCount > 0
                            ? '$steamCount Steam · $manualCount manuel(s)'
                            : 'Lance une synchro pour importer les trophées',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          color: ArclogColors.cyanGlow,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _refreshing ? null : _refreshSteam,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ArclogColors.cyanGlow
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: ArclogColors.cyanGlow
                                  .withValues(alpha: 0.5)),
                        ),
                        child: _refreshing
                            ? const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: ArclogColors.cyanGlow),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sync,
                                      size: 11,
                                      color: ArclogColors.cyanGlow),
                                  SizedBox(width: 4),
                                  Text('SYNC',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: ArclogColors.cyanGlow,
                                      )),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Liste ─────────────────────────────────────────────────────
            if (achievements.isEmpty)
              _EmptyState(
                icon: Icons.emoji_events_outlined,
                message: hasSteam
                    ? 'Lance une synchronisation Steam pour importer tes trophées'
                    : 'Lie un Steam App ID à ce jeu puis synchronise',
                color: ArclogColors.electricYellow,
              )
            else
              ...achievements.map((a) {
                final isSteam = a.steamApiName != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: Key('ach_${a.id}'),
                    direction: isSteam
                        ? DismissDirection.startToEnd
                        : DismissDirection.horizontal,
                    background: _SwipeFavoriteBackground(
                        isFavorite: a.isFavorite),
                    secondaryBackground: isSteam
                        ? null
                        : const _SwipeDeleteBackground(),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await ref
                            .read(gameDetailProvider(widget.gameId)
                                .notifier)
                            .toggleFavoriteAchievement(a);
                        return false;
                      }
                      return !isSteam;
                    },
                    onDismissed: (_) => ref
                        .read(gameDetailProvider(widget.gameId).notifier)
                        .deleteAchievement(a.id!),
                    child: AchievementTile(
                      achievement: a,
                      onToggle: isSteam
                          ? null
                          : () => ref
                              .read(gameDetailProvider(widget.gameId)
                                  .notifier)
                              .toggleAchievement(a),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Tier progress bar
// =============================================================================

class _TierProgressBar extends StatelessWidget {
  const _TierProgressBar({required this.ratio});
  final double ratio;

  static const _labels = ['NEWCOMER', 'APPRENTICE', 'VETERAN', 'LEGEND'];
  static const _count = 4;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final currentTier = (ratio * _count).floor().clamp(0, _count - 1);

    return Column(
      children: [
        Row(
          children: List.generate(_count, (i) {
            final lower = i / _count;
            final fill =
                ((ratio - lower) / (1 / _count)).clamp(0.0, 1.0);
            final isCompleted = i < currentTier;
            final color = (isCompleted || ratio >= 1.0)
                ? ArclogColors.electricYellow
                : ArclogColors.cyanGlow;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _count - 1 ? 4 : 0),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: ArclogColors.circuitLine,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    if (fill > 0)
                      FractionallySizedBox(
                        widthFactor: fill,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              color.withValues(alpha: 0.65),
                              color,
                            ]),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(_count, (i) {
            final isActive =
                i == (ratio * _count).floor().clamp(0, _count - 1);
            final isCompleted =
                ratio > 0 && i < (ratio * _count).floor();
            return Expanded(
              child: Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(
                  fontSize: 9,
                  color: isActive
                      ? ArclogColors.cyanGlow
                      : isCompleted
                          ? ArclogColors.electricYellow
                          : ArclogColors.textSecondary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.ratio});
  final double ratio;

  String get _label {
    if (ratio >= 1.0) return 'LEGEND';
    if (ratio >= 0.75) return 'VETERAN';
    if (ratio >= 0.50) return 'APPRENTICE';
    return 'NEWCOMER';
  }

  Color get _color =>
      ratio >= 0.75 ? ArclogColors.electricYellow : ArclogColors.cyanGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: _color),
        borderRadius: BorderRadius.circular(6),
        color: _color.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// =============================================================================
// Widgets locaux partagés
// =============================================================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(
        color: ArclogColors.deepBlack,
        child: Column(
          children: [
            Container(height: 1, color: ArclogColors.circuitLine),
            tabBar,
          ],
        ),
      );

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.actionLabel,
    required this.onAction,
    required this.padding,
  });
  final String label;
  final String actionLabel;
  final VoidCallback onAction;
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
                    color:
                        ArclogColors.electricYellow.withValues(alpha: 0.5),
                    blurRadius: 6)
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
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                    color: ArclogColors.cyanGlow.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(6),
                color: ArclogColors.cyanGlow.withValues(alpha: 0.08),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ArclogColors.cyanGlow,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.label,
    required this.onTap,
    this.color = ArclogColors.cyanGlow,
  });
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          color: color.withValues(alpha: 0.07),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.color = ArclogColors.cyanGlow,
  });
  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeFavoriteBackground extends StatelessWidget {
  const _SwipeFavoriteBackground({required this.isFavorite});
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    const color = ArclogColors.electricYellow;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFavorite ? Icons.star : Icons.star_outline,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            isFavorite ? 'RETIRER ★' : 'FAVORI',
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: ArclogColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: ArclogColors.error.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SUPPRIMER',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ArclogColors.error,
              letterSpacing: 1,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.delete_outline, color: ArclogColors.error, size: 22),
        ],
      ),
    );
  }
}
