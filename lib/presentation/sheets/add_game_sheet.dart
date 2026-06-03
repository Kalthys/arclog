import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/game_status.dart';
import '../state/game_providers.dart';
import '../widgets/game_badges.dart';
import '../widgets/sheet_utils.dart';

class AddGameSheet extends ConsumerStatefulWidget {
  const AddGameSheet({super.key});

  @override
  ConsumerState<AddGameSheet> createState() => _AddGameSheetState();
}

class _AddGameSheetState extends ConsumerState<AddGameSheet> {
  final _titleCtrl = TextEditingController();
  final _platformCtrl = TextEditingController();
  String? _coverPath;
  GameStatus _status = GameStatus.backlog;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _platformCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _coverPath = picked.path);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    await ref.read(gamesProvider.notifier).addGame(
          title,
          coverImagePath: _coverPath,
          status: _status,
          platform: _platformCtrl.text.trim().isEmpty
              ? null
              : _platformCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          Text('NOUVEAU JEU', style: tt.titleLarge),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _coverPath != null
                      ? Image.file(File(_coverPath!),
                          width: 72, height: 72, fit: BoxFit.cover)
                      : Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: ArclogColors.deepBlack,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ArclogColors.cyanGlow.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: ArclogColors.cyanGlow, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'COVER',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 8,
                                  color: ArclogColors.cyanGlow,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: tt.bodyLarge,
                  cursorColor: ArclogColors.cyanGlow,
                  decoration: InputDecoration(
                    hintText: 'Titre du jeu…',
                    hintStyle: tt.bodyMedium,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: ArclogColors.circuitLine),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: ArclogColors.cyanGlow, width: 1.5),
                    ),
                    filled: true,
                    fillColor: ArclogColors.deepBlack,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('STATUT', style: tt.labelSmall),
          const SizedBox(height: 8),
          StatusSelectorRow(
            selected: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: 16),
          Text('PLATEFORME (optionnelle)', style: tt.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _platformCtrl,
            style: tt.bodyLarge,
            cursorColor: ArclogColors.cyanGlow,
            decoration: InputDecoration(
              hintText: 'PC, PS5, Switch…',
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
          const SizedBox(height: 8),
          PlatformQuickChips(
            onSelected: (p) {
              _platformCtrl.text = p;
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArclogColors.cyanGlow,
                foregroundColor: ArclogColors.deepBlack,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: tt.titleMedium?.copyWith(
                  color: ArclogColors.deepBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ArclogColors.deepBlack),
                    )
                  : const Text('AJOUTER'),
            ),
          ),
        ],
      ),
    );
  }
}
