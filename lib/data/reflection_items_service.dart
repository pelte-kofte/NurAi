import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class ReflectionItem {
  const ReflectionItem({
    required this.type,
    this.arabic,
    required this.tr,
    required this.en,
  });

  final String type;
  final String? arabic;
  final ReflectionItemLocale tr;
  final ReflectionItemLocale en;

  factory ReflectionItem.fromJson(Map<String, dynamic> json) {
    return ReflectionItem(
      type: (json['type'] as String? ?? '').trim().toLowerCase(),
      arabic: (json['arabic'] as String?)?.trim(),
      tr: ReflectionItemLocale.fromJson(
        (json['tr'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            const <String, dynamic>{},
      ),
      en: ReflectionItemLocale.fromJson(
        (json['en'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            const <String, dynamic>{},
      ),
    );
  }

  ReflectionItemLocale localized(String languageCode) {
    return languageCode.toLowerCase() == 'tr' ? tr : en;
  }

  bool get isSupportedType => type == 'ayah' || type == 'asma' || type == 'dhikr';

  bool isValid() {
    if (!isSupportedType) return false;
    return tr.isValidForType(type) && en.isValidForType(type);
  }
}

class ReflectionItemLocale {
  const ReflectionItemLocale({
    this.text,
    this.source,
    this.guidance,
    this.name,
    this.meaning,
    this.transliteration,
  });

  final String? text;
  final String? source;
  final String? guidance;
  final String? name;
  final String? meaning;
  final String? transliteration;

  factory ReflectionItemLocale.fromJson(Map<String, dynamic> json) {
    String? read(String key) => (json[key] as String?)?.trim();

    return ReflectionItemLocale(
      text: read('text'),
      source: read('source'),
      guidance: read('guidance'),
      name: read('name'),
      meaning: read('meaning'),
      transliteration: read('transliteration'),
    );
  }

  bool isValidForType(String type) {
    switch (type) {
      case 'ayah':
        return _has(text) && _has(source) && _has(guidance);
      case 'asma':
        return _has(name) && _has(meaning) && _has(guidance);
      case 'dhikr':
        return _has(transliteration) && _has(meaning) && _has(guidance);
      default:
        return false;
    }
  }

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;
}

class ReflectionItemsService {
  ReflectionItemsService._();

  static const _assetPath = 'assets/data/reflection_items.json';
  static List<ReflectionItem>? _cache;

  static Future<List<ReflectionItem>> loadItems() async {
    final cached = _cache;
    if (cached != null) return cached;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache = fallbackItems;
        return _cache!;
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .map(ReflectionItem.fromJson)
          .where((item) => item.isValid())
          .toList(growable: false);

      _cache = items.isEmpty ? fallbackItems : items;
      return _cache!;
    } catch (_) {
      _cache = fallbackItems;
      return _cache!;
    }
  }

  static List<ReflectionItem> pickSessionItems(
    List<ReflectionItem> items, {
    int count = 3,
    Random? random,
  }) {
    if (items.isEmpty) return fallbackItems.take(count).toList(growable: false);

    final source = List<ReflectionItem>.from(items);
    source.shuffle(random ?? Random());
    final selected = source.take(min(count, source.length)).toList(growable: false);
    if (selected.length >= count) return selected;

    final filled = List<ReflectionItem>.from(selected);
    const fallback = fallbackItems;
    var index = 0;
    while (filled.length < count) {
      filled.add(fallback[index % fallback.length]);
      index += 1;
    }
    return filled;
  }

  static const fallbackItems = <ReflectionItem>[
    ReflectionItem(
      type: 'ayah',
      arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      tr: ReflectionItemLocale(
        text: 'Kalpler ancak Allah’ı anmakla huzur bulur.',
        source: 'Ra’d Suresi 13:28',
        guidance: 'Bu sözün içinde birkaç saniye kal.',
      ),
      en: ReflectionItemLocale(
        text: 'Surely in the remembrance of Allah do hearts find rest.',
        source: 'Surah Ar-Ra’d 13:28',
        guidance: 'Stay with these words for a few seconds.',
      ),
    ),
    ReflectionItem(
      type: 'dhikr',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      tr: ReflectionItemLocale(
        transliteration: 'Subhanallahi ve bihamdihi',
        meaning: 'Allah her türlü eksiklikten uzaktır; hamd O’nadır.',
        guidance: 'İçinden tekrar et.',
      ),
      en: ReflectionItemLocale(
        transliteration: 'Subhanallahi wa bihamdihi',
        meaning: 'Glory be to Allah, and praise belongs to Him.',
        guidance: 'Repeat it quietly within.',
      ),
    ),
    ReflectionItem(
      type: 'asma',
      arabic: 'اللَّطِيفُ',
      tr: ReflectionItemLocale(
        name: 'El-Latif',
        meaning: 'İncelikle kuşatan, yumuşaklıkla ulaştıran.',
        guidance: 'Bu anlamı düşün.',
      ),
      en: ReflectionItemLocale(
        name: 'Al-Latif',
        meaning: 'The One who reaches with subtle mercy.',
        guidance: 'Reflect on this meaning.',
      ),
    ),
  ];
}
