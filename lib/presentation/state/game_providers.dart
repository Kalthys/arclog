import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_status.dart';
import '../../domain/repositories/game_repository.dart';
import '../../data/repositories/game_repository_impl.dart';

final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepositoryImpl(),
);

class GamesNotifier extends AsyncNotifier<List<Game>> {
  @override
  Future<List<Game>> build() =>
      ref.read(gameRepositoryProvider).getAllGames();

  Future<void> addGame(
    String title, {
    String? coverImagePath,
    GameStatus status = GameStatus.backlog,
    String? platform,
  }) async {
    final now = DateTime.now();
    await ref.read(gameRepositoryProvider).insertGame(
          Game(
            title: title,
            coverImagePath: coverImagePath,
            createdAt: now,
            updatedAt: now,
            status: status,
            platform: platform?.trim().isEmpty == true ? null : platform?.trim(),
          ),
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeGame(int id) async {
    await ref.read(gameRepositoryProvider).deleteGame(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeGames(List<int> ids) async {
    final repo = ref.read(gameRepositoryProvider);
    await Future.wait(ids.map(repo.deleteGame));
    ref.invalidateSelf();
    await future;
  }
}

final gamesProvider =
    AsyncNotifierProvider<GamesNotifier, List<Game>>(GamesNotifier.new);
