import 'dart:convert';

import 'local_preferences_service.dart';

enum TodayCardFavoriteType {
  ayah,
  hadith,
  reminder,
  quote,
}

class TodayCardFavorite {
  const TodayCardFavorite({
    required this.type,
    required this.title,
    required this.content,
    required this.savedAtIso,
    this.reference,
    this.arabicText,
    this.localeCode,
    this.surahNumber,
    this.ayahNumber,
  });

  final TodayCardFavoriteType type;
  final String title;
  final String content;
  final String savedAtIso;
  final String? reference;
  final String? arabicText;
  final String? localeCode;
  final int? surahNumber;
  final int? ayahNumber;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'content': content,
      'savedAtIso': savedAtIso,
      'reference': reference,
      'arabicText': arabicText,
      'localeCode': localeCode,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
    };
  }

  factory TodayCardFavorite.fromJson(Map<String, dynamic> json) {
    return TodayCardFavorite(
      type: TodayCardFavoriteType.values.firstWhere(
        (value) => value.name == (json['type'] as String? ?? '').trim(),
        orElse: () => TodayCardFavoriteType.reminder,
      ),
      title: (json['title'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
      savedAtIso: (json['savedAtIso'] as String? ?? '').trim(),
      reference: (json['reference'] as String?)?.trim(),
      arabicText: (json['arabicText'] as String?)?.trim(),
      localeCode: (json['localeCode'] as String?)?.trim(),
      surahNumber: json['surahNumber'] as int?,
      ayahNumber: json['ayahNumber'] as int?,
    );
  }

  bool matches(TodayCardFavorite other) {
    if (type != other.type) return false;
    if (type == TodayCardFavoriteType.ayah) {
      return surahNumber == other.surahNumber && ayahNumber == other.ayahNumber;
    }
    return title == other.title &&
        content == other.content &&
        (reference ?? '') == (other.reference ?? '');
  }
}

class TodayCardFavoritesService {
  TodayCardFavoritesService._();

  static Future<List<TodayCardFavorite>> getFavorites() async {
    final raw = LocalPreferencesService.getTodayCardFavoritesRaw();
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = decoded
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .map(TodayCardFavorite.fromJson)
          .where((item) => item.title.isNotEmpty && item.content.isNotEmpty)
          .toList(growable: false);
      final sorted = List<TodayCardFavorite>.from(items)
        ..sort((a, b) => b.savedAtIso.compareTo(a.savedAtIso));
      return sorted;
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> addIfAbsent(TodayCardFavorite favorite) async {
    final favorites = List<TodayCardFavorite>.from(await getFavorites());
    final exists = favorites.any((item) => item.matches(favorite));
    if (exists) return false;
    favorites.insert(0, favorite);
    await _writeFavorites(favorites);
    return true;
  }

  static Future<void> _writeFavorites(List<TodayCardFavorite> favorites) async {
    final raw = jsonEncode(favorites.map((item) => item.toJson()).toList());
    await LocalPreferencesService.setTodayCardFavoritesRaw(raw);
  }
}
