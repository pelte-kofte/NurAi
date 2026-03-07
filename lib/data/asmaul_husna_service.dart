import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'daily_content_service.dart';
import 'local_preferences_service.dart';

class AsmaulHusnaName {
  const AsmaulHusnaName({
    required this.id,
    required this.nameArabic,
    required this.nameTurkish,
    required this.nameEnglish,
    required this.meaningTurkish,
    required this.meaningEnglish,
    required this.shortReflectionTurkish,
    required this.shortReflectionEnglish,
    required this.dhikrTurkish,
    required this.dhikrEnglish,
  });

  final String id;
  final String nameArabic;
  final String nameTurkish;
  final String nameEnglish;
  final String meaningTurkish;
  final String meaningEnglish;
  final String shortReflectionTurkish;
  final String shortReflectionEnglish;
  final String dhikrTurkish;
  final String dhikrEnglish;

  factory AsmaulHusnaName.fromJson(Map<String, dynamic> json) {
    return AsmaulHusnaName(
      id: (json['id'] as String? ?? '').trim(),
      nameArabic: (json['name_ar'] as String? ?? '').trim(),
      nameTurkish: (json['name_tr'] as String? ?? '').trim(),
      nameEnglish: (json['name_en'] as String? ?? '').trim(),
      meaningTurkish: (json['meaning_tr'] as String? ?? '').trim(),
      meaningEnglish: (json['meaning_en'] as String? ?? '').trim(),
      shortReflectionTurkish:
          (json['short_reflection_tr'] as String? ?? '').trim(),
      shortReflectionEnglish:
          (json['short_reflection_en'] as String? ?? '').trim(),
      dhikrTurkish: (json['dhikr_tr'] as String? ?? '').trim(),
      dhikrEnglish: (json['dhikr_en'] as String? ?? '').trim(),
    );
  }

  String localizedName(String languageCode) =>
      languageCode.toLowerCase() == 'tr' ? nameTurkish : nameEnglish;

  String localizedMeaning(String languageCode) =>
      languageCode.toLowerCase() == 'tr' ? meaningTurkish : meaningEnglish;

  String localizedReflection(String languageCode) =>
      languageCode.toLowerCase() == 'tr'
          ? shortReflectionTurkish
          : shortReflectionEnglish;

  String localizedDhikr(String languageCode) =>
      languageCode.toLowerCase() == 'tr' ? dhikrTurkish : dhikrEnglish;

  bool matchesQuery(String query, String languageCode) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return true;
    return _normalize(nameArabic).contains(normalizedQuery) ||
        _normalize(nameTurkish).contains(normalizedQuery) ||
        _normalize(nameEnglish).contains(normalizedQuery) ||
        _normalize(localizedMeaning(languageCode)).contains(normalizedQuery);
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class AsmaulHusnaService {
  AsmaulHusnaService._();

  static const _assetPath = 'assets/content/asmaul_husna_tr_en.json';
  static const _rotationKeyPrefix = 'asma_daily';
  static List<AsmaulHusnaName>? _cache;

  static Future<List<AsmaulHusnaName>> getAllNames() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    final items = decoded
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .map(AsmaulHusnaName.fromJson)
        .where(
          (item) =>
              item.id.isNotEmpty &&
              item.nameArabic.isNotEmpty &&
              item.nameTurkish.isNotEmpty &&
              item.nameEnglish.isNotEmpty &&
              item.meaningTurkish.isNotEmpty &&
              item.meaningEnglish.isNotEmpty,
        )
        .toList(growable: false);

    _cache = items;
    return items;
  }

  static Future<AsmaulHusnaName?> getNameById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;
    final items = await getAllNames();
    for (final item in items) {
      if (item.id == normalizedId) return item;
    }
    return null;
  }

  static Future<AsmaulHusnaName> getDailyNameForDate(
    DateTime date,
    Locale locale,
  ) async {
    final items = await getAllNames();
    if (items.isEmpty) {
      return const AsmaulHusnaName(
        id: 'asma_fallback',
        nameArabic: 'الرَّحْمَٰنُ',
        nameTurkish: 'Er-Rahmân',
        nameEnglish: 'Ar-Rahman',
        meaningTurkish: 'Sonsuz merhamet sahibi',
        meaningEnglish: 'The Most Compassionate',
        shortReflectionTurkish: 'Allah’ın rahmeti bütün varlığı kuşatır.',
        shortReflectionEnglish: 'Allah’s mercy encompasses all creation.',
        dhikrTurkish: 'Yâ Rahmân',
        dhikrEnglish: 'Ya Rahman',
      );
    }

    final languageCode = _normalizeLanguageCode(locale.languageCode);
    final itemById = {
      for (final item in items) item.id: item,
    };
    final dateKey = _dateKey(date);
    final rotationKey = _rotationKey(languageCode);
    final state = _readRotationState(rotationKey);

    if (state.dateKey == dateKey &&
        state.currentId != null &&
        itemById.containsKey(state.currentId)) {
      return itemById[state.currentId]!;
    }

    final nextState = _advanceRotationState(
      state: state,
      dateKey: dateKey,
      rotationKey: rotationKey,
      availableIds: items.map((item) => item.id).toList(growable: false),
    );
    await _writeRotationState(rotationKey, nextState);

    return itemById[nextState.currentId] ?? items.first;
  }

  static String currentLanguageCode() =>
      _normalizeLanguageCode(LocalPreferencesService.language.value);

  static String _normalizeLanguageCode(String languageCode) {
    return languageCode.toLowerCase() == 'tr' ? 'tr' : 'en';
  }

  static String _rotationKey(String languageCode) =>
      '${_rotationKeyPrefix}_$languageCode';

  static _AsmaDailyRotationState _readRotationState(String rotationKey) {
    final raw = LocalPreferencesService.getHomeDailyRotationStateRaw(
      rotationKey,
    );
    if (raw == null || raw.trim().isEmpty) {
      return const _AsmaDailyRotationState();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const _AsmaDailyRotationState();
      return _AsmaDailyRotationState.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return const _AsmaDailyRotationState();
    }
  }

  static Future<void> _writeRotationState(
    String rotationKey,
    _AsmaDailyRotationState state,
  ) {
    return LocalPreferencesService.setHomeDailyRotationStateRaw(
      rotationKey,
      jsonEncode(state.toJson()),
    );
  }

  static _AsmaDailyRotationState _advanceRotationState({
    required _AsmaDailyRotationState state,
    required String dateKey,
    required String rotationKey,
    required List<String> availableIds,
  }) {
    if (availableIds.isEmpty) {
      return _AsmaDailyRotationState(dateKey: dateKey);
    }

    if (availableIds.length == 1) {
      return _AsmaDailyRotationState(
        dateKey: dateKey,
        currentId: availableIds.first,
        remainingIds: const [],
        cycle: state.cycle,
      );
    }

    final validIds = availableIds.toSet();
    final previousId =
        validIds.contains(state.currentId) ? state.currentId : null;
    var remaining = state.remainingIds
        .where(validIds.contains)
        .where((id) => id != previousId)
        .toList(growable: true);
    var cycle = state.cycle;

    if (remaining.isEmpty) {
      cycle += 1;
      remaining = List<String>.from(availableIds);
      remaining.shuffle(
        Random(
          DailyContentService.stableHash(
            '$rotationKey|$cycle|${availableIds.length}',
          ),
        ),
      );
      if (previousId != null && remaining.first == previousId) {
        final swapIndex = remaining.indexWhere((id) => id != previousId);
        if (swapIndex > 0) {
          final first = remaining.first;
          remaining[0] = remaining[swapIndex];
          remaining[swapIndex] = first;
        }
      }
    }

    final currentId = remaining.removeAt(0);
    return _AsmaDailyRotationState(
      dateKey: dateKey,
      currentId: currentId,
      remainingIds: remaining,
      cycle: cycle,
    );
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _AsmaDailyRotationState {
  const _AsmaDailyRotationState({
    this.dateKey,
    this.currentId,
    this.remainingIds = const [],
    this.cycle = 0,
  });

  final String? dateKey;
  final String? currentId;
  final List<String> remainingIds;
  final int cycle;

  factory _AsmaDailyRotationState.fromJson(Map<String, dynamic> json) {
    return _AsmaDailyRotationState(
      dateKey: json['dateKey'] as String?,
      currentId: json['currentId'] as String?,
      remainingIds: (json['remainingIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      cycle: json['cycle'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'currentId': currentId,
      'remainingIds': remainingIds,
      'cycle': cycle,
    };
  }
}
