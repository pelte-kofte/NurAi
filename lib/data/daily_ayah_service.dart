import 'package:flutter/widgets.dart';

import '../models/ayah.dart';
import 'quran_data.dart';
import 'quran_english_service.dart';

/// Enriched daily ayah with surah context for display.
class DailyAyah {
  final Ayah ayah;
  final String surahName;

  const DailyAyah({
    required this.ayah,
    required this.surahName,
  });

  String get arabic => ayah.arabic;
  String get turkishReadable => ayah.turkishReadable;
  int get surahNumber => ayah.surah;
  int get ayahNumber => ayah.ayahNumber;

  String get reference => '$surahName Suresi, $ayahNumber';
}

/// Selects a deterministic daily ayah based on calendar date.
/// Includes Ramadan awareness for themed ayah selection.
class DailyAyahService {
  /// Surah numbers containing themes of mercy, patience, encouragement.
  /// Used during Ramadan for more relevant selections.
  static const _ramadanPreferredSurahs = [
    1,   // Fatiha - opening, mercy
    2,   // Bakara - fasting verses (183-187)
    3,   // Al-Imran - patience, steadfastness
    13,  // Ra'd - remembrance
    25,  // Furqan - servants of Rahman
    36,  // Yasin - heart of Quran
    55,  // Rahman - mercy
    67,  // Mulk - reflection
    73,  // Muzzammil - night prayer
    87,  // A'la - purification
    93,  // Duha - comfort
    94,  // Inshirah - ease after hardship
    97,  // Qadr - Night of Power
    112, // Ikhlas - sincerity
  ];

  /// Returns today's ayah from the provided list.
  /// During Ramadan, prefers ayahs from themed surahs.
  static Ayah getTodayAyah(List<Ayah> allAyahs) {
    if (allAyahs.isEmpty) {
      throw StateError('Cannot select daily ayah from empty list');
    }

    final dayIndex = _getDayIndex();

    if (_isRamadan()) {
      final ramadanAyahs = allAyahs
          .where((a) => _ramadanPreferredSurahs.contains(a.surah))
          .toList();

      if (ramadanAyahs.isNotEmpty) {
        final index = _spreadIndex(dayIndex, ramadanAyahs.length);
        return ramadanAyahs[index];
      }
    }

    final index = _spreadIndex(dayIndex, allAyahs.length);
    return allAyahs[index];
  }

  /// Returns today's ayah with surah name context.
  static DailyAyah getTodayAyahWithContext(
    List<Ayah> allAyahs,
    String Function(int surahNumber) getSurahName,
  ) {
    final ayah = getTodayAyah(allAyahs);
    final surahName = getSurahName(ayah.surah);
    return DailyAyah(ayah: ayah, surahName: surahName);
  }

  static Future<String> getAyahReadableText({
    required int surah,
    required int ayah,
    required Locale locale,
  }) async {
    if (locale.languageCode.toLowerCase() == 'en') {
      final english = await QuranEnglishService.getEnglishAyah(surah, ayah);
      if (english != null && english.trim().isNotEmpty) {
        return english.trim();
      }
    }
    return _getTurkishAyahText(surah: surah, ayah: ayah) ?? '';
  }

  /// Converts current date to a stable day index.
  static int _getDayIndex() {
    final today = DateTime.now();
    final epoch = DateTime(2024, 1, 1);
    return today.difference(epoch).inDays;
  }

  /// Spreads index to reduce consecutive repeats.
  /// Uses a simple multiplicative hash for better distribution.
  static int _spreadIndex(int dayIndex, int length) {
    // Prime multiplier for better distribution
    final spread = (dayIndex * 2654435761) % length;
    return spread.abs();
  }

  /// Checks if current date falls within Ramadan.
  /// Uses approximate Gregorian dates (updated yearly).
  static bool _isRamadan() {
    final now = DateTime.now();

    // Ramadan 2025: approx March 1 - March 30
    // Ramadan 2026: approx February 18 - March 19
    final ramadanRanges = {
      2025: (DateTime(2025, 3, 1), DateTime(2025, 3, 30)),
      2026: (DateTime(2026, 2, 18), DateTime(2026, 3, 19)),
      2027: (DateTime(2027, 2, 8), DateTime(2027, 3, 9)),
    };

    final range = ramadanRanges[now.year];
    if (range == null) return false;

    return now.isAfter(range.$1.subtract(const Duration(days: 1))) &&
           now.isBefore(range.$2.add(const Duration(days: 1)));
  }

  /// Exposes Ramadan status for UI hints (if needed).
  static bool get isRamadanActive => _isRamadan();

  static String? _getTurkishAyahText({
    required int surah,
    required int ayah,
  }) {
    for (final item in QuranData.instance.ayahs) {
      if (item.surah == surah && item.ayahNumber == ayah) {
        return item.turkishReadable;
      }
    }
    return null;
  }
}
