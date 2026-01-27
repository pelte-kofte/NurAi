import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a Juz (cüz) range in the Quran.
class JuzRange {
  final int juzNumber;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  const JuzRange({
    required this.juzNumber,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  factory JuzRange.fromJson(Map<String, dynamic> json) {
    return JuzRange(
      juzNumber: json['juz'] as int,
      startSurah: json['start']['surah'] as int,
      startAyah: json['start']['ayah'] as int,
      endSurah: json['end']['surah'] as int,
      endAyah: json['end']['ayah'] as int,
    );
  }

  /// Checks if a given surah:ayah falls within this juz range.
  bool containsAyah(int surah, int ayah) {
    // Before start
    if (surah < startSurah) return false;
    if (surah == startSurah && ayah < startAyah) return false;

    // After end
    if (surah > endSurah) return false;
    if (surah == endSurah && ayah > endAyah) return false;

    return true;
  }
}

/// Silent background service for Collective Reading (Cüz Niyeti).
/// Tracks reading progress without any UI feedback.
class CollectiveReadingService {
  static const _selectedJuzKey = 'collective_selected_juz';
  static const _readAyahsKey = 'collective_read_ayahs';
  static const _completedKey = 'collective_completed';

  static SharedPreferences? _prefs;
  static List<JuzRange> _juzRanges = [];

  /// Initialize the service. Must be called before use.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadJuzRanges();
  }

  static Future<void> _loadJuzRanges() async {
    final jsonString =
        await rootBundle.loadString('assets/quran/meta/juz_ranges.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _juzRanges = jsonList.map((j) => JuzRange.fromJson(j)).toList();
  }

  /// Get all juz ranges (for selector UI).
  static List<JuzRange> get juzRanges => _juzRanges;

  /// Get the currently selected juz number, or null if none.
  static int? getSelectedJuz() {
    final value = _prefs?.getInt(_selectedJuzKey);
    return value;
  }

  /// Select a juz for collective reading intention.
  static Future<void> selectJuz(int juzNumber) async {
    await _prefs?.setInt(_selectedJuzKey, juzNumber);
    // Clear previous read ayahs and completion status
    await _prefs?.remove(_readAyahsKey);
    await _prefs?.remove(_completedKey);
  }

  /// Clear the current juz selection.
  static Future<void> clearSelection() async {
    await _prefs?.remove(_selectedJuzKey);
    await _prefs?.remove(_readAyahsKey);
    await _prefs?.remove(_completedKey);
  }

  /// Check if there's an active juz selection.
  static bool hasActiveSelection() {
    return getSelectedJuz() != null && !isCompleted();
  }

  /// Get the JuzRange for the selected juz.
  static JuzRange? getSelectedJuzRange() {
    final juzNumber = getSelectedJuz();
    if (juzNumber == null) return null;
    return _juzRanges.firstWhere(
      (j) => j.juzNumber == juzNumber,
      orElse: () => _juzRanges.first,
    );
  }

  /// Silently record an ayah read. No UI feedback.
  /// Only records if the ayah falls within the selected juz.
  static Future<void> recordAyahRead(int surah, int ayah) async {
    final selectedRange = getSelectedJuzRange();
    if (selectedRange == null) return;
    if (isCompleted()) return;

    if (selectedRange.containsAyah(surah, ayah)) {
      final key = '$surah:$ayah';
      final readAyahs = _getReadAyahs();
      if (!readAyahs.contains(key)) {
        readAyahs.add(key);
        await _prefs?.setStringList(_readAyahsKey, readAyahs.toList());
      }
    }
  }

  static Set<String> _getReadAyahs() {
    final list = _prefs?.getStringList(_readAyahsKey) ?? [];
    return list.toSet();
  }

  /// Mark the current juz as manually completed.
  static Future<void> markCompleted() async {
    if (getSelectedJuz() != null) {
      await _prefs?.setBool(_completedKey, true);
    }
  }

  /// Check if the current juz has been marked as completed.
  static bool isCompleted() {
    return _prefs?.getBool(_completedKey) ?? false;
  }
}
