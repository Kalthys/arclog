import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/arclog_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/game.dart';
import 'game_badges.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ArclogColors.circuitLine,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class SheetField extends StatelessWidget {
  const SheetField({
    super.key,
    required this.ctrl,
    required this.hint,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
  });

  final TextEditingController ctrl;
  final String hint;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelSmall),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          autofocus: autofocus,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          style: tt.bodyLarge,
          cursorColor: ArclogColors.cyanGlow,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ArclogColors.circuitLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: ArclogColors.cyanGlow, width: 1.5),
            ),
            filled: true,
            fillColor: ArclogColors.deepBlack,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class SheetSubmitBtn extends StatelessWidget {
  const SheetSubmitBtn({
    super.key,
    required this.loading,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool loading;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null ? ArclogColors.circuitLine : color,
          foregroundColor: ArclogColors.deepBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ArclogColors.deepBlack),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}

class GamePicker extends StatelessWidget {
  const GamePicker({
    super.key,
    required this.games,
    required this.selected,
    required this.onSelect,
  });

  final List<Game> games;
  final Game? selected;
  final ValueChanged<Game> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: games.map((g) {
          final isSelected = selected?.id == g.id;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? ArclogColors.cyanGlow.withValues(alpha: 0.15)
                    : ArclogColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? ArclogColors.cyanGlow
                      : ArclogColors.circuitLine,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: ArclogColors.cyanGlow.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (g.coverImagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(g.coverImagePath!),
                        width: 24, height: 24, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.videogame_asset_outlined,
                          size: 16,
                          color: isSelected
                              ? ArclogColors.cyanGlow
                              : ArclogColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.videogame_asset_outlined,
                      size: 16,
                      color: isSelected
                          ? ArclogColors.cyanGlow
                          : ArclogColors.textSecondary,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    g.title,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? ArclogColors.cyanGlow
                          : ArclogColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.loading,
    required this.submitLabel,
    required this.onSubmit,
    this.submitColor = ArclogColors.cyanGlow,
  });

  final String title;
  final List<Widget> children;
  final bool loading;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Color submitColor;

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
          Text(title, style: tt.titleLarge),
          const SizedBox(height: 20),
          ...children,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: submitColor,
                foregroundColor: ArclogColors.deepBlack,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ArclogColors.deepBlack),
                    )
                  : Text(submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carousel picker de jeux (avec jaquettes) ──────────────────────────────────

class GameCarouselPicker extends StatelessWidget {
  const GameCarouselPicker({
    super.key,
    required this.games,
    required this.selected,
    required this.onSelect,
  });

  final List<Game> games;
  final Game? selected;
  final ValueChanged<Game> onSelect;

  Widget _cover(Game g) {
    // 1. Cover locale
    if (g.coverImagePath != null) {
      return Image.file(
        File(g.coverImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _steamCover(g),
      );
    }
    return _steamCover(g);
  }

  Widget _steamCover(Game g) {
    // 2. Image Steam portrait
    if (g.steamAppId != null) {
      return Image.network(
        'https://cdn.cloudflare.steamstatic.com/steam/apps/${g.steamAppId}/library_600x900.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => g.steamCoverUrl != null
            ? Image.network(g.steamCoverUrl!, fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => _placeholder(g))
            : _placeholder(g),
      );
    }
    if (g.steamCoverUrl != null) {
      return Image.network(g.steamCoverUrl!, fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => _placeholder(g));
    }
    return _placeholder(g);
  }

  Widget _placeholder(Game g) => Container(
        color: ArclogColors.surfaceDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videogame_asset_outlined,
                color: ArclogColors.cyanGlow, size: 32),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                g.title.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Orbitron', fontSize: 8,
                  color: ArclogColors.cyanGlow.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        padding: const EdgeInsets.only(right: 4),
        itemBuilder: (_, i) {
          final g = games[i];
          final isSelected = selected?.id == g.id;

          return GestureDetector(
            onTap: () => onSelect(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 118,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? ArclogColors.cyanGlow
                      : ArclogColors.circuitLine,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: ArclogColors.cyanGlow.withValues(alpha: 0.35),
                        blurRadius: 14, spreadRadius: 1)]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Jaquette ────────────────────────────────────────────
                    _cover(g),

                    // ── Dégradé bas ──────────────────────────────────────────
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.3, 1],
                            colors: [
                              ArclogColors.deepBlack.withValues(alpha: 0),
                              ArclogColors.deepBlack.withValues(alpha: 0.6),
                              ArclogColors.deepBlack.withValues(alpha: 0.96),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              g.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Orbitron', fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ArclogColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 9,
                                    color: ArclogColors.electricYellow),
                                const SizedBox(width: 2),
                                Text(
                                  ArclogFormatters.playTime(
                                      g.totalPlayTimeMinutes),
                                  style: const TextStyle(
                                    fontFamily: 'Orbitron', fontSize: 8,
                                    color: ArclogColors.electricYellow,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            GameStatusBadge(status: g.status, compact: true),
                          ],
                        ),
                      ),
                    ),

                    // ── Coche de sélection ────────────────────────────────────
                    if (isSelected)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ArclogColors.cyanGlow,
                          ),
                          child: const Icon(Icons.check,
                              size: 14, color: ArclogColors.deepBlack),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
