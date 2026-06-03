class Objective {
  final int? id;
  final int gameId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final int? targetQuantity;
  final int currentQuantity;
  final bool isFavorite;

  const Objective({
    this.id,
    required this.gameId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.targetQuantity,
    this.currentQuantity = 0,
    this.isFavorite = false,
  });

  bool get hasQuantity => targetQuantity != null && targetQuantity! > 0;

  double get quantityProgress => hasQuantity
      ? (currentQuantity / targetQuantity!).clamp(0.0, 1.0)
      : (isCompleted ? 1.0 : 0.0);

  bool get isQuantityReached =>
      hasQuantity && currentQuantity >= targetQuantity!;

  @override
  bool operator ==(Object other) =>
      other is Objective && other.id == id && other.gameId == gameId;

  @override
  int get hashCode => Object.hash(id, gameId);
}
