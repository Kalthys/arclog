import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/session.dart';
import '../state/game_detail_providers.dart';
import '../state/game_providers.dart';
import '../widgets/session_input_widgets.dart';
import '../widgets/sheet_utils.dart';

class QuickAddSessionSheet extends ConsumerStatefulWidget {
  const QuickAddSessionSheet({super.key});

  @override
  ConsumerState<QuickAddSessionSheet> createState() =>
      _QuickAddSessionSheetState();
}

class _QuickAddSessionSheetState
    extends ConsumerState<QuickAddSessionSheet> {
  Game? _selected;
  int _hours = 0;
  int _minutes = 30;
  final _notesCtrl = TextEditingController();
  final Set<String> _tags = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _error = 'Sélectionne un jeu.');
      return;
    }
    final total = _hours * 60 + _minutes;
    if (total <= 0) {
      setState(() => _error = 'La durée doit être supérieure à 0.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    await ref.read(gameDetailProvider(_selected!.id!).notifier).addSession(
          durationMinutes: total,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          tags: _tags.toList(),
        );
    ref.invalidate(gamesProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final gamesAsync = ref.watch(gamesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text('SESSION RAPIDE', style: tt.titleLarge),
          const SizedBox(height: 16),

          // ── Sélecteur de jeu ───────────────────────────────────────────────
          Text('CHOISIR UN JEU', style: tt.labelSmall),
          const SizedBox(height: 8),
          gamesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: ArclogColors.cyanGlow)),
            error: (e, _) => Text('Erreur : $e'),
            data: (games) => games.isEmpty
                ? Text('Aucun jeu — crée-en un d\'abord.',
                    style: tt.bodyMedium)
                : GameCarouselPicker(
                    games: games,
                    selected: _selected,
                    onSelect: (g) => setState(() => _selected = g),
                  ),
          ),
          const SizedBox(height: 20),

          // ── Compteur durée ─────────────────────────────────────────────────
          SessionDurationPicker(
            hours: _hours,
            minutes: _minutes,
            onHoursChanged: (v) => setState(() => _hours = v),
            onMinutesChanged: (v) => setState(() => _minutes = v),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(
                color: ArclogColors.error,
                fontFamily: 'Orbitron', fontSize: 10)),
          ],

          const SizedBox(height: 20),

          // ── Tags ───────────────────────────────────────────────────────────
          Text('TAGS', style: tt.labelSmall),
          const SizedBox(height: 8),
          SessionTagPicker(
            selected: _tags,
            onToggle: (tag) => setState(() {
              _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
            }),
          ),

          const SizedBox(height: 20),

          // ── Journal de bord ────────────────────────────────────────────────
          SheetField(
            ctrl: _notesCtrl,
            label: 'Journal de bord (optionnel)',
            hint: 'Boss battu, zone explorée, objectif atteint, tes impressions…',
            minLines: 5,
            maxLines: 15,
          ),

          const SizedBox(height: 18),
          SheetSubmitBtn(
            loading: _loading,
            label: 'ENREGISTRER',
            color: ArclogColors.electricYellow,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}
