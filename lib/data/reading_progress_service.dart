import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_context.dart';
import 'local_data_recovery.dart';

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
    await _migrateLegacyKeys();
  }

  /// Migrate old single-progress keys to global + explore context.
  static Future<void> _migrateLegacyKeys() async {
    if (_prefs == null) return;
    final hasLegacy = LocalDataRecovery.containsKey(_prefs, _legacySurah);
    final hasGlobal = LocalDataRecovery.containsKey(_prefs, _globalSurah);

    if (hasLegacy && !hasGlobal) {
      final surah = LocalDataRecovery.getInt(_prefs, _legacySurah);
      final ayah = LocalDataRecovery.getInt(_prefs, _legacyAyah) ?? 1;
      if (surah == null || surah <= 0) {
        await LocalDataRecovery.clearPrefsKeys(
          _prefs,
          [_legacySurah, _legacyAyah],
        );
        return;
      }

      // Copy to global
      await _prefs!.setInt(_globalSurah, surah);
      await _prefs!.setInt(_globalAyah, ayah);

      // Copy to explore context
      const explore = ReadingContext.explore();
      await _prefs!.setInt(explore.surahKey, surah);
      await _prefs!.setInt(explore.ayahKey, ayah);

      // Remove legacy keys
      await _prefs!.remove(_legacySurah);
      await _prefs!.remove(_legacyAyah);
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
    return LocalDataRecovery.getInt(_prefs, _globalSurah);
  }

  /// Get global last-read ayah. Returns null if no history.
  static int? getGlobalLastAyah() {
    return LocalDataRecovery.getInt(_prefs, _globalAyah);
  }

  /// Returns true if any global reading history exists.
  static bool hasGlobalHistory() {
    return LocalDataRecovery.containsKey(_prefs, _globalSurah);
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

  /// Clear saved progress for a specific reading context.
  static Future<void> clearContextProgress(ReadingContext ctx) async {
    await _prefs?.remove(ctx.surahKey);
    await _prefs?.remove(ctx.ayahKey);
  }

  /// Get progress for a specific context. Returns null if none.
  static ({int surah, int ayah})? getContextProgress(ReadingContext ctx) {
    final surah = LocalDataRecovery.getInt(_prefs, ctx.surahKey);
    final ayah = LocalDataRecovery.getInt(_prefs, ctx.ayahKey) ?? 1;
    if (surah == null || surah <= 0) {
      if (LocalDataRecovery.containsKey(_prefs, ctx.surahKey)) {
        unawaited(
          LocalDataRecovery.clearPrefsKeys(_prefs, [ctx.surahKey, ctx.ayahKey]),
        );
      }
      return null;
    }
    return (surah: surah, ayah: ayah <= 0 ? 1 : ayah);
  }

  /// Returns the last ayah for [targetSurah] inside the given context.
  /// If context progress points to a different surah, returns null.
  static int? getLastAyahForContext(ReadingContext ctx, int targetSurah) {
    final progress = getContextProgress(ctx);
    if (progress == null || progress.surah != targetSurah) return null;
    return progress.ayah;
  }

  /// Returns true if a specific context has saved progress.
  static bool hasContextProgress(ReadingContext ctx) {
    return LocalDataRecovery.containsKey(_prefs, ctx.surahKey);
  }

  static Future<void> resetHatimProgress() async {
    await clearContextProgress(const ReadingContext.hatim());
  }

  static Future<void> resetJuzProgress(int juzNumber) async {
    await clearContextProgress(ReadingContext.juz(juzNumber));
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
