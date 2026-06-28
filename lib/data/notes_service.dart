import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'local_data_recovery.dart';
import 'secure_storage_service.dart';

/// Simple local notes service for personal reflections.
/// Fully private, no tracking, no sync.
class NotesService {
  static const _noteKey = 'personal_note';
  static const _lastEditedKey = 'note_last_edited';
  static const _dailyMoodTextKey = 'dailyMoodText';
  static const _dailyMoodDateKey = 'dailyMoodDate';
  static const _dailyReflectionIdKey = 'dailyReflectionId';

  static const _secureNoteKey = 'secure_personal_note';
  static const _secureDailyMoodTextKey = 'secure_daily_mood_text';

  static SharedPreferences? _prefs;
  static final ValueNotifier<String> noteNotifier = ValueNotifier<String>('');
  static final ValueNotifier<int> dailyMoodRevision = ValueNotifier<int>(0);

  static String _cachedNote = '';
  static String _cachedDailyMoodText = '';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _hydrateSensitiveValues();
    noteNotifier.value = getNote();
    _emitDailyMoodState();
  }

  static Future<void> _hydrateSensitiveValues() async {
    final secureNote = await SecureStorageService.readSafely(_secureNoteKey);
    final legacyNote = LocalDataRecovery.getString(_prefs, _noteKey);

    if ((secureNote == null || secureNote.isEmpty) &&
        legacyNote != null &&
        legacyNote.isNotEmpty) {
      await SecureStorageService.write(_secureNoteKey, legacyNote);
      _cachedNote = legacyNote;
    } else {
      _cachedNote = secureNote ?? '';
    }
    if (legacyNote != null) {
      await _prefs?.remove(_noteKey);
    }

    final secureDailyMoodText =
        await SecureStorageService.readSafely(_secureDailyMoodTextKey);
    final legacyDailyMoodText =
        LocalDataRecovery.getString(_prefs, _dailyMoodTextKey);

    if ((secureDailyMoodText == null || secureDailyMoodText.isEmpty) &&
        legacyDailyMoodText != null &&
        legacyDailyMoodText.isNotEmpty) {
      await SecureStorageService.write(
        _secureDailyMoodTextKey,
        legacyDailyMoodText,
      );
      _cachedDailyMoodText = legacyDailyMoodText;
    } else {
      _cachedDailyMoodText = secureDailyMoodText ?? '';
    }
    if (legacyDailyMoodText != null) {
      await _prefs?.remove(_dailyMoodTextKey);
    }
  }

  /// Get the current note content.
  static String getNote() {
    return _cachedNote;
  }

  /// Save note content (auto-save, no submit button).
  static Future<void> saveNote(String content) async {
    await SecureStorageService.write(_secureNoteKey, content);
    _cachedNote = content;
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
    final date = LocalDataRecovery.getString(_prefs, _dailyMoodDateKey);
    final text = _cachedDailyMoodText.trim();
    return date == _todayKey() && text.isNotEmpty;
  }

  static String getTodayMoodText() {
    if (!isDailyMoodLockedToday()) return '';
    return _cachedDailyMoodText;
  }

  static int? getTodayReflectionId() {
    if (!isDailyMoodLockedToday()) return null;
    return LocalDataRecovery.getInt(_prefs, _dailyReflectionIdKey);
  }

  static Future<bool> submitDailyMood({
    required String text,
    required int reflectionId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (isDailyMoodLockedToday()) return false;

    await _prefs?.setString(_dailyMoodDateKey, _todayKey());
    await SecureStorageService.write(_secureDailyMoodTextKey, trimmed);
    _cachedDailyMoodText = trimmed;
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
