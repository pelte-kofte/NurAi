import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

enum HomeDailyContentType {
  verse,
  hadith,
  gentleReminder,
  quote,
}

class DailyContentService {
  static bool _initialized = false;
  static bool _isLoading = false;

  static final revision = ValueNotifier<int>(0);
  static List<DailyContentItem> _hadith = const [];
  static List<DailyContentItem> _words = const [];

  static DailyContentItem? get todayHadith => _pickDeterministic(
        _hadith,
        DateTime.now(),
      );

  static DailyContentItem? get todayWord => _pickDeterministic(
        _words,
        DateTime.now(),
      );

  static HomeDailyContentType homeContentTypeForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return HomeDailyContentType.verse;
      case DateTime.tuesday:
        return HomeDailyContentType.hadith;
      case DateTime.wednesday:
        return HomeDailyContentType.gentleReminder;
      case DateTime.thursday:
        return HomeDailyContentType.quote;
      case DateTime.friday:
        return HomeDailyContentType.hadith;
      case DateTime.saturday:
        return HomeDailyContentType.verse;
      case DateTime.sunday:
        return HomeDailyContentType.gentleReminder;
      default:
        return HomeDailyContentType.verse;
    }
  }

  static DailyContentItem getQuoteForDate(DateTime date) {
    const quotes = <DailyContentItem>[
      DailyContentItem(
        id: 'quote_1',
        text:
            'The most beloved deeds to Allah are those done regularly, even if they are small.',
        source: 'Bukhari',
      ),
      DailyContentItem(
        id: 'quote_2',
        text: 'Whoever relies upon Allah, then He is sufficient for them.',
        source: 'At-Talaq 65:3',
      ),
      DailyContentItem(
        id: 'quote_3',
        text:
            'Indeed, Allah does not look at your forms, but He looks at your hearts and deeds.',
        source: 'Muslim',
      ),
    ];
    final index = reminderIndexForDate(date, quotes.length);
    return quotes[index];
  }

  static Future<String> getGentleReminderForDate(
    DateTime date,
    Locale locale,
  ) async {
    final normalized = _normalizeLanguageCode(locale.languageCode);
    final words = await _loadLocalizedList(
      primaryPath: 'assets/content/daily_words_$normalized.json',
      fallbackPath: 'assets/content/daily_words_en.json',
    );
    final picked = _pickDeterministic(words, date);
    return picked?.text ?? '';
  }

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
      final normalized = _normalizeLanguageCode(languageCode);
      final hadith = await _loadLocalizedList(
        primaryPath: 'assets/content/hadith_$normalized.json',
        fallbackPath: 'assets/content/hadith_en.json',
      );
      final words = await _loadLocalizedList(
        primaryPath: 'assets/content/daily_words_$normalized.json',
        fallbackPath: 'assets/content/daily_words_en.json',
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

  static String _normalizeLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tr':
      case 'en':
      case 'ar':
      case 'de':
      case 'fr':
        return languageCode.toLowerCase();
      default:
        return 'en';
    }
  }

  static DailyContentItem? _pickDeterministic(
    List<DailyContentItem> items,
    DateTime date,
  ) {
    if (items.isEmpty) return null;
    final index = reminderIndexForDate(date, items.length);
    return items[index];
  }

  static int reminderIndexForDate(DateTime date, int listLength) {
    if (listLength <= 0) return 0;
    final key = _dateKey(date);
    return stableHash(key) % listLength;
  }

  static int stableHash(String value) {
    // FNV-1a 32-bit for deterministic cross-run hashing.
    var hash = 0x811C9DC5;
    for (var i = 0; i < value.length; i++) {
      hash ^= value.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
