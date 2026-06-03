import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session.dart';
import 'game_detail_providers.dart';
import 'game_providers.dart';

// =============================================================================
// État
// =============================================================================

class ActiveSessionState {
  final int? gameId;
  final String? gameTitle;
  final DateTime? startedAt;

  const ActiveSessionState({this.gameId, this.gameTitle, this.startedAt});

  static const empty = ActiveSessionState();

  bool get isRunning => gameId != null && startedAt != null;

  Duration get elapsed =>
      isRunning ? DateTime.now().difference(startedAt!) : Duration.zero;
}

// =============================================================================
// Notifier
// =============================================================================

class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  @override
  ActiveSessionState build() => ActiveSessionState.empty;

  /// Démarre le chronomètre pour un jeu donné.
  void start(int gameId, String gameTitle) {
    state = ActiveSessionState(
      gameId: gameId,
      gameTitle: gameTitle,
      startedAt: DateTime.now(),
    );
  }

  /// Arrête et enregistre la session. Retourne la durée en minutes (0 si < 1 min).
  Future<int> stop({
    String? notes,
    String? screenshotPath,
    List<String> tags = const [],
  }) async {
    if (!state.isRunning) return 0;
    final savedGameId = state.gameId!;
    final minutes = state.elapsed.inSeconds >= 30
        ? state.elapsed.inMinutes.clamp(1, 9999)
        : 0;
    if (minutes > 0) {
      await ref.read(gameRepositoryProvider).insertSession(
            Session(
              gameId: savedGameId,
              startedAt: state.startedAt!,
              durationMinutes: minutes,
              notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
              screenshotPath: screenshotPath,
              tags: tags,
            ),
          );
      ref.invalidate(gamesProvider);
      ref.invalidate(gameDetailProvider(savedGameId));
    }
    state = ActiveSessionState.empty;
    return minutes;
  }

  /// Annule le chronomètre sans sauvegarder.
  void cancel() => state = ActiveSessionState.empty;
}

// =============================================================================
// Provider
// =============================================================================

final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
  ActiveSessionNotifier.new,
);
