import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ayah.dart';
import '../models/surah.dart';

/// Loads and caches Quran data from local JSON assets.
/// Data is loaded once and kept in memory for the session.
class QuranData {
  static QuranData? _instance;
  static QuranData get instance => _instance ??= QuranData._();

  QuranData._();

  List<Ayah>? _ayahs;
  List<Surah>? _surahs;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Ayah> get ayahs => _ayahs ?? [];
  List<Surah> get surahs => _surahs ?? [];

  /// Loads all Quran data from assets. Call once at app startup.
  Future<void> load() async {
    if (_isLoaded) return;

    final results = await Future.wait([
      rootBundle.loadString('assets/quran/final/quran_ar_tr.json'),
      rootBundle.loadString('assets/quran/meta/surahs.json'),
    ]);

    final ayahJson = jsonDecode(results[0]) as List<dynamic>;
    final surahJson = jsonDecode(results[1]) as List<dynamic>;

    _ayahs = ayahJson.map((e) => Ayah.fromJson(e)).toList();
    _surahs = surahJson.map((e) => Surah.fromJson(e)).toList();
    _isLoaded = true;
  }

  /// Returns the Turkish name of a surah by its number (1-114).
  String getSurahName(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return '';
    return _surahs?[surahNumber - 1].nameTurkish ?? '';
  }

  /// Returns a daily ayah based on the current date.
  /// Uses a simple hash of the date to pick a consistent ayah for each day.
  Ayah? getDailyAyah() {
    if (_ayahs == null || _ayahs!.isEmpty) return null;

    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2024, 1, 1)).inDays;
    final index = daysSinceEpoch % _ayahs!.length;

    return _ayahs![index];
  }

  /// Returns all ayahs for a specific surah (1-114).
  List<Ayah> getAyahsForSurah(int surahNumber) {
    if (_ayahs == null) return [];
    return _ayahs!.where((a) => a.surah == surahNumber).toList();
  }
}
