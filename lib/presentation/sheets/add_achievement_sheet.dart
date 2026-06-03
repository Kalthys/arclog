import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/arclog_colors.dart';
import '../state/game_detail_providers.dart';
import '../widgets/sheet_utils.dart';

class AddAchievementSheet extends ConsumerStatefulWidget {
  const AddAchievementSheet({super.key, required this.gameId});
  final int gameId;

  @override
  ConsumerState<AddAchievementSheet> createState() =>
      _AddAchievementSheetState();
}

class _AddAchievementSheetState extends ConsumerState<AddAchievementSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await ref
        .read(gameDetailProvider(widget.gameId).notifier)
        .addAchievement(
          _titleCtrl.text,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'NOUVEAU TROPHÉE',
      loading: _loading,
      submitLabel: 'AJOUTER',
      submitColor: ArclogColors.electricYellow,
      onSubmit: _submit,
      children: [
        SheetField(
          ctrl: _titleCtrl,
          label: 'Nom du trophée',
          hint: 'Platine, 100 kills…',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        SheetField(
          ctrl: _descCtrl,
          label: 'Description (optionnelle)',
          hint: 'Conditions…',
          maxLines: 2,
        ),
      ],
    );
  }
}
