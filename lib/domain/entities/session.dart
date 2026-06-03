class Session {
  final int? id;
  final int gameId;
  final DateTime startedAt;
  final int durationMinutes;
  final String? notes;
  final String? screenshotPath;
  final List<String> tags;

  const Session({
    this.id,
    required this.gameId,
    required this.startedAt,
    required this.durationMinutes,
    this.notes,
    this.screenshotPath,
    this.tags = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is Session && other.id == id && other.gameId == gameId;

  @override
  int get hashCode => Object.hash(id, gameId);
}
