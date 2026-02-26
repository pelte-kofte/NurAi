import 'dart:convert';

import 'package:flutter/services.dart';

class QuranEnglishService {
  QuranEnglishService._();

  static const _assetPath = 'assets/content/quran_en.json';
  static Map<String, String> _cache = const {};
  static Future<void>? _loadFuture;

  static Future<String?> getEnglishAyah(int surah, int ayah) async {
    await _ensureLoaded();
    final key = '$surah|$ayah';
    return _cache[key];
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
