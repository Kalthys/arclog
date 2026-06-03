import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/game_detail_providers.dart';
import '../widgets/sheet_utils.dart';

class AddObjectiveSheet extends ConsumerStatefulWidget {
  const AddObjectiveSheet({super.key, required this.gameId});
  final int gameId;

  @override
  ConsumerState<AddObjectiveSheet> createState() => _AddObjectiveSheetState();
}

class _AddObjectiveSheetState extends ConsumerState<AddObjectiveSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await ref
        .read(gameDetailProvider(widget.gameId).notifier)
        .addObjective(
          _titleCtrl.text,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text,
          targetQuantity: int.tryParse(_qtyCtrl.text.trim()),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'NOUVEL OBJECTIF',
      loading: _loading,
      submitLabel: 'CRÉER',
      onSubmit: _submit,
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
      ],
    );
  }
}
