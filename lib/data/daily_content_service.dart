import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_preferences_service.dart';

class DailyContentItem {
  final String id;
  final String text;
  final String? source;

  const DailyContentItem({
    required this.id,
    required this.text,
    this.source,
  });

  factory DailyContentItem.fromJson(Map<String, dynamic> json) {
    return DailyContentItem(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      source: json['source']?.toString(),
    );
  }
}

class DailyContentService {
  static bool _initialized = false;
  static bool _isLoading = false;

  static final revision = ValueNotifier<int>(0);
  static List<DailyContentItem> _hadith = const [];
  static List<DailyContentItem> _words = const [];

  static DailyContentItem? get todayHadith =>
      _pickDeterministic(_hadith);

  static DailyContentItem? get todayWord =>
      _pickDeterministic(_words);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    LocalPreferencesService.language.addListener(_onLanguageChanged);
    await _loadForLanguage(LocalPreferencesService.language.value);
  }

  static Future<void> _onLanguageChanged() async {
    await _loadForLanguage(LocalPreferencesService.language.value);
  }

  static Future<void> _loadForLanguage(String languageCode) async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final normalized = languageCode.toLowerCase() == 'en' ? 'en' : 'tr';
      final hadith = await _loadLocalizedList(
        primaryPath: 'assets/content/hadith_$normalized.json',
        fallbackPath: 'assets/content/hadith_tr.json',
      );
      final words = await _loadLocalizedList(
        primaryPath: 'assets/content/daily_words_$normalized.json',
        fallbackPath: 'assets/content/daily_words_tr.json',
      );
      _hadith = hadith;
      _words = words;
      revision.value = revision.value + 1;
    } finally {
      _isLoading = false;
    }
  }

  static Future<List<DailyContentItem>> _loadLocalizedList({
    required String primaryPath,
    required String fallbackPath,
  }) async {
    final primary = await _loadList(primaryPath);
    if (primary.isNotEmpty) return primary;
    if (primaryPath == fallbackPath) return primary;
    return _loadList(fallbackPath);
  }

  static Future<List<DailyContentItem>> _loadList(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value,
                ),
              ))
          .map(DailyContentItem.fromJson)
          .where((e) => e.id.trim().isNotEmpty && e.text.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static DailyContentItem? _pickDeterministic(List<DailyContentItem> items) {
    if (items.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final daySeed = now.year * 1000 + dayOfYear;
    final index = daySeed % items.length;
    return items[index];
  }
}
