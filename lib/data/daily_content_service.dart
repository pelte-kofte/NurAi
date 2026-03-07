import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

class DailyQuoteItem {
  final String text;
  final String? source;

  const DailyQuoteItem({
    required this.text,
    this.source,
  });

  factory DailyQuoteItem.fromJson(Map<String, dynamic> json) {
    return DailyQuoteItem(
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
  asma,
}

class DailyContentService {
  static bool _initialized = false;
  static bool _isLoading = false;

  static final revision = ValueNotifier<int>(0);
  static List<DailyContentItem> _hadith = const [];
  static List<DailyContentItem> _words = const [];
  static final Map<String, List<DailyQuoteItem>> _quotesCacheByLang = {};

  static DailyContentItem? get todayHadith => _pickDeterministic(
        _hadith,
        DateTime.now(),
      );

  static DailyContentItem? get todayWord => _pickRotatingWord(DateTime.now());

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
        return HomeDailyContentType.asma;
      case DateTime.saturday:
        return HomeDailyContentType.verse;
      case DateTime.sunday:
        return HomeDailyContentType.gentleReminder;
      default:
        return HomeDailyContentType.verse;
    }
  }

  static Future<DailyQuoteItem> getQuoteForDate(
    DateTime date, [
    Locale? locale,
  ]) async {
    final normalized = _normalizeQuoteLanguageCode(
      locale?.languageCode ?? LocalPreferencesService.language.value,
    );
    final quotes = await _loadQuotesForLanguage(normalized);
    if (quotes.isEmpty) {
      return const DailyQuoteItem(
        text:
            'The most beloved deeds to Allah are those done regularly, even if they are small.',
        source: 'Bukhari',
      );
    }
    final index = _nextRotatingIndex(
      date: date,
      rotationKey: _rotationKey('quote', normalized),
      poolLength: quotes.length,
    );
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
    final picked = _pickRotatingFromList(
      words,
      date,
      rotationKey: _rotationKey('reminder', normalized),
    );
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

  static Future<List<DailyQuoteItem>> _loadQuotesForLanguage(
      String lang) async {
    final normalized = _normalizeQuoteLanguageCode(lang);
    final cached = _quotesCacheByLang[normalized];
    if (cached != null) return cached;

    final primary =
        await _loadQuoteList('assets/content/quotes_$normalized.json');
    if (primary.isNotEmpty) {
      _quotesCacheByLang[normalized] = primary;
      return primary;
    }

    if (normalized == 'en') {
      _quotesCacheByLang['en'] = const [];
      return const [];
    }

    final fallback = await _loadQuoteList('assets/content/quotes_en.json');
    _quotesCacheByLang[normalized] = fallback;
    if (fallback.isNotEmpty) {
      _quotesCacheByLang['en'] = fallback;
    }
    return fallback;
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

  static Future<List<DailyQuoteItem>> _loadQuoteList(String path) async {
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
          .map(DailyQuoteItem.fromJson)
          .where((e) => e.text.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static String _normalizeLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tr':
      case 'en':
        return languageCode.toLowerCase();
      default:
        return 'en';
    }
  }

  static String _normalizeQuoteLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tr':
      case 'en':
        return languageCode.toLowerCase();
      default:
        return 'en';
    }
  }

  static DailyContentItem? _pickRotatingWord(DateTime date) {
    final normalized = _normalizeLanguageCode(
      LocalPreferencesService.language.value,
    );
    return _pickRotatingFromList(
      _words,
      date,
      rotationKey: _rotationKey('reminder', normalized),
    );
  }

  static DailyContentItem? _pickRotatingFromList(
    List<DailyContentItem> items,
    DateTime date, {
    required String rotationKey,
  }) {
    if (items.isEmpty) return null;
    final index = _nextRotatingIndex(
      date: date,
      rotationKey: rotationKey,
      poolLength: items.length,
    );
    return items[index];
  }

  static DailyContentItem? _pickDeterministic(
    List<DailyContentItem> items,
    DateTime date,
  ) {
    if (items.isEmpty) return null;
    final index = reminderIndexForDate(date, items.length);
    return items[index];
  }

  static int _nextRotatingIndex({
    required DateTime date,
    required String rotationKey,
    required int poolLength,
  }) {
    if (poolLength <= 1) return 0;

    final dateKey = _dateKey(date);
    final saved = _readRotationState(rotationKey);
    if (saved.dateKey == dateKey &&
        saved.currentIndex != null &&
        saved.currentIndex! >= 0 &&
        saved.currentIndex! < poolLength) {
      return saved.currentIndex!;
    }
    final updatedState = _computeNextRotationState(
      state: saved,
      nextDateKey: dateKey,
      rotationKey: rotationKey,
      nextPoolLength: poolLength,
    );
    unawaited(_writeRotationState(rotationKey, updatedState));
    return updatedState.currentIndex ?? 0;
  }

  static List<int> _buildShuffledQueue(
    int poolLength, {
    required String rotationKey,
    required int cycle,
    int? previousIndex,
  }) {
    final queue = List<int>.generate(poolLength, (index) => index);
    final seed = stableHash('$rotationKey|$cycle|$poolLength');
    queue.shuffle(Random(seed));
    if (poolLength > 1 &&
        previousIndex != null &&
        queue.isNotEmpty &&
        queue.first == previousIndex) {
      final swapIndex = queue.indexWhere((index) => index != previousIndex);
      if (swapIndex > 0) {
        final first = queue.first;
        queue[0] = queue[swapIndex];
        queue[swapIndex] = first;
      }
    }
    return queue;
  }

  static String _rotationKey(String type, String locale) => '${type}_$locale';

  static _HomeDailyRotationState _readRotationState(String rotationKey) {
    final raw = LocalPreferencesService.getHomeDailyRotationStateRaw(
      rotationKey,
    );
    if (raw == null || raw.trim().isEmpty) {
      return const _HomeDailyRotationState();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const _HomeDailyRotationState();
      return _HomeDailyRotationState.fromJson(
        decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } catch (_) {
      return const _HomeDailyRotationState();
    }
  }

  static Future<void> _writeRotationState(
    String rotationKey,
    _HomeDailyRotationState state,
  ) {
    return LocalPreferencesService.setHomeDailyRotationStateRaw(
      rotationKey,
      jsonEncode(state.toJson()),
    );
  }

  @visibleForTesting
  static Map<String, dynamic> nextRotationStateForTesting({
    required String? dateKey,
    required int? currentIndex,
    required List<int> remainingIndices,
    required int? poolLength,
    required int cycle,
    required String nextDateKey,
    required String rotationKey,
    required int nextPoolLength,
  }) {
    final state = _HomeDailyRotationState(
      dateKey: dateKey,
      currentIndex: currentIndex,
      remainingIndices: remainingIndices,
      poolLength: poolLength,
      cycle: cycle,
    );
    return _computeNextRotationState(
      state: state,
      nextDateKey: nextDateKey,
      rotationKey: rotationKey,
      nextPoolLength: nextPoolLength,
    ).toJson();
  }

  static _HomeDailyRotationState _computeNextRotationState({
    required _HomeDailyRotationState state,
    required String nextDateKey,
    required String rotationKey,
    required int nextPoolLength,
  }) {
    if (nextPoolLength <= 1) {
      return _HomeDailyRotationState(
        dateKey: nextDateKey,
        currentIndex: 0,
        remainingIndices: const [],
        poolLength: nextPoolLength,
        cycle: state.cycle,
      );
    }
    if (state.dateKey == nextDateKey &&
        state.currentIndex != null &&
        state.currentIndex! >= 0 &&
        state.currentIndex! < nextPoolLength) {
      return state;
    }
    final sanitizedQueue = state.remainingIndices
        .where((index) => index >= 0 && index < nextPoolLength)
        .toList(growable: true);
    final nextCycle = state.poolLength == nextPoolLength ? state.cycle : 0;
    final previousIndex = state.currentIndex != null &&
            state.currentIndex! >= 0 &&
            state.currentIndex! < nextPoolLength
        ? state.currentIndex
        : null;
    final queue = sanitizedQueue.isNotEmpty
        ? sanitizedQueue
        : _buildShuffledQueue(
            nextPoolLength,
            previousIndex: previousIndex,
            rotationKey: rotationKey,
            cycle: nextCycle,
          );
    final nextIndex = queue.removeAt(0);
    return _HomeDailyRotationState(
      dateKey: nextDateKey,
      currentIndex: nextIndex,
      remainingIndices: queue,
      poolLength: nextPoolLength,
      cycle: queue.isEmpty ? nextCycle + 1 : nextCycle,
    );
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

class _HomeDailyRotationState {
  const _HomeDailyRotationState({
    this.dateKey,
    this.currentIndex,
    this.remainingIndices = const [],
    this.poolLength,
    this.cycle = 0,
  });

  final String? dateKey;
  final int? currentIndex;
  final List<int> remainingIndices;
  final int? poolLength;
  final int cycle;

  factory _HomeDailyRotationState.fromJson(Map<String, dynamic> json) {
    final remaining = json['remainingIndices'];
    return _HomeDailyRotationState(
      dateKey: json['dateKey']?.toString(),
      currentIndex: json['currentIndex'] is int
          ? json['currentIndex'] as int
          : int.tryParse(json['currentIndex']?.toString() ?? ''),
      remainingIndices: remaining is List
          ? remaining
              .map((value) => value is int ? value : int.tryParse('$value'))
              .whereType<int>()
              .toList(growable: false)
          : const [],
      poolLength: json['poolLength'] is int
          ? json['poolLength'] as int
          : int.tryParse(json['poolLength']?.toString() ?? ''),
      cycle: json['cycle'] is int
          ? json['cycle'] as int
          : int.tryParse(json['cycle']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'currentIndex': currentIndex,
      'remainingIndices': remainingIndices,
      'poolLength': poolLength,
      'cycle': cycle,
    };
  }
}
