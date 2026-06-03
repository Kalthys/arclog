import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/session.dart';
import '../state/game_detail_providers.dart';
import '../widgets/session_input_widgets.dart';
import '../widgets/sheet_utils.dart';

class EditSessionSheet extends ConsumerStatefulWidget {
  const EditSessionSheet(
      {super.key, required this.gameId, required this.session});
  final int gameId;
  final Session session;

  @override
  ConsumerState<EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<EditSessionSheet> {
  late int _hours;
  late int _minutes;
  late final TextEditingController _notesCtrl;
  late DateTime _startedAt;
  String? _screenshotPath;
  late final Set<String> _tags;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _startedAt = s.startedAt;
    _hours = s.durationMinutes ~/ 60;
    _minutes = s.durationMinutes % 60;
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _screenshotPath = s.screenshotPath;
    _tags = Set<String>.from(s.tags);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ArclogColors.cyanGlow,
            surface: ArclogColors.surfaceDark,
          ),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ArclogColors.cyanGlow,
            surface: ArclogColors.surfaceDark,
          ),
        ),
        child: child!,
      ),
    );
    setState(() => _startedAt = DateTime(
          d.year, d.month, d.day,
          t?.hour ?? _startedAt.hour,
          t?.minute ?? _startedAt.minute,
        ));
  }

  Future<void> _pickScreenshot() async {
    final p = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (p != null) setState(() => _screenshotPath = p.path);
  }

  Future<void> _submit() async {
    final total = _hours * 60 + _minutes;
    if (total <= 0) {
      setState(() => _error = 'La durée doit être supérieure à 0.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await ref.read(gameDetailProvider(widget.gameId).notifier).updateSession(
          original: widget.session,
          startedAt: _startedAt,
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
    final dateStr =
        '${_startedAt.day.toString().padLeft(2, '0')}/'
        '${_startedAt.month.toString().padLeft(2, '0')}/'
        '${_startedAt.year}  '
        '${_startedAt.hour.toString().padLeft(2, '0')}:'
        '${_startedAt.minute.toString().padLeft(2, '0')}';

    return SheetScaffold(
      title: 'MODIFIER LA SESSION',
      loading: _loading,
      submitLabel: 'ENREGISTRER',
      onSubmit: _submit,
      children: [
        // ── Date / heure ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: ArclogColors.deepBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ArclogColors.circuitLine),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: ArclogColors.cyanGlow),
                const SizedBox(width: 8),
                Text(dateStr, style: tt.bodyLarge),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 16, color: ArclogColors.textSecondary),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

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
              ? Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_screenshotPath!),
                        height: 80, width: double.infinity, fit: BoxFit.cover)),
                  Positioned(top: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ArclogColors.deepBlack.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4)),
                      child: const Text('CHANGER', style: TextStyle(
                          fontFamily: 'Orbitron', fontSize: 8,
                          color: ArclogColors.cyanGlow)))),
                ])
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
                      Text('AJOUTER UN SCREENSHOT',
                          style: TextStyle(fontFamily: 'Orbitron', fontSize: 9,
                              color: ArclogColors.cyanGlow, letterSpacing: 1)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
