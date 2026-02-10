import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_context.dart';

/// Stores and retrieves reading progress locally.
/// Supports multiple reading contexts (explore, hatim, juz)
/// plus a global "last touched" position.
class ReadingProgressService {
  // Legacy keys (pre-context era)
  static const _legacySurah = 'last_read_surah';
  static const _legacyAyah = 'last_read_ayah';

  // Global last-touched keys
  static const _globalSurah = 'last_read_global_surah';
  static const _globalAyah = 'last_read_global_ayah';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences and migrate legacy data.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _migrateLegacyKeys();
  }

  /// Migrate old single-progress keys to global + explore context.
  static void _migrateLegacyKeys() {
    if (_prefs == null) return;
    final hasLegacy = _prefs!.containsKey(_legacySurah);
    final hasGlobal = _prefs!.containsKey(_globalSurah);

    if (hasLegacy && !hasGlobal) {
      final surah = _prefs!.getInt(_legacySurah)!;
      final ayah = _prefs!.getInt(_legacyAyah) ?? 1;

      // Copy to global
      _prefs!.setInt(_globalSurah, surah);
      _prefs!.setInt(_globalAyah, ayah);

      // Copy to explore context
      const explore = ReadingContext.explore();
      _prefs!.setInt(explore.surahKey, surah);
      _prefs!.setInt(explore.ayahKey, ayah);

      // Remove legacy keys
      _prefs!.remove(_legacySurah);
      _prefs!.remove(_legacyAyah);
    }
  }

  // ── Global last-touched ──────────────────────────────────

  /// Save the global last-touched position (updated on every tap).
  static Future<void> saveGlobalLastRead(int surah, int ayah) async {
    await _prefs?.setInt(_globalSurah, surah);
    await _prefs?.setInt(_globalAyah, ayah);
  }

  /// Get global last-read surah. Returns null if no history.
  static int? getGlobalLastSurah() {
    return _prefs?.getInt(_globalSurah);
  }

  /// Get global last-read ayah. Returns null if no history.
  static int? getGlobalLastAyah() {
    return _prefs?.getInt(_globalAyah);
  }

  /// Returns true if any global reading history exists.
  static bool hasGlobalHistory() {
    return _prefs?.containsKey(_globalSurah) ?? false;
  }

  // ── Context-specific progress ────────────────────────────

  /// Save progress for a specific reading context.
  static Future<void> saveContextProgress(
    ReadingContext ctx,
    int surah,
    int ayah,
  ) async {
    await _prefs?.setInt(ctx.surahKey, surah);
    await _prefs?.setInt(ctx.ayahKey, ayah);
  }

  /// Get progress for a specific context. Returns null if none.
  static ({int surah, int ayah})? getContextProgress(ReadingContext ctx) {
    final surah = _prefs?.getInt(ctx.surahKey);
    final ayah = _prefs?.getInt(ctx.ayahKey);
    if (surah == null) return null;
    return (surah: surah, ayah: ayah ?? 1);
  }

  /// Returns true if a specific context has saved progress.
  static bool hasContextProgress(ReadingContext ctx) {
    return _prefs?.containsKey(ctx.surahKey) ?? false;
  }

  // ── Legacy compat (used by older callers during transition) ──

  /// @deprecated Use saveGlobalLastRead + saveContextProgress instead.
  static Future<void> saveProgress(int surahNumber, int ayahNumber) async {
    await saveGlobalLastRead(surahNumber, ayahNumber);
    await saveContextProgress(
      const ReadingContext.explore(),
      surahNumber,
      ayahNumber,
    );
  }

  /// @deprecated Use getGlobalLastSurah instead.
  static int getLastSurah() {
    return getGlobalLastSurah() ?? 1;
  }

  /// @deprecated Use getGlobalLastAyah instead.
  static int getLastAyah() {
    return getGlobalLastAyah() ?? 1;
  }

  /// @deprecated Use hasGlobalHistory instead.
  static bool hasHistory() {
    return hasGlobalHistory();
  }
}
