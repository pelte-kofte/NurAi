import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_data_recovery.dart';

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
  static const _completedJuzsKey = 'collective_completed_juzs';
  static const _legacyCompletedKey = 'collective_completed';

  static SharedPreferences? _prefs;
  static List<JuzRange> _juzRanges = [];

  /// Initialize the service. Must be called before use.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyCompletionIfNeeded();
    await _loadJuzRanges();
  }

  static Future<void> _migrateLegacyCompletionIfNeeded() async {
    final legacyCompleted =
        LocalDataRecovery.getBool(_prefs, _legacyCompletedKey);
    final selectedJuz = LocalDataRecovery.getInt(_prefs, _selectedJuzKey);
    if (!legacyCompleted || selectedJuz == null) {
      await _prefs?.remove(_legacyCompletedKey);
      return;
    }

    final completed = getCompletedJuzs().toSet();
    completed.add(selectedJuz);
    await _prefs?.setStringList(
      _completedJuzsKey,
      completed.map((juz) => '$juz').toList(growable: false),
    );
    await _prefs?.remove(_legacyCompletedKey);
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
    final value = LocalDataRecovery.getInt(_prefs, _selectedJuzKey);
    return value;
  }

  /// Select a juz for collective reading intention.
  static Future<void> selectJuz(int juzNumber) async {
    await _prefs?.setInt(_selectedJuzKey, juzNumber);
    // Clear previous read ayahs for the newly selected active juz.
    await _prefs?.remove(_readAyahsKey);
  }

  /// Clear the current juz selection.
  static Future<void> clearSelection() async {
    await _prefs?.remove(_selectedJuzKey);
    await _prefs?.remove(_readAyahsKey);
  }

  /// Check if there's an active juz selection.
  static bool hasActiveSelection() {
    return getSelectedJuz() != null && !isCompleted();
  }

  static List<int> getCompletedJuzs() {
    final raw = LocalDataRecovery.getStringList(
          _prefs,
          _completedJuzsKey,
          fallback: const <String>[],
        ) ??
        const <String>[];
    final values = raw
        .map(int.tryParse)
        .whereType<int>()
        .where((value) => value >= 1 && value <= 30)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  /// Get the JuzRange for the selected juz.
  static JuzRange? getSelectedJuzRange() {
    final juzNumber = getSelectedJuz();
    if (juzNumber == null) return null;
    return getJuzRange(juzNumber);
  }

  /// Get a JuzRange by juz number. Returns null if not found.
  static JuzRange? getJuzRange(int juzNumber) {
    if (_juzRanges.isEmpty) return null;
    for (final r in _juzRanges) {
      if (r.juzNumber == juzNumber) return r;
    }
    return null;
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
    final list = LocalDataRecovery.getStringList(
          _prefs,
          _readAyahsKey,
          fallback: const <String>[],
        ) ??
        const <String>[];
    return list.toSet();
  }

  /// Mark the current juz as manually completed.
  static Future<void> markCompleted() async {
    final selectedJuz = getSelectedJuz();
    if (selectedJuz == null) return;

    final completed = getCompletedJuzs().toSet();
    completed.add(selectedJuz);
    await _prefs?.setStringList(
      _completedJuzsKey,
      completed.map((juz) => '$juz').toList(growable: false),
    );
  }

  static Future<void> undoCompleted([int? juzNumber]) async {
    final targetJuz = juzNumber ?? getSelectedJuz();
    if (targetJuz == null) return;

    final completed = getCompletedJuzs().toSet()..remove(targetJuz);
    await _prefs?.setStringList(
      _completedJuzsKey,
      completed.map((juz) => '$juz').toList(growable: false),
    );
  }

  static Future<void> resetSelectedJuzProgress([int? juzNumber]) async {
    final targetJuz = juzNumber ?? getSelectedJuz();
    if (targetJuz == null) return;

    await undoCompleted(targetJuz);
    if (getSelectedJuz() == targetJuz) {
      await _prefs?.remove(_readAyahsKey);
    }
  }

  /// Check if the current juz has been marked as completed.
  static bool isCompleted([int? juzNumber]) {
    final targetJuz = juzNumber ?? getSelectedJuz();
    if (targetJuz == null) return false;
    return getCompletedJuzs().contains(targetJuz);
  }
}
