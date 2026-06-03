import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../data/services/steam_service.dart';
import 'game_providers.dart';
import 'player_providers.dart';
export 'player_providers.dart' show steamAvatarProvider;

/// URL du proxy Vercel — hardcodée pour ne pas exposer le champ dans l'UI.
const _kVercelUrl = 'https://arclog-backend-delta.vercel.app';

final steamServiceProvider = Provider<SteamService>(
  (_) => SteamService(vercelBaseUrl: _kVercelUrl),
);

// ── État ──────────────────────────────────────────────────────────────────────

enum SteamSyncStatus { idle, loadingGames, syncing, success, error }

class SteamSyncState {
  const SteamSyncState({
    this.status = SteamSyncStatus.idle,
    this.availableGames = const [],
    this.result,
    this.errorMessage,
  });

  final SteamSyncStatus status;

  /// Jeux Steam récupérés (avec playtime > 0), triés par temps de jeu desc.
  /// Non vide seulement entre fetchGames() et importSelected().
  final List<SteamGame> availableGames;

  final SteamSyncResult? result;
  final String? errorMessage;

  bool get isLoadingGames => status == SteamSyncStatus.loadingGames;
  bool get isSyncing      => status == SteamSyncStatus.syncing;
  bool get isLoading      => isLoadingGames || isSyncing;
  bool get hasGames       => availableGames.isNotEmpty;

  SteamSyncState copyWith({
    SteamSyncStatus? status,
    List<SteamGame>? availableGames,
    SteamSyncResult? result,
    String? errorMessage,
  }) =>
      SteamSyncState(
        status:         status         ?? this.status,
        availableGames: availableGames ?? this.availableGames,
        result:         result         ?? this.result,
        errorMessage:   errorMessage   ?? this.errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SteamSyncNotifier extends Notifier<SteamSyncState> {
  @override
  SteamSyncState build() => const SteamSyncState();

  // ── Étape 1 : récupérer la liste des jeux Steam ───────────────────────────

  Future<void> fetchGames() async {
    // Attendre le chargement des prefs (évite l'erreur au premier appui)
    const url = _kVercelUrl;
    final steamId = await ref.read(steamIdProvider.future);


    if (steamId.isEmpty) {
      state = state.copyWith(
        status: SteamSyncStatus.error,
        errorMessage: 'Steam ID non configuré.',
      );
      return;
    }

    final steamService = SteamService(vercelBaseUrl: _kVercelUrl);

    state = state.copyWith(status: SteamSyncStatus.loadingGames);

    try {
      final response = await steamService.fetchOwnedGames(steamId);
      final all = response.games;

      // Sauvegarder le profil Steam (pseudo + avatar) si disponible
      if (response.player != null) {
        await ref
            .read(playerNameProvider.notifier)
            .setName(response.player!.name);
        if (response.player!.avatarUrl != null) {
          await ref
              .read(steamAvatarProvider.notifier)
              .setUrl(response.player!.avatarUrl!);
        }
      }

      if (all.isEmpty) {
        state = state.copyWith(
          status: SteamSyncStatus.error,
          errorMessage:
              'Aucun jeu trouvé. Vérifie que ton profil Steam est public.',
        );
        return;
      }

      // Garder uniquement les jeux joués, triés par temps de jeu desc
      final played = all.where((g) => g.playtimeMinutes > 0).toList()
        ..sort((a, b) => b.playtimeMinutes.compareTo(a.playtimeMinutes));

      state = state.copyWith(
        status: SteamSyncStatus.idle,
        availableGames: played,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SteamSyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Étape 2 : importer les jeux sélectionnés ──────────────────────────────

  Future<void> importSelected(List<int> selectedAppIds) async {
    if (selectedAppIds.isEmpty) return;

    const url = _kVercelUrl;
    final steamId = await ref.read(steamIdProvider.future);
    if (steamId.isEmpty) return;
    final steamService = SteamService(vercelBaseUrl: _kVercelUrl);

    final selectedGames = state.availableGames
        .where((g) => selectedAppIds.contains(g.appId))
        .toList();

    state = state.copyWith(status: SteamSyncStatus.syncing);

    try {
      final repo = ref.read(gameRepositoryProvider) as GameRepositoryImpl;
      final result = await repo.importSelectedGames(
        steamService: steamService,
        steamId: steamId,
        selectedGames: selectedGames,
      );

      ref.invalidate(gamesProvider);

      state = state.copyWith(
        status: result.hasErrors
            ? SteamSyncStatus.error
            : SteamSyncStatus.success,
        result: result,
        availableGames: const [],
        errorMessage: result.hasErrors ? result.errors.join('\n') : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SteamSyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Synchronisation rapide (jeux déjà liés) ──────────────────────────────

  Future<void> syncAll() async {
    const url = _kVercelUrl;
    final steamId = await ref.read(steamIdProvider.future);


    if (steamId.isEmpty) {
      state = state.copyWith(
        status: SteamSyncStatus.error,
        errorMessage: 'Steam ID non configuré.',
      );
      return;
    }

    final steamService = SteamService(vercelBaseUrl: _kVercelUrl);

    state = state.copyWith(status: SteamSyncStatus.syncing);

    try {
      final repo = ref.read(gameRepositoryProvider) as GameRepositoryImpl;

      // Récupérer le profil en même temps que le refresh
      final response = await steamService.fetchOwnedGames(steamId);
      if (response.player != null) {
        await ref.read(playerNameProvider.notifier).setName(response.player!.name);
        if (response.player!.avatarUrl != null) {
          await ref.read(steamAvatarProvider.notifier).setUrl(response.player!.avatarUrl!);
        }
      }

      final result = await repo.refreshAllLinked(
        steamService: steamService,
        steamId: steamId,
      );
      ref.invalidate(gamesProvider);
      state = state.copyWith(
        status: result.hasErrors
            ? SteamSyncStatus.error
            : SteamSyncStatus.success,
        result: result,
        errorMessage: result.hasErrors ? result.errors.join('\n') : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SteamSyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const SteamSyncState();
  void clearGames() =>
      state = state.copyWith(availableGames: const []);
}

final steamSyncProvider =
    NotifierProvider<SteamSyncNotifier, SteamSyncState>(SteamSyncNotifier.new);
