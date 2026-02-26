import 'dart:convert';

import 'package:flutter/services.dart';

class QuranTurkishMealService {
  QuranTurkishMealService._();

  static const _assetPath = 'assets/content/quran_tr_meal.json';
  static Map<String, String> _cache = const {};
  static Future<void>? _loadFuture;

  static Future<String?> getTurkishMeal(int surah, int ayah) async {
    await _ensureLoaded();
    final key = '$surah|$ayah';
    final value = _cache[key];
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<void> _ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  static Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _cache = const {};
        return;
      }
      _cache = decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value?.toString() ?? '',
        ),
      );
    } catch (_) {
      _cache = const {};
    }
  }
}
