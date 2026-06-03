enum GameStatus {
  backlog('backlog', 'BACKLOG', 'À faire'),
  playing('playing', 'PLAYING', 'En cours'),
  completed('completed', 'COMPLETED', 'Terminé'),
  mastered('mastered', 'MASTERED', 'Platiné'),
  dropped('dropped', 'DROPPED', 'Abandonné');

  const GameStatus(this.dbKey, this.tag, this.label);

  /// Clé stockée en base de données.
  final String dbKey;

  /// Tag court affiché dans les badges.
  final String tag;

  /// Libellé complet pour les sélecteurs.
  final String label;

  static GameStatus fromDbKey(String? key) => values.firstWhere(
        (s) => s.dbKey == key,
        orElse: () => GameStatus.backlog,
      );
}
