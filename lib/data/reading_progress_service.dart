import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves reading progress locally.
/// No gamification — just quiet continuity.
class ReadingProgressService {
  static const _keySurah = 'last_read_surah';
  static const _keyAyah = 'last_read_ayah';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences. Call once at app startup.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves the last read position.
  static Future<void> saveProgress(int surahNumber, int ayahNumber) async {
    await _prefs?.setInt(_keySurah, surahNumber);
    await _prefs?.setInt(_keyAyah, ayahNumber);
  }

  /// Returns the last read surah number.
  /// Defaults to 1 (Al-Fatiha) if no history.
  static int getLastSurah() {
    return _prefs?.getInt(_keySurah) ?? 1;
  }

  /// Returns the last read ayah number.
  /// Defaults to 1 if no history.
  static int getLastAyah() {
    return _prefs?.getInt(_keyAyah) ?? 1;
  }

  /// Returns true if user has reading history.
  static bool hasHistory() {
    return _prefs?.containsKey(_keySurah) ?? false;
  }

  /// Clears reading history (if needed for testing).
  static Future<void> clearHistory() async {
    await _prefs?.remove(_keySurah);
    await _prefs?.remove(_keyAyah);
  }
}
