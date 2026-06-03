import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Nom du joueur ─────────────────────────────────────────────────────────────

class PlayerNameNotifier extends AsyncNotifier<String> {
  static const _key = 'player_name';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'PLAYER 1';
  }

  Future<void> setName(String raw) async {
    final name = raw.trim().isEmpty ? 'PLAYER 1' : raw.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
    state = AsyncData(name);
  }
}

final playerNameProvider =
    AsyncNotifierProvider<PlayerNameNotifier, String>(PlayerNameNotifier.new);

// ── Steam ID ──────────────────────────────────────────────────────────────────

class SteamIdNotifier extends AsyncNotifier<String> {
  static const _key = 'steam_id';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  Future<void> setId(String id) async {
    final trimmed = id.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
    state = AsyncData(trimmed);
  }
}

final steamIdProvider =
    AsyncNotifierProvider<SteamIdNotifier, String>(SteamIdNotifier.new);

// ── URL Vercel ────────────────────────────────────────────────────────────────

class VercelUrlNotifier extends AsyncNotifier<String> {
  static const _key = 'vercel_url';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  Future<void> setUrl(String url) async {
    // Supprimer le slash final pour une URL propre
    final cleaned = url.trim().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, cleaned);
    state = AsyncData(cleaned);
  }
}

final vercelUrlProvider =
    AsyncNotifierProvider<VercelUrlNotifier, String>(VercelUrlNotifier.new);

// ── Avatar Steam ──────────────────────────────────────────────────────────────

class SteamAvatarNotifier extends AsyncNotifier<String> {
  static const _key = 'steam_avatar_url';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  Future<void> setUrl(String url) async {
    final trimmed = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
    state = AsyncData(trimmed);
  }
}

final steamAvatarProvider =
    AsyncNotifierProvider<SteamAvatarNotifier, String>(SteamAvatarNotifier.new);
