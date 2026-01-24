import '../models/ayah.dart';

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

  /// Formatted reference for display: "Fâtiha Suresi, 1"
  String get reference => '$surahName Suresi, $ayahNumber';
}

/// Selects a deterministic daily ayah based on calendar date.
/// Same day always returns the same ayah. No randomness.
class DailyAyahService {
  /// Returns today's ayah from the provided list.
  /// Selection is deterministic: same calendar day → same ayah.
  static Ayah getTodayAyah(List<Ayah> allAyahs) {
    if (allAyahs.isEmpty) {
      throw StateError('Cannot select daily ayah from empty list');
    }

    final index = _getDayIndex() % allAyahs.length;
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

  /// Converts current date to a stable day index.
  /// Uses days since a fixed epoch for consistency.
  static int _getDayIndex() {
    final today = DateTime.now();
    final epoch = DateTime(2024, 1, 1);
    return today.difference(epoch).inDays;
  }
}
