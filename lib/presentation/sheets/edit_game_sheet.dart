import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/arclog_colors.dart';
import '../../domain/entities/game_status.dart';
import '../state/game_detail_providers.dart';
import '../widgets/game_badges.dart';
import '../widgets/sheet_utils.dart';

class EditGameSheet extends ConsumerStatefulWidget {
  const EditGameSheet({
    super.key,
    required this.gameId,
    required this.currentTitle,
    this.currentCoverPath,
    required this.currentStatus,
    this.currentPlatform,
    this.currentSteamAppId,
  });

  final int gameId;
  final String currentTitle;
  final String? currentCoverPath;
  final GameStatus currentStatus;
  final String? currentPlatform;
  final int? currentSteamAppId;

  @override
  ConsumerState<EditGameSheet> createState() => _EditGameSheetState();
}

class _EditGameSheetState extends ConsumerState<EditGameSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _platformCtrl;
  late final TextEditingController _steamAppIdCtrl;
  String? _newCoverPath;
  late GameStatus _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.currentTitle);
    _platformCtrl = TextEditingController(text: widget.currentPlatform ?? '');
    _steamAppIdCtrl = TextEditingController(
      text: widget.currentSteamAppId?.toString() ?? '',
    );
    _status = widget.currentStatus;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _platformCtrl.dispose();
    _steamAppIdCtrl.dispose();
    super.dispose();
  }

  String? get _displayedCover => _newCoverPath ?? widget.currentCoverPath;
  bool get _hasCover =>
      _displayedCover != null && File(_displayedCover!).existsSync();

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newCoverPath = picked.path);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final rawSteamId = _steamAppIdCtrl.text.trim();
    final steamAppId = rawSteamId.isEmpty ? null : int.tryParse(rawSteamId);

    await ref.read(gameDetailProvider(widget.gameId).notifier).updateGameInfo(
          title: _titleCtrl.text,
          newCoverPath: _newCoverPath,
          status: _status,
          platform: _platformCtrl.text,
          steamAppId: steamAppId,
          clearSteamAppId: rawSteamId.isEmpty,
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
          Text('MODIFIER LE JEU', style: tt.titleLarge),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _hasCover
                          ? Image.file(File(_displayedCover!),
                              width: 72, height: 72, fit: BoxFit.cover)
                          : Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: ArclogColors.deepBlack,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ArclogColors.cyanGlow
                                      .withValues(alpha: 0.5),
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
                    if (_hasCover)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color:
                                ArclogColors.deepBlack.withValues(alpha: 0.4),
                            child: const Icon(Icons.edit,
                                color: ArclogColors.cyanGlow, size: 22),
                          ),
                        ),
                      ),
                  ],
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
                    labelText: 'Nom du jeu',
                    labelStyle:
                        const TextStyle(color: ArclogColors.textSecondary),
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
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('STATUT',
              style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: ArclogColors.electricYellow,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          StatusSelectorRow(
            selected: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: 16),
          const Text('PLATEFORME (optionnelle)',
              style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: ArclogColors.electricYellow,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          TextField(
            controller: _platformCtrl,
            style: const TextStyle(
                fontFamily: 'Orbitron', color: ArclogColors.textPrimary),
            cursorColor: ArclogColors.cyanGlow,
            decoration: InputDecoration(
              hintText: 'PC, PS5, Switch…',
              hintStyle: const TextStyle(color: ArclogColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: ArclogColors.circuitLine)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: ArclogColors.cyanGlow, width: 1.5)),
              filled: true,
              fillColor: ArclogColors.deepBlack,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          PlatformQuickChips(
              onSelected: (p) => setState(() => _platformCtrl.text = p)),
          const SizedBox(height: 16),
          // ── Steam App ID ────────────────────────────────────────────────────
          Row(
            children: [
              const Text('STEAM APP ID (optionnel)',
                  style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: ArclogColors.electricYellow,
                      letterSpacing: 2)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showSteamIdHelp(context),
                child: const Icon(Icons.help_outline,
                    size: 14, color: ArclogColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _steamAppIdCtrl,
            style: const TextStyle(
                fontFamily: 'Orbitron', color: ArclogColors.textPrimary),
            keyboardType: TextInputType.number,
            cursorColor: ArclogColors.cyanGlow,
            decoration: InputDecoration(
              hintText: 'ex : 570 (Dota 2)',
              hintStyle: const TextStyle(color: ArclogColors.textSecondary),
              prefixIcon: const Icon(Icons.sports_esports,
                  color: ArclogColors.cyanGlow, size: 18),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: ArclogColors.cyanGlow, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: ArclogColors.cyanGlow, width: 1.5)),
              filled: true,
              fillColor: ArclogColors.deepBlack,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArclogColors.cyanGlow,
                foregroundColor: ArclogColors.deepBlack,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ArclogColors.deepBlack))
                  : const Text('ENREGISTRER'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSteamIdHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArclogColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArclogColors.circuitLine),
        ),
        title: const Text('Trouver le Steam App ID',
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                color: ArclogColors.cyanGlow)),
        content: const Text(
          'Recherche le jeu sur store.steampowered.com.\n\n'
          'L\'App ID est le numéro dans l\'URL :\n'
          'store.steampowered.com/app/[APP_ID]/…',
          style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: ArclogColors.textSecondary,
              height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: ArclogColors.cyanGlow)),
          ),
        ],
      ),
    );
  }
}
