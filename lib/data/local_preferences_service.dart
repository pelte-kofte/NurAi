import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prayer_location.dart';

/// Lightweight local preferences with ValueNotifiers for reactive UI.
class LocalPreferencesService {
  static const _keyAdhan = 'pref_adhan_enabled';
  static const _keyHaptics = 'pref_haptics_enabled';
  static const _keyTheme = 'theme_mode';
  static const _legacyKeyTheme = 'pref_theme_mode';
  static const _keyLanguage = 'pref_language';
  static const _keyPrayerLocation = 'pref_prayer_location';
  static const _keyPrayerLocationMode = 'prayer_location_mode';
  static const _keyPrayerLat = 'prayer_lat';
  static const _keyPrayerLng = 'prayer_lng';
  static const _keyPrayerCityName = 'prayer_city_name';
  static const _keyIftarLiveActivity = 'pref_iftar_live_activity_enabled';
  static const _keyIftarLiveActivityTipSeen = 'iftar_live_activity_tip_seen';

  static SharedPreferences? _prefs;

  /// Reactive notifiers — UI can listen without Provider/Bloc.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final adhanEnabled = ValueNotifier<bool>(false);
  static final hapticsEnabled = ValueNotifier<bool>(true);
  static final language = ValueNotifier<String>('tr');
  static final iftarLiveActivityEnabled = ValueNotifier<bool>(false);
  static final iftarLiveActivityTipSeen = ValueNotifier<bool>(false);
  static final prayerLocation = ValueNotifier<PrayerLocation>(
    PrayerLocation.initial(),
  );

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Hydrate notifiers from disk
    themeMode.value = _readThemeMode();
    adhanEnabled.value = _prefs?.getBool(_keyAdhan) ?? false;
    hapticsEnabled.value = _prefs?.getBool(_keyHaptics) ?? true;
    language.value = _prefs?.getString(_keyLanguage) ?? 'tr';
    iftarLiveActivityEnabled.value =
        _prefs?.getBool(_keyIftarLiveActivity) ?? false;
    iftarLiveActivityTipSeen.value =
        _prefs?.getBool(_keyIftarLiveActivityTipSeen) ?? false;
    prayerLocation.value = _readPrayerLocation();
  }

  // ── Theme ──────────────────────────────────────────────

  static ThemeMode _readThemeMode() {
    final raw = _prefs?.getString(_keyTheme) ??
        _prefs?.getString(_legacyKeyTheme) ??
        'system';
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
    await _prefs?.remove(_legacyKeyTheme);
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

  static Future<void> setIftarLiveActivityEnabled(bool value) async {
    await _prefs?.setBool(_keyIftarLiveActivity, value);
    iftarLiveActivityEnabled.value = value;
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
}
