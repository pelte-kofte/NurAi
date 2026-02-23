import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prayer_location.dart';

class RamadanSuggestionSelection {
  const RamadanSuggestionSelection({
    required this.dateKey,
    required this.duaIndex,
    required this.ayetIndex,
    required this.iyilikIndex,
  });

  final String dateKey;
  final int duaIndex;
  final int ayetIndex;
  final int iyilikIndex;
}

/// Lightweight local preferences with ValueNotifiers for reactive UI.
class LocalPreferencesService {
  static const _keyAdhan = 'pref_adhan_enabled';
  static const _keyTheme = 'theme_mode';
  static const _legacyKeyTheme = 'pref_theme_mode';
  static const _legacyKeyHaptics = 'pref_haptics_enabled';
  static const _keyLanguage = 'pref_language';
  static const _keyPrayerLocation = 'pref_prayer_location';
  static const _keyPrayerLocationMode = 'prayer_location_mode';
  static const _keyPrayerLat = 'prayer_lat';
  static const _keyPrayerLng = 'prayer_lng';
  static const _keyPrayerCityName = 'prayer_city_name';
  static const _keyEzanAlarmSound = 'pref_ezan_alarm_sound_enabled';
  static const _keyIftarLiveActivity = 'pref_iftar_live_activity_enabled';
  static const _keyIftarPermissionPromptShown =
      'pref_iftar_permission_prompt_shown';
  static const _keyIftarLiveActivityTipSeen = 'iftar_live_activity_tip_seen';
  static const _keyRamadanSuggestionsDate = 'pref_ramadan_suggestions_date';
  static const _keyRamadanSuggestionsDuaIndex =
      'pref_ramadan_suggestions_dua_index';
  static const _keyRamadanSuggestionsAyetIndex =
      'pref_ramadan_suggestions_ayet_index';
  static const _keyRamadanSuggestionsIyilikIndex =
      'pref_ramadan_suggestions_iyilik_index';
  static const _keyRamadanSuggestionsFavorites =
      'pref_ramadan_suggestions_favorites';

  static SharedPreferences? _prefs;

  /// Reactive notifiers — UI can listen without Provider/Bloc.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final adhanEnabled = ValueNotifier<bool>(false);
  static final language = ValueNotifier<String>('tr');
  static final ezanAlarmSoundEnabled = ValueNotifier<bool>(false);
  static final iftarLiveActivityEnabled = ValueNotifier<bool>(false);
  static final iftarPermissionPromptShown = ValueNotifier<bool>(false);
  static final iftarLiveActivityTipSeen = ValueNotifier<bool>(false);
  static final prayerLocation = ValueNotifier<PrayerLocation>(
    PrayerLocation.initial(),
  );

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Hydrate notifiers from disk
    themeMode.value = _readThemeMode();
    adhanEnabled.value = _prefs?.getBool(_keyAdhan) ?? false;
    await _prefs?.remove(_legacyKeyHaptics);
    language.value = _prefs?.getString(_keyLanguage) ?? 'tr';
    ezanAlarmSoundEnabled.value = _prefs?.getBool(_keyEzanAlarmSound) ?? false;
    iftarLiveActivityEnabled.value =
        _prefs?.getBool(_keyIftarLiveActivity) ?? false;
    iftarPermissionPromptShown.value =
        _prefs?.getBool(_keyIftarPermissionPromptShown) ?? false;
    iftarLiveActivityTipSeen.value =
        _prefs?.getBool(_keyIftarLiveActivityTipSeen) ?? false;
    prayerLocation.value = _readPrayerLocation();
  }

  // ── Theme ──────────────────────────────────────────────

  static ThemeMode _readThemeMode() {
    final raw = _prefs?.getString(_keyTheme) ??
        _prefs?.getString(_legacyKeyTheme) ??
        'light';
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'light',
    };
    // Notify immediately so UI theme updates without waiting for disk I/O.
    themeMode.value = mode;
    await _prefs?.setString(_keyTheme, raw);
    await _prefs?.remove(_legacyKeyTheme);
  }

  // ── Adhan ──────────────────────────────────────────────

  static Future<void> setAdhanEnabled(bool value) async {
    await _prefs?.setBool(_keyAdhan, value);
    adhanEnabled.value = value;
  }

  static Future<void> setEzanAlarmSoundEnabled(bool value) async {
    await _prefs?.setBool(_keyEzanAlarmSound, value);
    ezanAlarmSoundEnabled.value = value;
  }

  // ── Language ───────────────────────────────────────────

  static Future<void> setLanguage(String lang) async {
    await _prefs?.setString(_keyLanguage, lang);
    language.value = lang;
  }

  static Future<void> setIftarLiveActivityEnabled(bool value) async {
    await _prefs?.setBool(_keyIftarLiveActivity, value);
    iftarLiveActivityEnabled.value = value;
  }

  static Future<void> setIftarPermissionPromptShown(bool value) async {
    await _prefs?.setBool(_keyIftarPermissionPromptShown, value);
    iftarPermissionPromptShown.value = value;
  }

  static Future<void> setIftarLiveActivityTipSeen(bool value) async {
    await _prefs?.setBool(_keyIftarLiveActivityTipSeen, value);
    iftarLiveActivityTipSeen.value = value;
  }

  // Prayer location
  static PrayerLocation _readPrayerLocation() {
    final raw = _prefs?.getString(_keyPrayerLocation);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return PrayerLocation.fromJson(json);
      } catch (_) {
        // Fall through to legacy keys.
      }
    }

    final modeRaw = _prefs?.getString(_keyPrayerLocationMode);
    final lat = _prefs?.getDouble(_keyPrayerLat);
    final lng = _prefs?.getDouble(_keyPrayerLng);
    final cityName = _prefs?.getString(_keyPrayerCityName);
    if (modeRaw == null && lat == null && lng == null && cityName == null) {
      return PrayerLocation.initial();
    }

    final mode = modeRaw == PrayerLocationMode.current.name
        ? PrayerLocationMode.current
        : PrayerLocationMode.city;
    return PrayerLocation(
      mode: mode,
      lat: lat,
      lng: lng,
      cityName: cityName,
      updatedAt: DateTime.now(),
    );
  }

  static Future<void> setPrayerLocation(PrayerLocation value) async {
    await _prefs?.setString(_keyPrayerLocation, jsonEncode(value.toJson()));
    await _prefs?.setString(_keyPrayerLocationMode, value.mode.name);
    if (value.lat != null) {
      await _prefs?.setDouble(_keyPrayerLat, value.lat!);
    } else {
      await _prefs?.remove(_keyPrayerLat);
    }
    if (value.lng != null) {
      await _prefs?.setDouble(_keyPrayerLng, value.lng!);
    } else {
      await _prefs?.remove(_keyPrayerLng);
    }
    if (value.cityName != null && value.cityName!.trim().isNotEmpty) {
      await _prefs?.setString(_keyPrayerCityName, value.cityName!.trim());
    } else {
      await _prefs?.remove(_keyPrayerCityName);
    }
    prayerLocation.value = value;
  }

  static RamadanSuggestionSelection? getRamadanSuggestionSelection() {
    final dateKey = _prefs?.getString(_keyRamadanSuggestionsDate);
    final duaIndex = _prefs?.getInt(_keyRamadanSuggestionsDuaIndex);
    final ayetIndex = _prefs?.getInt(_keyRamadanSuggestionsAyetIndex);
    final iyilikIndex = _prefs?.getInt(_keyRamadanSuggestionsIyilikIndex);
    if (dateKey == null ||
        duaIndex == null ||
        ayetIndex == null ||
        iyilikIndex == null) {
      return null;
    }
    return RamadanSuggestionSelection(
      dateKey: dateKey,
      duaIndex: duaIndex,
      ayetIndex: ayetIndex,
      iyilikIndex: iyilikIndex,
    );
  }

  static Future<void> setRamadanSuggestionSelection({
    required String dateKey,
    required int duaIndex,
    required int ayetIndex,
    required int iyilikIndex,
  }) async {
    await _prefs?.setString(_keyRamadanSuggestionsDate, dateKey);
    await _prefs?.setInt(_keyRamadanSuggestionsDuaIndex, duaIndex);
    await _prefs?.setInt(_keyRamadanSuggestionsAyetIndex, ayetIndex);
    await _prefs?.setInt(_keyRamadanSuggestionsIyilikIndex, iyilikIndex);
  }

  static String? getRamadanSuggestionFavoritesRaw() {
    return _prefs?.getString(_keyRamadanSuggestionsFavorites);
  }

  static Future<void> setRamadanSuggestionFavoritesRaw(String value) async {
    await _prefs?.setString(_keyRamadanSuggestionsFavorites, value);
  }
}
