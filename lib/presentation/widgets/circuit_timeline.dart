import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/objective.dart';
import '../../domain/entities/session.dart';

// ── Activity entry types ──────────────────────────────────────────────────────

sealed class ActivityEntry {
  Game get game;
  DateTime get date;
}

class SessionActivity extends ActivityEntry {
  final Session session;
  @override
  final Game game;
  SessionActivity({required this.session, required this.game});
  @override
  DateTime get date => session.startedAt;
}

class AchievementActivity extends ActivityEntry {
  final Achievement achievement;
  @override
  final Game game;
  AchievementActivity({required this.achievement, required this.game});
  @override
  DateTime get date => achievement.unlockedAt!;
}

class ObjectiveActivity extends ActivityEntry {
  final Objective objective;
  @override
  final Game game;
  ObjectiveActivity({required this.objective, required this.game});
  @override
  DateTime get date => objective.completedAt!;
}

// ── Shared format helpers ─────────────────────────────────────────────────────

String _fmtLog(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return '> $d.$mo · $h:$mi';
}

String _fmtDur(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h${m}m';
}

List<Shadow> _neonGlow(Color c) => [
      Shadow(color: c.withValues(alpha: 0.95), blurRadius: 8),
      Shadow(color: c.withValues(alpha: 0.45), blurRadius: 18),
    ];

// =============================================================================
// CircuitTimeline
// =============================================================================

class CircuitTimeline extends StatelessWidget {
  const CircuitTimeline({
    super.key,
    required this.entries,
    this.onTapEntry,
  });

  final List<ActivityEntry> entries;
  final void Function(ActivityEntry entry)? onTapEntry;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Aucune activité — lancez une partie !',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      children: List.generate(
        entries.length,
        (i) => _CircuitNode(
          entry: entries[i],
          isLast: i == entries.length - 1,
          onTap: onTapEntry != null ? () => onTapEntry!(entries[i]) : null,
        ),
      ),
    );
  }
}

// =============================================================================
// Nœud : ligne verticale + point coloré + carte
// =============================================================================

class _CircuitNode extends StatelessWidget {
  const _CircuitNode({
    required this.entry,
    required this.isLast,
    this.onTap,
  });

  final ActivityEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  Color get _color => switch (entry) {
        SessionActivity() => ArclogColors.cyanGlow,
        AchievementActivity() => ArclogColors.electricYellow,
        ObjectiveActivity() => ArclogColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Colonne gauche : ligne + point coloré ─────────────────────────
          SizedBox(
            width: 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Ligne verticale
                Positioned(
                  top: 18,
                  bottom: 0,
                  left: 9,
                  width: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.55),
                          isLast
                              ? color.withValues(alpha: 0.0)
                              : color.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                // Trait horizontal PCB
                Positioned(
                  top: 11,
                  left: 14,
                  width: 16,
                  height: 1,
                  child: ColoredBox(color: color.withValues(alpha: 0.45)),
                ),
                // Point lumineux
                Positioned(
                  top: 8,
                  left: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.9),
                          blurRadius: 5,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Carte d'activité ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 6, bottom: isLast ? 4 : 16),
              child: _ActivityCard(entry: entry, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Carte d'activité (glassmorphisme)
// =============================================================================

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entry, this.onTap});

  final ActivityEntry entry;
  final VoidCallback? onTap;

  Color get _accentColor => switch (entry) {
        SessionActivity() => ArclogColors.cyanGlow,
        AchievementActivity() => ArclogColors.electricYellow,
        ObjectiveActivity() => ArclogColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF091624),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            child: _buildContent(),
          ),

          // Coins "viseur"
          const _Corner(pos: _Pos.tl),
          const _Corner(pos: _Pos.tr),
          const _Corner(pos: _Pos.bl),
          const _Corner(pos: _Pos.br),

          // Chevron si tappable
          if (onTap != null)
            Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.chevron_right,
                size: 11,
                color: _accentColor.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() => switch (entry) {
        SessionActivity(:final session, :final game) =>
          _buildSession(session, game),
        AchievementActivity(:final achievement, :final game) =>
          _buildAchievement(achievement, game),
        ObjectiveActivity(:final objective, :final game) =>
          _buildObjective(objective, game),
      };

  // ── Session ──────────────────────────────────────────────────────────────────

  Widget _buildSession(Session session, Game game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          game.title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ArclogColors.textPrimary,
            letterSpacing: 1.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '+',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ArclogColors.electricYellow,
                    height: 1,
                    shadows: _neonGlow(ArclogColors.electricYellow),
                  ),
                ),
                TextSpan(
                  text: _fmtDur(session.durationMinutes),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ArclogColors.cyanGlow,
                    height: 1,
                    shadows: _neonGlow(ArclogColors.cyanGlow),
                  ),
                ),
              ]),
            ),
            const Spacer(),
            Text(
              _fmtLog(session.startedAt),
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                color: ArclogColors.textSecondary.withValues(alpha: 0.65),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        if (session.notes != null && session.notes!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '// ${session.notes}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              color: ArclogColors.textSecondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ── Achievement ───────────────────────────────────────────────────────────────

  Widget _buildAchievement(Achievement achievement, Game game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'TROPHÉE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: ArclogColors.electricYellow.withValues(alpha: 0.85),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                game.title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  color: ArclogColors.textSecondary.withValues(alpha: 0.65),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 16,
              color: ArclogColors.electricYellow,
              shadows: _neonGlow(ArclogColors.electricYellow),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                achievement.title,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ArclogColors.electricYellow,
                  shadows: _neonGlow(ArclogColors.electricYellow),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _fmtLog(achievement.unlockedAt!),
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                color: ArclogColors.textSecondary.withValues(alpha: 0.65),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        if (achievement.description != null &&
            achievement.description!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '// ${achievement.description}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              color: ArclogColors.textSecondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ── Objective ─────────────────────────────────────────────────────────────────

  Widget _buildObjective(Objective objective, Game game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'QUÊTE COMPLÉTÉE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: ArclogColors.success.withValues(alpha: 0.85),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                game.title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  color: ArclogColors.textSecondary.withValues(alpha: 0.65),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: ArclogColors.success,
              shadows: _neonGlow(ArclogColors.success),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                objective.title,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ArclogColors.success,
                  shadows: _neonGlow(ArclogColors.success),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _fmtLog(objective.completedAt!),
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                color: ArclogColors.textSecondary.withValues(alpha: 0.65),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        if (objective.description != null &&
            objective.description!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '// ${objective.description}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              color: ArclogColors.textSecondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Coins "viseur" (7×7, 1px bordure)
// =============================================================================

enum _Pos { tl, tr, bl, br }

class _Corner extends StatelessWidget {
  const _Corner({required this.pos});

  final _Pos pos;

  @override
  Widget build(BuildContext context) {
    const s = 7.0;
    const t = 1.0;
    final c = ArclogColors.cyanGlow.withValues(alpha: 0.6);

    final border = switch (pos) {
      _Pos.tl => Border(
          top: BorderSide(color: c, width: t),
          left: BorderSide(color: c, width: t),
        ),
      _Pos.tr => Border(
          top: BorderSide(color: c, width: t),
          right: BorderSide(color: c, width: t),
        ),
      _Pos.bl => Border(
          bottom: BorderSide(color: c, width: t),
          left: BorderSide(color: c, width: t),
        ),
      _Pos.br => Border(
          bottom: BorderSide(color: c, width: t),
          right: BorderSide(color: c, width: t),
        ),
    };

    final alignment = switch (pos) {
      _Pos.tl => Alignment.topLeft,
      _Pos.tr => Alignment.topRight,
      _Pos.bl => Alignment.bottomLeft,
      _Pos.br => Alignment.bottomRight,
    };

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: s,
          height: s,
          child: DecoratedBox(decoration: BoxDecoration(border: border)),
        ),
      ),
    );
  }
}
