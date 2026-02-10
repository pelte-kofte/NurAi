import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local preferences with ValueNotifiers for reactive UI.
class LocalPreferencesService {
  static const _keyAdhan = 'pref_adhan_enabled';
  static const _keyHaptics = 'pref_haptics_enabled';
  static const _keyTheme = 'pref_theme_mode';
  static const _keyLanguage = 'pref_language';

  static SharedPreferences? _prefs;

  /// Reactive notifiers — UI can listen without Provider/Bloc.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final adhanEnabled = ValueNotifier<bool>(false);
  static final hapticsEnabled = ValueNotifier<bool>(true);
  static final language = ValueNotifier<String>('tr');

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Hydrate notifiers from disk
    themeMode.value = _readThemeMode();
    adhanEnabled.value = _prefs?.getBool(_keyAdhan) ?? false;
    hapticsEnabled.value = _prefs?.getBool(_keyHaptics) ?? true;
    language.value = _prefs?.getString(_keyLanguage) ?? 'tr';
  }

  // ── Theme ──────────────────────────────────────────────

  static ThemeMode _readThemeMode() {
    final raw = _prefs?.getString(_keyTheme) ?? 'system';
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _prefs?.setString(_keyTheme, raw);
    themeMode.value = mode;
  }

  // ── Adhan ──────────────────────────────────────────────

  static Future<void> setAdhanEnabled(bool value) async {
    await _prefs?.setBool(_keyAdhan, value);
    adhanEnabled.value = value;
  }

  // ── Haptics ────────────────────────────────────────────

  static Future<void> setHapticsEnabled(bool value) async {
    await _prefs?.setBool(_keyHaptics, value);
    hapticsEnabled.value = value;
  }

  // ── Language ───────────────────────────────────────────

  static Future<void> setLanguage(String lang) async {
    await _prefs?.setString(_keyLanguage, lang);
    language.value = lang;
  }
}
