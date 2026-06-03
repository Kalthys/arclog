import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Modèles de réponse ────────────────────────────────────────────────────────

class SteamGame {
  const SteamGame({
    required this.appId,
    required this.name,
    required this.playtimeMinutes,
    this.iconUrl,
  });

  final int appId;
  final String name;
  final int playtimeMinutes;
  final String? iconUrl;

  factory SteamGame.fromJson(Map<String, dynamic> j) => SteamGame(
        appId:           j['appId'] as int,
        name:            j['name'] as String,
        playtimeMinutes: j['playtimeMinutes'] as int,
        iconUrl:         j['iconUrl'] as String?,
      );
}

// ── Profil joueur Steam ───────────────────────────────────────────────────────

class SteamPlayerProfile {
  const SteamPlayerProfile({
    required this.steamId,
    required this.name,
    this.avatarUrl,
  });

  final String steamId;
  final String name;
  final String? avatarUrl;

  factory SteamPlayerProfile.fromJson(Map<String, dynamic> j) =>
      SteamPlayerProfile(
        steamId:   j['steamId'] as String,
        name:      j['name'] as String,
        avatarUrl: j['avatar'] as String?,
      );
}

// ── Réponse jeux possédés ─────────────────────────────────────────────────────

class OwnedGamesResponse {
  const OwnedGamesResponse({
    required this.games,
    required this.resolvedSteamId,
    this.player,
  });

  final List<SteamGame> games;
  /// SteamID64 résolu (utile si l'utilisateur a saisi une Vanity URL)
  final String resolvedSteamId;
  /// Profil du joueur (pseudo + avatar), null si profil privé
  final SteamPlayerProfile? player;
}

class SteamAchievement {
  const SteamAchievement({
    required this.apiName,
    required this.name,
    this.description,
    required this.unlocked,
    this.unlockedAt,
  });

  final String apiName;
  final String name;
  final String? description;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory SteamAchievement.fromJson(Map<String, dynamic> j) => SteamAchievement(
        apiName:     j['apiName'] as String,
        name:        j['name'] as String,
        description: j['description'] as String?,
        unlocked:    j['unlocked'] as bool,
        unlockedAt:  j['unlockedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['unlockedAt'] as int)
            : null,
      );
}

// ── Résultat de synchronisation ───────────────────────────────────────────────

class SteamSyncResult {
  const SteamSyncResult({
    this.importedGames = 0,
    this.updatedGames = 0,
    this.updatedAchievements = 0,
    this.errors = const [],
  });

  /// Jeux Steam importés comme nouvelles fiches locales.
  final int importedGames;
  /// Jeux locaux existants dont le playtime a été mis à jour.
  final int updatedGames;
  final int updatedAchievements;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasChanges => importedGames > 0 || updatedGames > 0 || updatedAchievements > 0;

  @override
  String toString() =>
      'SteamSyncResult(importés: $importedGames, mis à jour: $updatedGames, '
      'succès: $updatedAchievements, erreurs: ${errors.length})';
}

// ── Service ───────────────────────────────────────────────────────────────────

class SteamService {
  SteamService({required this.vercelBaseUrl});

  /// URL de base du proxy Vercel, sans slash final.
  /// Exemple : "https://arclog-steam-proxy.vercel.app"
  final String vercelBaseUrl;

  static const _timeout = Duration(seconds: 20);

  // ── Jeux possédés ─────────────────────────────────────────────────────────

  /// Récupère les jeux possédés. L'identifiant peut être un SteamID64
  /// (17 chiffres) ou une Vanity URL (pseudo Steam).
  Future<OwnedGamesResponse> fetchOwnedGames(String identifier) async {
    final uri = Uri.parse('$vercelBaseUrl/api/syncPlaytime')
        .replace(queryParameters: {'steamId': identifier});

    final resp = await http.get(uri).timeout(_timeout);
    _assertOk(resp, 'syncPlaytime');

    final body = jsonDecode(resp.body) as Map<String, dynamic>;

    final games = (body['games'] as List? ?? [])
        .map((g) => SteamGame.fromJson(g as Map<String, dynamic>))
        .toList();

    final resolvedId = (body['resolvedSteamId'] as String?) ?? identifier;

    final playerJson = body['player'] as Map<String, dynamic>?;
    final player = playerJson != null
        ? SteamPlayerProfile.fromJson(playerJson)
        : null;

    return OwnedGamesResponse(
      games: games,
      resolvedSteamId: resolvedId,
      player: player,
    );
  }

  // ── Succès d'un jeu ───────────────────────────────────────────────────────

  Future<List<SteamAchievement>> fetchAchievements(
    String steamId,
    int appId,
  ) async {
    final uri = Uri.parse('$vercelBaseUrl/api/syncAchievements').replace(
      queryParameters: {
        'steamId': steamId,
        'appId':   appId.toString(),
      },
    );

    final resp = await http.get(uri).timeout(_timeout);
    _assertOk(resp, 'syncAchievements');

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['achievements'] as List)
        .map((a) => SteamAchievement.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  void _assertOk(http.Response resp, String route) {
    if (resp.statusCode != 200) {
      throw Exception('[$route] HTTP ${resp.statusCode} — ${resp.body}');
    }
  }
}
