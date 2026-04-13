import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_location.dart';
import 'secure_storage_service.dart';

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

enum SpiritualNotificationTime {
  morning,
  midday,
  night,
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
  static const _keyNextPrayerWidget = 'pref_next_prayer_widget_enabled';
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
  static const _keyTodayCardFavorites = 'pref_today_card_favorites';
  static const _keyAsmaFavorites = 'pref_asma_favorites';
  static const _keyHomeDailyRotationPrefix = 'pref_home_daily_rotation_';
  static const _keyHomeHadithRotationTr = 'pref_home_hadith_rotation_tr';
  static const _keyHomeHadithRotationEn = 'pref_home_hadith_rotation_en';
  static const _keyAppOpenCount = 'pref_app_open_count';
  static const _keyLastPremiumUpsellShownAt =
      'pref_last_premium_upsell_shown_at';
  static const _keyLastPremiumUpsellDismissedAt =
      'pref_last_premium_upsell_dismissed_at';
  static const _keySpiritualNotificationsEnabled =
      'pref_spiritual_notifications_enabled';
  static const _keySpiritualNotificationTimes =
      'pref_spiritual_notification_times';
  static const _keyMinimalMode = 'pref_minimal_mode';
  static const _keyNightCompanionReminderEnabled =
      'pref_night_companion_reminder_enabled';
  static const _keyNightCompanionReminderHour =
      'pref_night_companion_reminder_hour';
  static const _keyNightCompanionReminderMinute =
      'pref_night_companion_reminder_minute';
  static const _keyReadingReminderEnabled = 'pref_reading_reminder_enabled';
  static const _keyReadingReminderHour = 'pref_reading_reminder_hour';
  static const _keyReadingReminderMinute = 'pref_reading_reminder_minute';
  static const _keyCompanionFlowCompletedDate =
      'pref_companion_flow_completed_date';
  static const _keyCompanionFlowCompletionCount =
      'pref_companion_flow_completion_count';
  static const _keyCompanionFlowDhikrIndex = 'pref_companion_flow_dhikr_index';
  static const _keyCompanionFlowVerseIndex = 'pref_companion_flow_verse_index';
  static const _keyFeedbackPromptActiveDays =
      'pref_feedback_prompt_active_days';
  static const _keyFeedbackPromptLastActiveDate =
      'pref_feedback_prompt_last_active_date';
  static const _keyFeedbackPromptLastShownAt =
      'pref_feedback_prompt_last_shown_at';
  static const _keyFeedbackPromptCompleted = 'pref_feedback_prompt_completed';
  static const _keyFeedbackPromptRated = 'pref_feedback_prompt_rated';
  static const _releaseLanguages = <String>{'tr', 'en'};

  static const _secureKeyPrayerLat = 'secure_prayer_lat';
  static const _secureKeyPrayerLng = 'secure_prayer_lng';

  static SharedPreferences? _prefs;
  static bool premiumUpsellShownThisSession = false;

  /// Reactive notifiers - UI can listen without Provider/Bloc.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static final adhanEnabled = ValueNotifier<bool>(false);
  static final language = ValueNotifier<String>('tr');
  static final ezanAlarmSoundEnabled = ValueNotifier<bool>(false);
  static final iftarLiveActivityEnabled = ValueNotifier<bool>(false);
  static final nextPrayerWidgetEnabled = ValueNotifier<bool>(false);
  static final iftarPermissionPromptShown = ValueNotifier<bool>(false);
  static final iftarLiveActivityTipSeen = ValueNotifier<bool>(false);
  static final spiritualNotificationsEnabled = ValueNotifier<bool>(false);
  static final minimalModeEnabled = ValueNotifier<bool>(false);
  static final nightCompanionReminderEnabled = ValueNotifier<bool>(false);
  static final nightCompanionReminderTime =
      ValueNotifier<TimeOfDay>(const TimeOfDay(hour: 22, minute: 30));
  static final readingReminderEnabled = ValueNotifier<bool>(false);
  static final readingReminderTime =
      ValueNotifier<TimeOfDay>(const TimeOfDay(hour: 20, minute: 30));
  static final companionFlowCompletedToday = ValueNotifier<bool>(false);
  static final spiritualNotificationTimes =
      ValueNotifier<List<SpiritualNotificationTime>>(
    const [
      SpiritualNotificationTime.morning,
      SpiritualNotificationTime.night,
    ],
  );
  static final prayerLocation = ValueNotifier<PrayerLocation>(
    PrayerLocation.initial(),
  );

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Hydrate notifiers from disk
    themeMode.value = _readThemeMode();
    adhanEnabled.value = _prefs?.getBool(_keyAdhan) ?? false;
    await _prefs?.remove(_legacyKeyHaptics);
    final rawLanguage = _prefs?.getString(_keyLanguage) ?? 'tr';
    final normalizedLanguage = _normalizeReleaseLanguage(rawLanguage);
    language.value = normalizedLanguage;
    if (rawLanguage != normalizedLanguage) {
      await _prefs?.setString(_keyLanguage, normalizedLanguage);
    }
    ezanAlarmSoundEnabled.value = _prefs?.getBool(_keyEzanAlarmSound) ?? false;
    iftarLiveActivityEnabled.value =
        _prefs?.getBool(_keyIftarLiveActivity) ?? false;
    nextPrayerWidgetEnabled.value =
        _prefs?.getBool(_keyNextPrayerWidget) ?? false;
    iftarPermissionPromptShown.value =
        _prefs?.getBool(_keyIftarPermissionPromptShown) ?? false;
    iftarLiveActivityTipSeen.value =
        _prefs?.getBool(_keyIftarLiveActivityTipSeen) ?? false;
    spiritualNotificationsEnabled.value =
        _prefs?.getBool(_keySpiritualNotificationsEnabled) ?? false;
    minimalModeEnabled.value = _prefs?.getBool(_keyMinimalMode) ?? false;
    nightCompanionReminderEnabled.value =
        _prefs?.getBool(_keyNightCompanionReminderEnabled) ?? false;
    final reminderHour = _prefs?.getInt(_keyNightCompanionReminderHour) ?? 22;
    final reminderMinute =
        _prefs?.getInt(_keyNightCompanionReminderMinute) ?? 30;
    nightCompanionReminderTime.value = TimeOfDay(
      hour: reminderHour.clamp(0, 23),
      minute: reminderMinute.clamp(0, 59),
    );
    readingReminderEnabled.value =
        _prefs?.getBool(_keyReadingReminderEnabled) ?? false;
    final readingReminderHour = _prefs?.getInt(_keyReadingReminderHour) ?? 20;
    final readingReminderMinute =
        _prefs?.getInt(_keyReadingReminderMinute) ?? 30;
    readingReminderTime.value = TimeOfDay(
      hour: readingReminderHour.clamp(0, 23),
      minute: readingReminderMinute.clamp(0, 59),
    );
    companionFlowCompletedToday.value =
        _prefs?.getString(_keyCompanionFlowCompletedDate) == _todayDateKey();
    spiritualNotificationTimes.value = _readSpiritualNotificationTimes();
    prayerLocation.value = await _readPrayerLocation();
  }

  // Theme

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

  // Adhan

  static Future<void> setAdhanEnabled(bool value) async {
    await _prefs?.setBool(_keyAdhan, value);
    adhanEnabled.value = value;
  }

  static Future<void> setEzanAlarmSoundEnabled(bool value) async {
    await _prefs?.setBool(_keyEzanAlarmSound, value);
    ezanAlarmSoundEnabled.value = value;
  }

  // Language

  static Future<void> setLanguage(String lang) async {
    final normalized = _normalizeReleaseLanguage(lang);
    await _prefs?.setString(_keyLanguage, normalized);
    language.value = normalized;
  }

  static Future<void> setIftarLiveActivityEnabled(bool value) async {
    await _prefs?.setBool(_keyIftarLiveActivity, value);
    iftarLiveActivityEnabled.value = value;
  }

  static Future<void> setNextPrayerWidgetEnabled(bool value) async {
    await _prefs?.setBool(_keyNextPrayerWidget, value);
    nextPrayerWidgetEnabled.value = value;
  }

  static Future<void> setIftarPermissionPromptShown(bool value) async {
    await _prefs?.setBool(_keyIftarPermissionPromptShown, value);
    iftarPermissionPromptShown.value = value;
  }

  static Future<void> setIftarLiveActivityTipSeen(bool value) async {
    await _prefs?.setBool(_keyIftarLiveActivityTipSeen, value);
    iftarLiveActivityTipSeen.value = value;
  }

  static Future<void> setSpiritualNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_keySpiritualNotificationsEnabled, value);
    spiritualNotificationsEnabled.value = value;
  }

  static Future<void> setMinimalModeEnabled(bool value) async {
    await _prefs?.setBool(_keyMinimalMode, value);
    minimalModeEnabled.value = value;
  }

  static Future<void> setNightCompanionReminderEnabled(bool value) async {
    await _prefs?.setBool(_keyNightCompanionReminderEnabled, value);
    nightCompanionReminderEnabled.value = value;
  }

  static Future<void> setNightCompanionReminderTime(TimeOfDay value) async {
    await _prefs?.setInt(_keyNightCompanionReminderHour, value.hour);
    await _prefs?.setInt(_keyNightCompanionReminderMinute, value.minute);
    nightCompanionReminderTime.value = value;
  }

  static Future<void> setReadingReminderEnabled(bool value) async {
    await _prefs?.setBool(_keyReadingReminderEnabled, value);
    readingReminderEnabled.value = value;
  }

  static Future<void> setReadingReminderTime(TimeOfDay value) async {
    await _prefs?.setInt(_keyReadingReminderHour, value.hour);
    await _prefs?.setInt(_keyReadingReminderMinute, value.minute);
    readingReminderTime.value = value;
  }

  static Future<void> markCompanionFlowCompletedToday() async {
    final todayKey = _todayDateKey();
    await _prefs?.setString(_keyCompanionFlowCompletedDate, todayKey);
    await _prefs?.setInt(
      _keyCompanionFlowCompletionCount,
      companionFlowCompletionCount + 1,
    );
    companionFlowCompletedToday.value = true;
  }

  static Future<int> nextCompanionFlowDhikrIndex({
    int totalCount = 3,
  }) async {
    final safeTotal = totalCount <= 0 ? 1 : totalCount;
    final lastIndex = _prefs?.getInt(_keyCompanionFlowDhikrIndex) ?? -1;
    final nextIndex = (lastIndex + 1) % safeTotal;
    await _prefs?.setInt(_keyCompanionFlowDhikrIndex, nextIndex);
    return nextIndex;
  }

  static Future<int> nextCompanionFlowVerseIndex({
    int totalCount = 10,
  }) async {
    final safeTotal = totalCount <= 0 ? 1 : totalCount;
    final lastIndex = _prefs?.getInt(_keyCompanionFlowVerseIndex) ?? -1;
    final nextIndex = (lastIndex + 1) % safeTotal;
    await _prefs?.setInt(_keyCompanionFlowVerseIndex, nextIndex);
    return nextIndex;
  }

  static Future<void> setSpiritualNotificationTimes(
    List<SpiritualNotificationTime> values,
  ) async {
    final normalized = _normalizeSpiritualNotificationTimes(values);
    await _prefs?.setStringList(
      _keySpiritualNotificationTimes,
      normalized.map((item) => item.name).toList(growable: false),
    );
    spiritualNotificationTimes.value = normalized;
  }

  // Prayer location
  static Future<PrayerLocation> _readPrayerLocation() async {
    PrayerLocation? decoded;
    final raw = _prefs?.getString(_keyPrayerLocation);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        decoded = PrayerLocation.fromJson(json);
      } catch (_) {
        // Fall through to legacy keys.
      }
    }

    double? secureLat = _parseDouble(
      await SecureStorageService.read(_secureKeyPrayerLat),
    );
    double? secureLng = _parseDouble(
      await SecureStorageService.read(_secureKeyPrayerLng),
    );

    var migratedFromLegacy = false;

    final decodedLat = decoded?.lat;
    final decodedLng = decoded?.lng;
    if ((secureLat == null || secureLng == null) &&
        decodedLat != null &&
        decodedLng != null) {
      secureLat = decodedLat;
      secureLng = decodedLng;
      migratedFromLegacy = true;
    }

    final legacyLat = _prefs?.getDouble(_keyPrayerLat);
    final legacyLng = _prefs?.getDouble(_keyPrayerLng);
    if ((secureLat == null || secureLng == null) &&
        legacyLat != null &&
        legacyLng != null) {
      secureLat = legacyLat;
      secureLng = legacyLng;
      migratedFromLegacy = true;
    }

    final normalizedCoords = _normalizeCoordinates(secureLat, secureLng);
    secureLat = normalizedCoords.$1;
    secureLng = normalizedCoords.$2;

    if (secureLat != null && secureLng != null && migratedFromLegacy) {
      await SecureStorageService.write(
          _secureKeyPrayerLat, secureLat.toString());
      await SecureStorageService.write(
          _secureKeyPrayerLng, secureLng.toString());
    }

    await _prefs?.remove(_keyPrayerLat);
    await _prefs?.remove(_keyPrayerLng);

    if (decoded != null) {
      if (decoded.lat != null || decoded.lng != null) {
        final sanitizedMap = Map<String, dynamic>.from(decoded.toJson())
          ..['lat'] = null
          ..['lng'] = null;
        await _prefs?.setString(_keyPrayerLocation, jsonEncode(sanitizedMap));
      }
      return PrayerLocation(
        mode: decoded.mode,
        lat: secureLat,
        lng: secureLng,
        cityName: decoded.cityName,
        cityId: decoded.cityId,
        timezone: decoded.timezone,
        updatedAt: decoded.updatedAt,
      );
    }

    final modeRaw = _prefs?.getString(_keyPrayerLocationMode);
    final cityName = _prefs?.getString(_keyPrayerCityName);
    if (modeRaw == null &&
        cityName == null &&
        secureLat == null &&
        secureLng == null) {
      return PrayerLocation.initial();
    }

    final mode = modeRaw == PrayerLocationMode.current.name
        ? PrayerLocationMode.current
        : PrayerLocationMode.city;
    return PrayerLocation(
      mode: mode,
      lat: secureLat,
      lng: secureLng,
      cityName: cityName,
      updatedAt: DateTime.now(),
    );
  }

  static Future<void> setPrayerLocation(PrayerLocation value) async {
    final normalizedCoords = _normalizeCoordinates(value.lat, value.lng);
    final lat = normalizedCoords.$1;
    final lng = normalizedCoords.$2;

    if (lat != null && lng != null) {
      await SecureStorageService.write(_secureKeyPrayerLat, lat.toString());
      await SecureStorageService.write(_secureKeyPrayerLng, lng.toString());
    } else {
      await SecureStorageService.delete(_secureKeyPrayerLat);
      await SecureStorageService.delete(_secureKeyPrayerLng);
    }

    final sanitizedMap = Map<String, dynamic>.from(value.toJson())
      ..['lat'] = null
      ..['lng'] = null;
    await _prefs?.setString(_keyPrayerLocation, jsonEncode(sanitizedMap));

    await _prefs?.setString(_keyPrayerLocationMode, value.mode.name);
    await _prefs?.remove(_keyPrayerLat);
    await _prefs?.remove(_keyPrayerLng);

    if (value.cityName != null && value.cityName!.trim().isNotEmpty) {
      await _prefs?.setString(_keyPrayerCityName, value.cityName!.trim());
    } else {
      await _prefs?.remove(_keyPrayerCityName);
    }

    prayerLocation.value = PrayerLocation(
      mode: value.mode,
      lat: lat,
      lng: lng,
      cityName: value.cityName,
      cityId: value.cityId,
      timezone: value.timezone,
      updatedAt: value.updatedAt,
    );
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

  static String? getTodayCardFavoritesRaw() {
    return _prefs?.getString(_keyTodayCardFavorites);
  }

  static Future<void> setTodayCardFavoritesRaw(String value) async {
    await _prefs?.setString(_keyTodayCardFavorites, value);
  }

  static String? getAsmaFavoritesRaw() {
    return _prefs?.getString(_keyAsmaFavorites);
  }

  static Future<void> setAsmaFavoritesRaw(String value) async {
    await _prefs?.setString(_keyAsmaFavorites, value);
  }

  static String? getHomeDailyRotationStateRaw(String rotationKey) {
    return _prefs?.getString('$_keyHomeDailyRotationPrefix$rotationKey');
  }

  static Future<void> setHomeDailyRotationStateRaw(
    String rotationKey,
    String value,
  ) async {
    await _prefs?.setString('$_keyHomeDailyRotationPrefix$rotationKey', value);
  }

  static String? getHadithRotationStateRaw(String languageCode) {
    final key = switch (languageCode.toLowerCase()) {
      'tr' => _keyHomeHadithRotationTr,
      _ => _keyHomeHadithRotationEn,
    };
    return _prefs?.getString(key);
  }

  static Future<void> setHadithRotationStateRaw(
    String languageCode,
    String value,
  ) async {
    final key = switch (languageCode.toLowerCase()) {
      'tr' => _keyHomeHadithRotationTr,
      _ => _keyHomeHadithRotationEn,
    };
    await _prefs?.setString(key, value);
  }

  static int get appOpenCount => _prefs?.getInt(_keyAppOpenCount) ?? 0;

  static int get companionFlowCompletionCount =>
      _prefs?.getInt(_keyCompanionFlowCompletionCount) ?? 0;

  static int get feedbackPromptActiveDays =>
      _prefs?.getInt(_keyFeedbackPromptActiveDays) ?? 0;

  static DateTime? get lastFeedbackPromptShownAt =>
      _readDateTime(_keyFeedbackPromptLastShownAt);

  static bool get feedbackPromptCompleted =>
      _prefs?.getBool(_keyFeedbackPromptCompleted) ?? false;

  static bool get feedbackPromptRated =>
      _prefs?.getBool(_keyFeedbackPromptRated) ?? false;

  static Future<int> incrementAppOpenCount() async {
    final nextValue = appOpenCount + 1;
    await _prefs?.setInt(_keyAppOpenCount, nextValue);
    await _recordFeedbackPromptActiveDayIfNeeded();
    premiumUpsellShownThisSession = false;
    return nextValue;
  }

  static Future<void> markFeedbackPromptShown([DateTime? shownAt]) async {
    final value = (shownAt ?? DateTime.now()).toIso8601String();
    await _prefs?.setString(_keyFeedbackPromptLastShownAt, value);
  }

  static Future<void> markFeedbackPromptCompleted() async {
    await _prefs?.setBool(_keyFeedbackPromptCompleted, true);
  }

  static Future<void> markFeedbackPromptRated() async {
    await _prefs?.setBool(_keyFeedbackPromptRated, true);
    await markFeedbackPromptCompleted();
  }

  static DateTime? get lastPremiumUpsellShownAt =>
      _readDateTime(_keyLastPremiumUpsellShownAt);

  static DateTime? get lastPremiumUpsellDismissedAt =>
      _readDateTime(_keyLastPremiumUpsellDismissedAt);

  static Future<void> setLastPremiumUpsellShownAt(DateTime value) async {
    await _prefs?.setString(
      _keyLastPremiumUpsellShownAt,
      value.toIso8601String(),
    );
    premiumUpsellShownThisSession = true;
  }

  static Future<void> setLastPremiumUpsellDismissedAt(DateTime? value) async {
    if (value == null) {
      await _prefs?.remove(_keyLastPremiumUpsellDismissedAt);
      return;
    }
    await _prefs?.setString(
      _keyLastPremiumUpsellDismissedAt,
      value.toIso8601String(),
    );
  }

  static void markPremiumUpsellShownThisSession() {
    premiumUpsellShownThisSession = true;
  }

  static (double?, double?) _normalizeCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return (null, null);
    return (lat, lng);
  }

  static double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value);
  }

  static DateTime? _readDateTime(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _normalizeReleaseLanguage(String lang) {
    final normalized = lang.toLowerCase();
    if (_releaseLanguages.contains(normalized)) return normalized;
    return 'en';
  }

  static List<SpiritualNotificationTime> _readSpiritualNotificationTimes() {
    final raw = _prefs?.getStringList(_keySpiritualNotificationTimes);
    if (raw == null || raw.isEmpty) {
      return const [
        SpiritualNotificationTime.morning,
        SpiritualNotificationTime.night,
      ];
    }
    return _normalizeSpiritualNotificationTimes(
      raw
          .map((value) {
            for (final item in SpiritualNotificationTime.values) {
              if (item.name == value) return item;
            }
            return null;
          })
          .whereType<SpiritualNotificationTime>()
          .toList(growable: false),
    );
  }

  static List<SpiritualNotificationTime> _normalizeSpiritualNotificationTimes(
    List<SpiritualNotificationTime> values,
  ) {
    final deduped = <SpiritualNotificationTime>{...values};
    final ordered = SpiritualNotificationTime.values
        .where(deduped.contains)
        .toList(growable: false);
    if (ordered.isNotEmpty) return ordered;
    return const [
      SpiritualNotificationTime.morning,
      SpiritualNotificationTime.night,
    ];
  }

  static String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _recordFeedbackPromptActiveDayIfNeeded() async {
    final todayKey = _todayDateKey();
    final lastActiveDate = _prefs?.getString(_keyFeedbackPromptLastActiveDate);
    if (lastActiveDate == todayKey) return;
    await _prefs?.setString(_keyFeedbackPromptLastActiveDate, todayKey);
    final nextCount = feedbackPromptActiveDays + 1;
    await _prefs?.setInt(_keyFeedbackPromptActiveDays, nextCount);
  }
}
