import 'dart:convert';

import 'local_preferences_service.dart';

class AsmaulHusnaFavoritesService {
  AsmaulHusnaFavoritesService._();

  static Future<Set<String>> getFavoriteIds() async {
    final raw = LocalPreferencesService.getAsmaFavoritesRaw();
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<bool> isFavorite(String id) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(id.trim());
  }

  static Future<bool> addIfAbsent(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return false;

    final favorites = await getFavoriteIds();
    if (favorites.contains(normalizedId)) return false;
    favorites.add(normalizedId);
    await _writeFavorites(favorites);
    return true;
  }

  static Future<bool> toggle(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return false;

    final favorites = await getFavoriteIds();
    final isNowFavorite = !favorites.contains(normalizedId);
    if (isNowFavorite) {
      favorites.add(normalizedId);
    } else {
      favorites.remove(normalizedId);
    }
    await _writeFavorites(favorites);
    return isNowFavorite;
  }

  static Future<void> _writeFavorites(Set<String> favorites) {
    final sorted = favorites.toList()..sort();
    return LocalPreferencesService.setAsmaFavoritesRaw(jsonEncode(sorted));
  }
}
