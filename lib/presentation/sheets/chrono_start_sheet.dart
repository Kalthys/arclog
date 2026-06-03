import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/game.dart';
import '../state/active_session_provider.dart';
import '../state/game_providers.dart';
import '../widgets/sheet_utils.dart';

class ChronoStartSheet extends ConsumerStatefulWidget {
  const ChronoStartSheet({super.key});

  @override
  ConsumerState<ChronoStartSheet> createState() => _ChronoStartSheetState();
}

class _ChronoStartSheetState extends ConsumerState<ChronoStartSheet> {
  Game? _selected;

  void _start() {
    if (_selected == null) return;
    ref
        .read(activeSessionProvider.notifier)
        .start(_selected!.id!, _selected!.title);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final gamesAsync = ref.watch(gamesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text('CHRONOMÈTRE', style: tt.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Lance un timer en direct. Appuie sur ■ STOP sur le dashboard pour sauvegarder.',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 9,
              color: ArclogColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text('CHOISIR UN JEU', style: tt.labelSmall),
          const SizedBox(height: 8),
          gamesAsync.when(
            loading: () => const Center(
                child:
                    CircularProgressIndicator(color: ArclogColors.cyanGlow)),
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
          SheetSubmitBtn(
            loading: false,
            label: '▶  DÉMARRER',
            color: ArclogColors.success,
            onTap: _selected != null ? _start : null,
          ),
        ],
      ),
    );
  }
}
