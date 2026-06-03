/// Trophée officiel du jeu (à terme alimenté par l'API Steam).
class Achievement {
  final int? id;
  final int gameId;
  final String title;
  final String? description;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  // Champs réservés à l'intégration future de l'API Steam
  final String? steamApiName;
  final String? iconUrl;

  final bool isFavorite;

  const Achievement({
    this.id,
    required this.gameId,
    required this.title,
    this.description,
    this.isUnlocked = false,
    this.unlockedAt,
    this.steamApiName,
    this.iconUrl,
    this.isFavorite = false,
  });

  Achievement copyWith({
    int? id,
    int? gameId,
    String? title,
    String? description,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? steamApiName,
    String? iconUrl,
    bool? isFavorite,
  }) =>
      Achievement(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        title: title ?? this.title,
        description: description ?? this.description,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        steamApiName: steamApiName ?? this.steamApiName,
        iconUrl: iconUrl ?? this.iconUrl,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  bool operator ==(Object other) =>
      other is Achievement && other.id == id && other.gameId == gameId;

  @override
  int get hashCode => Object.hash(id, gameId);
}
