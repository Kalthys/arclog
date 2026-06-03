import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/objective.dart';
import '../state/game_detail_providers.dart';
import '../widgets/sheet_utils.dart';

class EditObjectiveSheet extends ConsumerStatefulWidget {
  const EditObjectiveSheet(
      {super.key, required this.gameId, required this.objective});
  final int gameId;
  final Objective objective;

  @override
  ConsumerState<EditObjectiveSheet> createState() =>
      _EditObjectiveSheetState();
}

class _EditObjectiveSheetState extends ConsumerState<EditObjectiveSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final o = widget.objective;
    _titleCtrl = TextEditingController(text: o.title);
    _descCtrl = TextEditingController(text: o.description ?? '');
    _qtyCtrl = TextEditingController(
        text: o.targetQuantity != null ? '${o.targetQuantity}' : '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await ref
        .read(gameDetailProvider(widget.gameId).notifier)
        .updateObjectiveInfo(
          widget.objective,
          title: _titleCtrl.text,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text,
          targetQuantity: int.tryParse(_qtyCtrl.text.trim()),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: const Text('Supprimer l\'objectif ?',
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                color: ArclogColors.textPrimary)),
        content: Text(
          '"${widget.objective.title}" sera définitivement effacé.',
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
                style: TextStyle(color: ArclogColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(gameDetailProvider(widget.gameId).notifier)
          .deleteObjective(widget.objective.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'MODIFIER L\'OBJECTIF',
      loading: _loading,
      submitLabel: 'ENREGISTRER',
      onSubmit: _save,
      children: [
        SheetField(
          ctrl: _titleCtrl,
          label: 'Titre',
          hint: 'Ramasser des pommes…',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        SheetField(
          ctrl: _descCtrl,
          label: 'Description (optionnelle)',
          hint: 'Conditions, détails…',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        SheetField(
          ctrl: _qtyCtrl,
          label: 'Quantité cible (optionnelle)',
          hint: 'ex : 10  →  affichera 0 / 10',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        // ── Bouton supprimer ────────────────────────────────────────────
        GestureDetector(
          onTap: _loading ? null : _delete,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: ArclogColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: ArclogColors.error.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline,
                    size: 14, color: ArclogColors.error),
                SizedBox(width: 8),
                Text(
                  'SUPPRIMER CET OBJECTIF',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
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
    );
  }
}
