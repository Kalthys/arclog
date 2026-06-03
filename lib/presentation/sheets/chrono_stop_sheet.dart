import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/arclog_colors.dart';
import '../state/active_session_provider.dart';
import '../widgets/session_input_widgets.dart';
import '../widgets/sheet_utils.dart';

class ChronoStopSheet extends ConsumerStatefulWidget {
  const ChronoStopSheet({super.key});

  @override
  ConsumerState<ChronoStopSheet> createState() => _ChronoStopSheetState();
}

class _ChronoStopSheetState extends ConsumerState<ChronoStopSheet> {
  final _notesCtrl = TextEditingController();
  String? _screenshotPath;
  final Set<String> _tags = {};
  bool _loading = false;

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

  Future<void> _save() async {
    setState(() => _loading = true);
    await ref.read(activeSessionProvider.notifier).stop(
          notes:
              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          screenshotPath: _screenshotPath,
          tags: _tags.toList(),
        );
    if (mounted) Navigator.pop(context);
  }

  void _discard() {
    ref.read(activeSessionProvider.notifier).cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(activeSessionProvider);
    final elapsed = session.elapsed;
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final durStr = h > 0 ? '+${h}h${m}m' : '+${m}m';
    final hasSc =
        _screenshotPath != null && File(_screenshotPath!).existsSync();
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SESSION TERMINÉE', style: tt.labelSmall),
                  Text(
                    durStr,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: ArclogColors.success,
                      shadows: [
                        Shadow(
                          color: ArclogColors.success.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Text(session.gameTitle ?? '', style: tt.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('TAGS', style: tt.labelSmall),
          const SizedBox(height: 8),
          SessionTagPicker(
            selected: _tags,
            onToggle: (tag) => setState(() {
              _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
            }),
          ),
          const SizedBox(height: 16),
          Text('CE QUE TU AS FAIT (optionnel)', style: tt.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            minLines: 8,
            maxLines: 20,
            autofocus: true,
            style: tt.bodyLarge,
            cursorColor: ArclogColors.cyanGlow,
            decoration: InputDecoration(
              hintText: 'Boss battu, zone explorée, objectif atteint, tes impressions…',
              hintStyle: tt.bodyMedium,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: ArclogColors.circuitLine),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: ArclogColors.cyanGlow, width: 1.5),
              ),
              filled: true,
              fillColor: ArclogColors.deepBlack,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickScreenshot,
            child: hasSc
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_screenshotPath!),
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                        Text(
                          'AJOUTER UN SCREENSHOT',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9,
                            color: ArclogColors.cyanGlow,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _discard,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: ArclogColors.circuitLine),
                    foregroundColor: ArclogColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ANNULER',
                      style:
                          TextStyle(fontFamily: 'Orbitron', fontSize: 10)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArclogColors.success,
                    foregroundColor: ArclogColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ArclogColors.deepBlack),
                        )
                      : const Text(
                          'SAUVEGARDER',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
