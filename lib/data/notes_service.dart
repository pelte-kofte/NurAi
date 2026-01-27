import 'package:shared_preferences/shared_preferences.dart';

/// Simple local notes service for personal reflections.
/// Fully private, no tracking, no sync.
class NotesService {
  static const _noteKey = 'personal_note';
  static const _lastEditedKey = 'note_last_edited';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the current note content.
  static String getNote() {
    return _prefs?.getString(_noteKey) ?? '';
  }

  /// Save note content (auto-save, no submit button).
  static Future<void> saveNote(String content) async {
    await _prefs?.setString(_noteKey, content);
    await _prefs?.setString(_lastEditedKey, DateTime.now().toIso8601String());
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
