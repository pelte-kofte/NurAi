import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class QuranTranslationService {
  QuranTranslationService._();

  static const _englishAssetPath = 'assets/content/quran_en.json';
  static const _turkishMealAssetPath = 'assets/content/quran_tr_meal.json';

  static Map<String, String> _englishCache = const {};
  static Map<String, String> _turkishMealCache = const {};
  static Future<void>? _loadFuture;

  static Future<String?> getTranslation(
      int surah, int ayah, Locale locale) async {
    await _ensureLoaded();
    final key = '$surah|$ayah';
    final languageCode = locale.languageCode.toLowerCase();

    final text = switch (languageCode) {
      'en' => _englishCache[key],
      'tr' => _turkishMealCache[key],
      _ => null,
    };
    if (text == null) return null;
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<void> _ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  static Future<void> _load() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString(_englishAssetPath),
        rootBundle.loadString(_turkishMealAssetPath),
      ]);
      _englishCache = _decodeMap(results[0]);
      _turkishMealCache = _decodeMap(results[1]);
    } catch (_) {
      _englishCache = const {};
      _turkishMealCache = const {};
    }
  }

  static Map<String, String> _decodeMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return decoded.map(
      (key, value) => MapEntry(
        key.toString(),
        value?.toString() ?? '',
      ),
    );
  }
}
