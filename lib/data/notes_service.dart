import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Simple local notes service for personal reflections.
/// Fully private, no tracking, no sync.
class NotesService {
  static const _noteKey = 'personal_note';
  static const _lastEditedKey = 'note_last_edited';
  static const _dailyMoodTextKey = 'dailyMoodText';
  static const _dailyMoodDateKey = 'dailyMoodDate';
  static const _dailyReflectionIdKey = 'dailyReflectionId';

  static SharedPreferences? _prefs;
  static final ValueNotifier<String> noteNotifier = ValueNotifier<String>('');
  static final ValueNotifier<int> dailyMoodRevision = ValueNotifier<int>(0);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    noteNotifier.value = getNote();
    _emitDailyMoodState();
  }

  /// Get the current note content.
  static String getNote() {
    return _prefs?.getString(_noteKey) ?? '';
  }

  /// Save note content (auto-save, no submit button).
  static Future<void> saveNote(String content) async {
    await _prefs?.setString(_noteKey, content);
    await _prefs?.setString(_lastEditedKey, DateTime.now().toIso8601String());
    noteNotifier.value = content;
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static bool isDailyMoodLockedToday() {
    final date = _prefs?.getString(_dailyMoodDateKey);
    final text = (_prefs?.getString(_dailyMoodTextKey) ?? '').trim();
    return date == _todayKey() && text.isNotEmpty;
  }

  static String getTodayMoodText() {
    if (!isDailyMoodLockedToday()) return '';
    return _prefs?.getString(_dailyMoodTextKey) ?? '';
  }

  static int? getTodayReflectionId() {
    if (!isDailyMoodLockedToday()) return null;
    return _prefs?.getInt(_dailyReflectionIdKey);
  }

  static Future<bool> submitDailyMood({
    required String text,
    required int reflectionId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (isDailyMoodLockedToday()) return false;

    await _prefs?.setString(_dailyMoodDateKey, _todayKey());
    await _prefs?.setString(_dailyMoodTextKey, trimmed);
    await _prefs?.setInt(_dailyReflectionIdKey, reflectionId);
    _emitDailyMoodState();
    return true;
  }

  static void refreshDailyMoodState() {
    _emitDailyMoodState();
  }

  static void _emitDailyMoodState() {
    dailyMoodRevision.value = dailyMoodRevision.value + 1;
  }

  /// Check if user has written anything.
  static bool hasNote() {
    final note = getNote();
    return note.trim().isNotEmpty;
  }

  /// Get first line preview for home display.
  static String? getFirstLinePreview() {
    final note = getNote();
    if (note.trim().isEmpty) return null;

    final firstLine = note.split('\n').first.trim();
    if (firstLine.isEmpty) return null;

    // Truncate if too long
    if (firstLine.length > 40) {
      return '${firstLine.substring(0, 40)}...';
    }
    return firstLine;
  }
}
