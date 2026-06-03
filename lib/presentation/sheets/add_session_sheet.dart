import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/session.dart';
import '../state/game_detail_providers.dart';
import '../widgets/session_input_widgets.dart';
import '../widgets/sheet_utils.dart';

class AddSessionSheet extends ConsumerStatefulWidget {
  const AddSessionSheet({super.key, required this.gameId});
  final int gameId;

  @override
  ConsumerState<AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends ConsumerState<AddSessionSheet> {
  int _hours = 0;
  int _minutes = 30;
  final _notesCtrl = TextEditingController();
  String? _screenshotPath;
  final Set<String> _tags = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final p = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (p != null) setState(() => _screenshotPath = p.path);
  }

  Future<void> _submit() async {
    final total = _hours * 60 + _minutes;
    if (total <= 0) {
      setState(() => _error = 'La durée doit être supérieure à 0 minute.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await ref.read(gameDetailProvider(widget.gameId).notifier).addSession(
          durationMinutes: total,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          screenshotPath: _screenshotPath,
          tags: _tags.toList(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasSc =
        _screenshotPath != null && File(_screenshotPath!).existsSync();

    return SheetScaffold(
      title: 'NOUVELLE SESSION',
      loading: _loading,
      submitLabel: 'ENREGISTRER',
      onSubmit: _submit,
      children: [
        // ── Compteur durée ────────────────────────────────────────────────────
        SessionDurationPicker(
          hours: _hours,
          minutes: _minutes,
          onHoursChanged: (v) => setState(() => _hours = v),
          onMinutesChanged: (v) => setState(() => _minutes = v),
        ),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(
              color: ArclogColors.error, fontFamily: 'Orbitron', fontSize: 10)),
        ],

        const SizedBox(height: 20),

        // ── Tags ──────────────────────────────────────────────────────────────
        Text('TAGS', style: tt.labelSmall),
        const SizedBox(height: 8),
        SessionTagPicker(
          selected: _tags,
          onToggle: (tag) => setState(() {
            _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
          }),
        ),

        const SizedBox(height: 20),

        // ── Journal de bord ───────────────────────────────────────────────────
        SheetField(
          ctrl: _notesCtrl,
          label: 'Journal de bord (optionnel)',
          hint: 'Boss battu, zone explorée, objectif atteint, tes impressions…',
          minLines: 8,
          maxLines: 20,
        ),

        const SizedBox(height: 12),

        // ── Screenshot ────────────────────────────────────────────────────────
        GestureDetector(
          onTap: _pickScreenshot,
          child: hasSc
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_screenshotPath!),
                      height: 80, width: double.infinity, fit: BoxFit.cover))
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: ArclogColors.circuitLine),
                    borderRadius: BorderRadius.circular(8),
                    color: ArclogColors.deepBlack,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: ArclogColors.cyanGlow, size: 18),
                      SizedBox(width: 8),
                      Text('SCREENSHOT (optionnel)',
                          style: TextStyle(
                              fontFamily: 'Orbitron', fontSize: 9,
                              color: ArclogColors.cyanGlow, letterSpacing: 1)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
