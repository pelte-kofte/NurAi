import 'package:shared_preferences/shared_preferences.dart';

/// Manages ayah bookmarks locally using SharedPreferences.
/// Bookmarks are stored as "surah:ayah" keys.
class BookmarkService {
  static const _prefix = 'bookmark_';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Creates a unique key for a surah:ayah pair.
  static String _key(int surah, int ayah) => '$_prefix${surah}_$ayah';

  /// Saves a bookmark.
  static Future<void> save(int surah, int ayah) async {
    await _prefs?.setBool(_key(surah, ayah), true);
  }

  /// Removes a bookmark.
  static Future<void> remove(int surah, int ayah) async {
    await _prefs?.remove(_key(surah, ayah));
  }

  /// Toggles bookmark state. Returns new state.
  static Future<bool> toggle(int surah, int ayah) async {
    if (isBookmarked(surah, ayah)) {
      await remove(surah, ayah);
      return false;
    } else {
      await save(surah, ayah);
      return true;
    }
  }

  /// Checks if an ayah is bookmarked.
  static bool isBookmarked(int surah, int ayah) {
    return _prefs?.getBool(_key(surah, ayah)) ?? false;
  }

  /// Returns all bookmarked ayahs as list of (surah, ayah) pairs.
  static List<(int, int)> getAllBookmarks() {
    final keys = _prefs?.getKeys() ?? {};
    final bookmarks = <(int, int)>[];

    for (final key in keys) {
      if (key.startsWith(_prefix)) {
        final parts = key.substring(_prefix.length).split('_');
        if (parts.length == 2) {
          final surah = int.tryParse(parts[0]);
          final ayah = int.tryParse(parts[1]);
          if (surah != null && ayah != null) {
            bookmarks.add((surah, ayah));
          }
        }
      }
    }

    return bookmarks;
  }
}
