import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../core/config/seasonal_config.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';
import '../models/reading_context.dart';
import 'adhan_times_service.dart';
import 'collective_reading_service.dart';
import 'daily_ayah_service.dart';
import 'daily_content_service.dart';
import 'local_preferences_service.dart';
import 'prayer_location_service.dart';
import 'quran_data.dart';
import 'reading_progress_service.dart';
import 'widget_payload_service.dart';

@pragma('vm:entry-point')
void adhanNotificationTapBackground(NotificationResponse response) {
  if (kDebugMode) {
    debugPrint(
      '[AdhanNotifications] background_notification_response payload=${_redactPayload(response.payload)} actionId=${response.actionId ?? 'none'}',
    );
  }
  AdhanNotificationService.handleNotificationResponsePayload(response.payload);
}

String _redactPayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) return 'none';
  final type = AdhanNotificationService.notificationPayloadType(payload);
  switch (type) {
    case 'iftar_live_activity_warmup':
    case AdhanNotificationService.iftarWarmupStartLiveActivityType:
      return AdhanNotificationService.iftarWarmupStartLiveActivityType;
    case 'iftar_alarm_fired':
      return 'iftar_alarm_fired';
    case 'iftar_post_cleanup':
      return 'iftar_post_cleanup';
    default:
      return 'redacted';
  }
}

enum AdhanEnableResult {
  enabled,
  unavailableOnWeb,
  notificationPermissionDenied,
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationMissing,
  locationFailed,
}

String buildAdhanNotificationBody(
  String prayerName,
  String time, {
  String? optionalReminder,
  String? cityName,
}) {
  final resolvedCity = cityName ?? S.get('prayer_times_subtitle_current');
  final base = S
      .get('prayer_notif_body')
      .replaceAll('{prayerName}', prayerName)
      .replaceAll('{cityName}', resolvedCity)
      .replaceAll('{time}', time);

  if (optionalReminder == null || optionalReminder.trim().isEmpty) {
    return base;
  }
  return '$base\n${S.get('daily_word_title')}: ${optionalReminder.trim()}';
}

class AdhanNotificationService {
  AdhanNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _maintenanceTimer;
  static const _prayerIndexes = <int>[0, 1, 2, 3, 4];
  static const _prayerChannelIdNormal = 'prayer_times';
  static const _prayerChannelNameNormal = 'Prayer Times';
  static const _prayerChannelIdAlarm = 'adhan_channel_v3';
  static const _prayerChannelNameAlarm = 'Prayer Times Alarm';
  static const _iftarChannelIdAlarm = 'iftar_alarm_v3';
  static const _iftarChannelNameAlarm = 'Iftar Alarm';
  static const _spiritualChannelId = 'spiritual_daily_content';
  static const _spiritualChannelName = 'Spiritual Daily Content';
  static const _nightRitualChannelId = 'night_companion_ritual';
  static const _nightRitualChannelName = 'Night Companion Ritual';
  static const _readingReminderChannelId = 'reading_continuation';
  static const _readingReminderChannelName = 'Reading Continuation';
  static const String spiritualMorningType = 'spiritual_morning';
  static const String spiritualMiddayType = 'spiritual_midday';
  static const String spiritualNightType = 'spiritual_night';
  static const String nightCompanionReminderType = 'night_companion_ritual';
  static const String readingReminderType = 'reading_continuation';
  static const _azanSound = RawResourceAndroidNotificationSound('azan');
  // On iOS, custom notification sounds must use the bundled file name
  // including its extension. Prefer a PCM/LPCM CAF comfortably under 30s.
  static const _iosAzanSoundFile = 'azan.caf';
  static const _iftarWarmupOffset = Duration(hours: 1);
  static const _legacyIftarWarmupPayload = 'iftar_live_activity_warmup';
  static const String iftarWarmupStartLiveActivityType =
      'iftar_warmup_start_live_activity';
  static const String morningReminderType = 'daily_morning_reflection';
  static const String eveningReminderType = 'daily_evening_reflection';
  static const _iftarAlarmPayload = 'iftar_alarm_fired';
  static const _iftarPostCleanupPayload = 'iftar_post_cleanup';
  static final lastNotificationTapPayload = ValueNotifier<String?>(null);
  static Future<void> Function(String? payload)? _notificationTapHandler;
  static bool? _lastIosAlertPermissionEnabled;
  static bool? _lastIosBadgePermissionEnabled;
  static bool? _lastIosSoundPermissionEnabled;
  static bool _spiritualListenersAttached = false;
  static bool _readingReminderListenersAttached = false;
  static Future<void> _scheduleQueue = Future<void>.value();

  static void setNotificationTapHandler(
    Future<void> Function(String? payload)? handler,
  ) {
    _notificationTapHandler = handler;
  }

  static bool get isIosSoundPermissionGranted =>
      _lastIosSoundPermissionEnabled ?? false;

  static String? notificationPayloadType(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    final trimmed = payload.trim();
    if (!trimmed.startsWith('{')) return trimmed;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type'];
        if (type is String && type.trim().isNotEmpty) {
          return type.trim();
        }
      }
    } catch (_) {
      return trimmed;
    }
    return trimmed;
  }

  static int? notificationPayloadIftarEpochMs(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    final trimmed = payload.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['iftarEpochMs'];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? notificationPayloadTimeZone(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    final trimmed = payload.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['timeZone'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    await _setTimezoneFromDeviceOrFallback();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        _log(
          'notification_response payload=${_redactPayload(response.payload)} actionId=${response.actionId ?? 'none'}',
        );
        handleNotificationResponsePayload(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          adhanNotificationTapBackground,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      handleNotificationResponsePayload(
        launchDetails?.notificationResponse?.payload,
      );
    }

    _attachSpiritualPreferenceListeners();
    _attachReadingReminderPreferenceListeners();
    await cancelNightCompanionReminder();

    _startDailyMaintenance();
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notificationGranted =
          await android.requestNotificationsPermission() ?? false;
      bool? exactGranted;
      try {
        exactGranted =
            await (android as dynamic).requestExactAlarmsPermission() as bool?;
      } catch (_) {
        exactGranted = null;
      }
      _log(
        'permissions android notificationsGranted=$notificationGranted exactAlarmGranted=$exactGranted',
      );
      return notificationGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final before = await ios.checkPermissions();
      _log(
        'permissions ios before isEnabled=${before?.isEnabled} alert=${before?.isAlertEnabled} badge=${before?.isBadgeEnabled} sound=${before?.isSoundEnabled}',
      );
      final granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      final after = await ios.checkPermissions();
      _lastIosAlertPermissionEnabled = after?.isAlertEnabled;
      _lastIosBadgePermissionEnabled = after?.isBadgeEnabled;
      _lastIosSoundPermissionEnabled = after?.isSoundEnabled;
      _log(
        'permissions ios after granted=$granted isEnabled=${after?.isEnabled} alert=${after?.isAlertEnabled} badge=${after?.isBadgeEnabled} sound=${after?.isSoundEnabled}',
      );
      _log(
        'permissions ios result alert=${_lastIosAlertPermissionEnabled ?? false} badge=${_lastIosBadgePermissionEnabled ?? false} sound=${_lastIosSoundPermissionEnabled ?? false}',
      );
      return granted && (_lastIosSoundPermissionEnabled ?? false);
    }

    return true;
  }

  static Future<AdhanEnableResult> enable() async {
    if (kIsWeb) return AdhanEnableResult.unavailableOnWeb;
    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      return AdhanEnableResult.notificationPermissionDenied;
    }

    var selection = LocalPreferencesService.prayerLocation.value;
    if (selection.mode == PrayerLocationMode.current) {
      final result = await PrayerLocationService.useCurrentLocation();
      if (result != PrayerLocationActionResult.success) {
        return switch (result) {
          PrayerLocationActionResult.serviceDisabled =>
            AdhanEnableResult.locationServiceDisabled,
          PrayerLocationActionResult.permissionDenied =>
            AdhanEnableResult.locationPermissionDenied,
          PrayerLocationActionResult.permissionDeniedForever =>
            AdhanEnableResult.locationPermissionDeniedForever,
          PrayerLocationActionResult.unavailableOnWeb =>
            AdhanEnableResult.unavailableOnWeb,
          PrayerLocationActionResult.failed => AdhanEnableResult.locationFailed,
          PrayerLocationActionResult.success => AdhanEnableResult.enabled,
        };
      }
      selection = LocalPreferencesService.prayerLocation.value;
    }

    if (!selection.hasCoordinates) {
      return AdhanEnableResult.locationMissing;
    }

    await LocalPreferencesService.setAdhanEnabled(true);
    await rescheduleForToday();
    await WidgetPayloadService.writeNextPrayerPayload();
    return AdhanEnableResult.enabled;
  }

  static Future<void> disable() async {
    if (kIsWeb) return;
    await LocalPreferencesService.setAdhanEnabled(false);
    await _enqueueScheduling(_cancelScheduledPrayerNotificationsInternal);
    await WidgetPayloadService.writeNextPrayerPayload();
  }

  static Future<AdhanEnableResult> enableForTodayAndRescheduleDaily() async {
    return enable();
  }

  static Future<void> disableAndCancelAll() async {
    await disable();
  }

  static Future<void> rescheduleForToday() async {
    await _enqueueScheduling(_rescheduleForTodayInternal);
  }

  static Future<void> _rescheduleForTodayInternal() async {
    if (kIsWeb) return;
    await _setTimezoneFromDeviceOrFallback();
    if (!LocalPreferencesService.adhanEnabled.value) return;

    await _scheduleDailyReminderNotificationsInternal();

    final selection = LocalPreferencesService.prayerLocation.value;
    if (!selection.hasCoordinates) return;

    final today = DateTime.now();
    await _schedulePrayerNotificationsFor(today, selection);
    if (!SeasonalConfig.isRamadanSeason) {
      await cancelIftarLiveActivityNotificationsForDate(today);
      await cancelIftarLiveActivityNotificationsForDate(
        today.add(const Duration(days: 1)),
      );
      await WidgetPayloadService.writeNextPrayerPayload();
      return;
    }
    final todayMaghrib = AdhanTimesService.computeTimes(
      today,
      selection,
      countryHint: _countryHintFromLocation(selection),
    ).maghrib;
    final targetMaghrib = today.isBefore(todayMaghrib)
        ? todayMaghrib
        : AdhanTimesService.computeTimes(
            today.add(const Duration(days: 1)),
            selection,
            countryHint: _countryHintFromLocation(selection),
          ).maghrib;
    await scheduleIftarLiveActivityNotifications(
      maghrib: targetMaghrib,
      timezoneName: selection.timezone,
      includeWarmup: false,
    );
    await WidgetPayloadService.writeNextPrayerPayload();
  }

  static Future<void> _schedulePrayerNotificationsFor(
    DateTime date,
    PrayerLocation selection,
  ) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final localDate = DateTime(date.year, date.month, date.day);
    final times = AdhanTimesService.computeTimes(
      localDate,
      selection,
      countryHint: _countryHintFromLocation(selection),
    );
    final prayerTimes = <DateTime>[
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];
    for (var i = 0; i < _prayerIndexes.length; i++) {
      final id = _notificationIdFor(localDate, i);
      await _plugin.cancel(id);
      final scheduleAt = prayerTimes[i];
      if (!scheduleAt.isAfter(now)) continue;
      final prayerName = _prayerNameForIndex(i);
      final cityName = _cityLabel(selection);
      final hhmm = AdhanTimesService.formatHHmm(scheduleAt);
      String? reminder;
      if (i == 0) {
        reminder = await DailyContentService.getGentleReminderForDate(
          scheduleAt,
          Locale(LocalPreferencesService.language.value),
        );
      }
      await _schedule(
        id: id,
        title:
            S.get('prayer_notif_title').replaceAll('{prayerName}', prayerName),
        body: buildAdhanNotificationBody(
          prayerName,
          hhmm,
          optionalReminder: reminder,
          cityName: cityName,
        ),
        dateTime: scheduleAt,
        timezoneName: selection.timezone,
        withSound: true,
        iosSoundName: _iosAzanSoundFile,
      );
      _log(
        'prayer_schedule_ios_custom_sound id=$id prayer=$prayerName scheduledAt=$hhmm soundFile=$_iosAzanSoundFile',
      );
    }
  }

  static Future<void> _cancelScheduledPrayerNotificationsInternal() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    for (var dayOffset = -1; dayOffset < 10; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      for (var i = 0; i < _prayerIndexes.length; i++) {
        await _plugin.cancel(_notificationIdFor(date, i));
      }
    }
  }

  static Future<void> scheduleDailyReminderNotifications() async {
    await _enqueueScheduling(_scheduleDailyReminderNotificationsInternal);
  }

  static Future<void> _scheduleDailyReminderNotificationsInternal() async {
    if (kIsWeb) return;
    if (!LocalPreferencesService.adhanEnabled.value) return;
    await _cancelScheduledDailyReminderNotifications();

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      await _schedule(
        id: _dailyReminderNotificationIdFor(date, isMorning: true),
        title: S.get('daily_morning_reminder_title'),
        body: _dailyReminderBodyForDate(date, isMorning: true),
        dateTime: DateTime(date.year, date.month, date.day, 8),
        withSound: false,
        payload: jsonEncode(<String, String>{'type': morningReminderType}),
      );
      await _schedule(
        id: _dailyReminderNotificationIdFor(date, isMorning: false),
        title: S.get('daily_evening_reminder_title'),
        body: _dailyReminderBodyForDate(date, isMorning: false),
        dateTime: DateTime(date.year, date.month, date.day, 21),
        withSound: false,
        payload: jsonEncode(<String, String>{'type': eveningReminderType}),
      );
    }
  }

  static Future<void> syncNightCompanionReminder() async {
    await _enqueueScheduling(_syncNightCompanionReminderInternal);
  }

  static Future<void> _syncNightCompanionReminderInternal() async {
    if (kIsWeb) return;
    await _setTimezoneFromDeviceOrFallback();
    await _cancelNightCompanionReminderInternal();
    if (!LocalPreferencesService.nightCompanionReminderEnabled.value) return;

    final selectedTime =
        LocalPreferencesService.nightCompanionReminderTime.value;
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      await _schedule(
        id: _nightCompanionNotificationIdFor(date),
        title: S.get('night_ritual_notification_title'),
        body: _nightCompanionBodyForDate(date),
        dateTime: DateTime(
          date.year,
          date.month,
          date.day,
          selectedTime.hour,
          selectedTime.minute,
        ),
        withSound: false,
        payload:
            jsonEncode(<String, String>{'type': nightCompanionReminderType}),
        androidChannelId: _nightRitualChannelId,
        androidChannelName: _nightRitualChannelName,
      );
    }
  }

  static Future<void> cancelNightCompanionReminder() async {
    await _enqueueScheduling(_cancelNightCompanionReminderInternal);
  }

  static Future<void> _cancelNightCompanionReminderInternal() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    for (var dayOffset = -1; dayOffset < 10; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      await _plugin.cancel(_nightCompanionNotificationIdFor(date));
    }
  }

  static Future<void> syncReadingReminder() async {
    await _enqueueScheduling(_syncReadingReminderInternal);
  }

  static Future<void> _syncReadingReminderInternal() async {
    if (kIsWeb) return;
    await _setTimezoneFromDeviceOrFallback();
    await _cancelReadingReminderInternal();
    if (!LocalPreferencesService.readingReminderEnabled.value) return;

    final content = _activeReadingReminderContent();
    if (content == null) return;

    final selectedTime = LocalPreferencesService.readingReminderTime.value;
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      await _schedule(
        id: _readingReminderNotificationIdFor(date),
        title: content.$1,
        body: _readingReminderBodyForDate(date, fallback: content.$2),
        dateTime: DateTime(
          date.year,
          date.month,
          date.day,
          selectedTime.hour,
          selectedTime.minute,
        ),
        withSound: false,
        payload: jsonEncode(<String, String>{'type': readingReminderType}),
        androidChannelId: _readingReminderChannelId,
        androidChannelName: _readingReminderChannelName,
      );
    }
  }

  static Future<void> cancelReadingReminder() async {
    await _enqueueScheduling(_cancelReadingReminderInternal);
  }

  static Future<void> _cancelReadingReminderInternal() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    for (var dayOffset = -1; dayOffset < 10; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      await _plugin.cancel(_readingReminderNotificationIdFor(date));
    }
  }

  static Future<void> cancelIftarLiveActivityNotificationsForDate(
    DateTime date,
  ) async {
    if (kIsWeb) return;
    await _plugin.cancel(_iftarNotificationIdFor(date, isWarmup: true));
    await _plugin.cancel(_iftarNotificationIdFor(date, isWarmup: false));
    await _plugin.cancel(_iftarNotificationIdFor(date, isWarmup: null));
  }

  static Future<void> scheduleIftarLiveActivityNotifications({
    required DateTime maghrib,
    String? timezoneName,
    bool includeWarmup = true,
  }) async {
    if (kIsWeb) return;
    if (!SeasonalConfig.isRamadanSeason) {
      await cancelIftarLiveActivityNotificationsForDate(maghrib);
      return;
    }
    final now = DateTime.now();
    final warmupAt = maghrib.subtract(_iftarWarmupOffset);
    final warmupId = _iftarNotificationIdFor(maghrib, isWarmup: true);
    final maghribId = _iftarNotificationIdFor(maghrib, isWarmup: false);

    await _plugin.cancel(warmupId);
    await _plugin.cancel(maghribId);

    if (includeWarmup && warmupAt.isAfter(now)) {
      await _schedule(
        id: warmupId,
        title: _warmupNotificationTitle(),
        body: _warmupNotificationBody(),
        dateTime: warmupAt,
        timezoneName: timezoneName,
        payload: jsonEncode(<String, dynamic>{
          'type': iftarWarmupStartLiveActivityType,
          'iftarEpochMs': maghrib.millisecondsSinceEpoch,
          'timeZone': timezoneName ?? 'local',
        }),
        withSound: false,
      );
      _log(
        'iftar_warmup_scheduled channel=$_prayerChannelIdNormal importance=default soundEnabled=false warmupEpochMs=${warmupAt.millisecondsSinceEpoch} iftarEpochMs=${maghrib.millisecondsSinceEpoch} timeZone=${timezoneName ?? 'local'}',
      );
    }

    if (maghrib.isAfter(now)) {
      await _schedule(
        id: maghribId,
        title: _iftarAlarmTitle(),
        body: _iftarAlarmBody(maghrib),
        dateTime: maghrib,
        timezoneName: timezoneName,
        payload: _iftarAlarmPayload,
        withSound: true,
        androidChannelId: _iftarChannelIdAlarm,
        androidChannelName: _iftarChannelNameAlarm,
      );
      _log(
        'iftar_alarm_scheduled channel=$_iftarChannelIdAlarm importance=high soundEnabled=true',
      );
    }
  }

  static Future<void> scheduleIftarPostCleanupNotification({
    required DateTime postEndsAt,
    String? timezoneName,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    if (!postEndsAt.isAfter(now)) return;

    final cleanupId = _iftarNotificationIdFor(postEndsAt, isWarmup: null);
    await _plugin.cancel(cleanupId);

    await _schedule(
      id: cleanupId,
      title: '',
      body: '',
      dateTime: postEndsAt,
      timezoneName: timezoneName,
      payload: _iftarPostCleanupPayload,
      withSound: false,
    );
    _log(
      'iftar_post_cleanup_scheduled payload=$_iftarPostCleanupPayload at=${postEndsAt.millisecondsSinceEpoch}',
    );
  }

  static Future<void> cancelAll() async {
    await _enqueueScheduling(() async {
      if (kIsWeb) return;
      await _plugin.cancelAll();
    });
  }

  static Future<void> syncSpiritualNotifications() async {
    await _enqueueScheduling(_syncSpiritualNotificationsInternal);
  }

  static Future<void> _syncSpiritualNotificationsInternal() async {
    if (kIsWeb) return;
    await _setTimezoneFromDeviceOrFallback();
    await _cancelScheduledSpiritualNotificationsInternal();
    if (!LocalPreferencesService.spiritualNotificationsEnabled.value) return;

    final selectedTime = LocalPreferencesService.dailyReminderTime.value;
    final slot = _spiritualSlotForTime(selectedTime);

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (!scheduledAt.isAfter(now)) continue;
      final content = await _buildSpiritualNotificationContent(
        date: date,
        slot: slot,
      );
      await _schedule(
        id: _spiritualNotificationIdFor(date, slot),
        title: content.title,
        body: content.body,
        dateTime: scheduledAt,
        withSound: false,
        androidChannelId: _spiritualChannelId,
        androidChannelName: _spiritualChannelName,
        payload: jsonEncode(<String, String>{
          'type': _spiritualPayloadType(slot),
        }),
      );
    }
  }

  static Future<void> cancelScheduledSpiritualNotifications() async {
    await _enqueueScheduling(_cancelScheduledSpiritualNotificationsInternal);
  }

  static Future<void> _cancelScheduledSpiritualNotificationsInternal() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    for (var dayOffset = -1; dayOffset < 10; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      for (final slot in SpiritualNotificationTime.values) {
        await _plugin.cancel(_spiritualNotificationIdFor(date, slot));
      }
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required bool withSound,
    String? timezoneName,
    String? payload,
    String? androidChannelId,
    String? androidChannelName,
    String? iosSoundName,
  }) async {
    final zone = _resolveLocation(timezoneName);
    final tzDateTime = tz.TZDateTime(
      zone,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    final resolvedAndroidChannelId = withSound
        ? (androidChannelId ?? _prayerChannelIdAlarm)
        : _prayerChannelIdNormal;
    final resolvedAndroidChannelName = withSound
        ? (androidChannelName ?? _prayerChannelNameAlarm)
        : _prayerChannelNameNormal;
    final resolvedImportance =
        withSound ? Importance.high : Importance.defaultImportance;
    final iosInterruptionLevel =
        withSound ? InterruptionLevel.timeSensitive : InterruptionLevel.passive;
    final iosPresentSound = withSound;
    final resolvedIosSoundName = withSound ? iosSoundName ?? 'default' : null;
    final iosDetails = withSound
        ? DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: resolvedIosSoundName,
            interruptionLevel: InterruptionLevel.timeSensitive,
          )
        : const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
            interruptionLevel: InterruptionLevel.passive,
          );
    final details = NotificationDetails(
      android: withSound
          ? AndroidNotificationDetails(
              resolvedAndroidChannelId,
              resolvedAndroidChannelName,
              channelDescription: 'Prayer time reminders with sound',
              importance: resolvedImportance,
              priority: Priority.high,
              playSound: true,
              sound: _azanSound,
            )
          : AndroidNotificationDetails(
              resolvedAndroidChannelId,
              resolvedAndroidChannelName,
              channelDescription:
                  resolvedAndroidChannelId == _spiritualChannelId
                      ? 'Daily spiritual content reminders'
                      : 'Prayer time reminders',
              importance: resolvedImportance,
              priority: Priority.defaultPriority,
            ),
      iOS: iosDetails,
    );
    _log(
      'schedule_ios id=$id scheduledEpochMs=${dateTime.millisecondsSinceEpoch} withSound=$withSound presentSound=$iosPresentSound soundName=${resolvedIosSoundName ?? 'none'} interruptionLevel=${iosInterruptionLevel.name}',
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: withSound
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
    _log(
      'schedule id=$id payload=${_redactPayload(payload)} soundEnabled=$withSound channelId=$resolvedAndroidChannelId importance=${resolvedImportance.name}',
    );
  }

  static Future<void> _cancelScheduledDailyReminderNotifications() async {
    final now = DateTime.now();
    for (var dayOffset = -1; dayOffset < 10; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      await _plugin
          .cancel(_dailyReminderNotificationIdFor(date, isMorning: true));
      await _plugin.cancel(
        _dailyReminderNotificationIdFor(date, isMorning: false),
      );
    }
  }

  static tz.Location _resolveLocation(String? timezoneName) {
    if (timezoneName == null || timezoneName.isEmpty) {
      return tz.local;
    }
    try {
      return tz.getLocation(timezoneName);
    } catch (_) {
      return tz.local;
    }
  }

  static void _startDailyMaintenance() {
    _maintenanceTimer?.cancel();

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 0, 5);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    final wait = next.difference(now);
    _maintenanceTimer = Timer(wait, () async {
      if (LocalPreferencesService.adhanEnabled.value) {
        await rescheduleForToday();
      }
      if (LocalPreferencesService.spiritualNotificationsEnabled.value) {
        await syncSpiritualNotifications();
      }
      if (LocalPreferencesService.readingReminderEnabled.value) {
        await syncReadingReminder();
      }
      _startDailyMaintenance();
    });
  }

  static void _attachSpiritualPreferenceListeners() {
    if (_spiritualListenersAttached) return;
    _spiritualListenersAttached = true;

    void sync() {
      unawaited(syncSpiritualNotifications());
    }

    LocalPreferencesService.spiritualNotificationsEnabled.addListener(sync);
    LocalPreferencesService.dailyReminderTime.addListener(sync);
    LocalPreferencesService.language.addListener(sync);
  }

  static void _attachReadingReminderPreferenceListeners() {
    if (_readingReminderListenersAttached) return;
    _readingReminderListenersAttached = true;

    void sync() {
      unawaited(syncReadingReminder());
    }

    LocalPreferencesService.readingReminderEnabled.addListener(sync);
    LocalPreferencesService.readingReminderTime.addListener(sync);
    LocalPreferencesService.language.addListener(sync);
  }

  static (String, String)? _activeReadingReminderContent() {
    final selectedJuz = CollectiveReadingService.getSelectedJuz();
    final hasActiveJuz = selectedJuz != null &&
        ReadingProgressService.hasContextProgress(
            ReadingContext.juz(selectedJuz)) &&
        !CollectiveReadingService.isCompleted(selectedJuz);
    if (hasActiveJuz) {
      return (
        S.get('reading_reminder_title'),
        S.get('reading_reminder_body_juz'),
      );
    }

    if (ReadingProgressService.hasContextProgress(
        const ReadingContext.hatim())) {
      return (
        S.get('reading_reminder_title'),
        S.get('reading_reminder_body_hatim'),
      );
    }

    return null;
  }

  static String _dailyReminderBodyForDate(
    DateTime date, {
    required bool isMorning,
  }) {
    return _rotatingMessageForDate(
      date: date,
      keys: isMorning
          ? const [
              'daily_reminder_variant_1',
              'daily_reminder_variant_2',
              'daily_reminder_variant_3',
            ]
          : const [
              'daily_reminder_variant_2',
              'daily_reminder_variant_3',
              'daily_reminder_variant_1',
            ],
      seed: isMorning ? 'daily_morning' : 'daily_evening',
    );
  }

  static String _nightCompanionBodyForDate(DateTime date) {
    return _rotatingMessageForDate(
      date: date,
      keys: const [
        'night_ritual_notification_body',
        'night_ritual_variant_1',
        'night_ritual_variant_2',
      ],
      seed: 'night_companion',
    );
  }

  static String _readingReminderBodyForDate(
    DateTime date, {
    required String fallback,
  }) {
    return _rotatingMessageForDate(
      date: date,
      keys: const [
        'reading_reminder_variant_1',
        'reading_reminder_variant_2',
        'reading_reminder_variant_3',
      ],
      seed: 'reading_reminder',
      fallback: fallback,
    );
  }

  static String _rotatingMessageForDate({
    required DateTime date,
    required List<String> keys,
    required String seed,
    String? fallback,
  }) {
    if (keys.isEmpty) return fallback ?? '';
    final languageCode = LocalPreferencesService.language.value.toLowerCase();
    final currentKey = _dateKey(date);
    var index =
        DailyContentService.stableHash('$seed|$languageCode|$currentKey') %
            keys.length;

    if (keys.length > 1) {
      final previousDate = date.subtract(const Duration(days: 1));
      final previousKey = _dateKey(previousDate);
      final previousIndex =
          DailyContentService.stableHash('$seed|$languageCode|$previousKey') %
              keys.length;
      if (previousIndex == index) {
        index = (index + 1) % keys.length;
      }
    }

    final message = S.get(keys[index]);
    if (message == keys[index] && fallback != null) return fallback;
    return message;
  }

  static int _dailyReminderNotificationIdFor(
    DateTime date, {
    required bool isMorning,
  }) {
    return _namespacedNotificationId(
      date,
      isMorning ? 11 : 12,
    );
  }

  static int _nightCompanionNotificationIdFor(DateTime date) {
    return _namespacedNotificationId(date, 13);
  }

  static int _readingReminderNotificationIdFor(DateTime date) {
    return _namespacedNotificationId(date, 14);
  }

  static Future<void> _setTimezoneFromDeviceOrFallback() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }
  }

  static String? _countryHintFromLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final label = location.cityName ?? '';
    final parts = label.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  static String _prayerNameForIndex(int index) {
    switch (index) {
      case 0:
        return S.get('fajr');
      case 1:
        return S.get('dhuhr');
      case 2:
        return S.get('asr');
      case 3:
        return S.get('maghrib');
      case 4:
      default:
        return S.get('isha');
    }
  }

  static String _cityLabel(PrayerLocation selection) {
    if (selection.mode == PrayerLocationMode.city &&
        (selection.cityName ?? '').trim().isNotEmpty) {
      return selection.cityName!.trim();
    }
    return S.get('prayer_times_subtitle_current');
  }

  static int _notificationIdFor(DateTime date, int prayerIndex) {
    return _namespacedNotificationId(date, prayerIndex + 1);
  }

  static int _iftarNotificationIdFor(DateTime date, {required bool? isWarmup}) {
    final suffix = switch (isWarmup) {
      true => 21,
      false => 22,
      null => 23,
    };
    return _namespacedNotificationId(date, suffix);
  }

  static int _spiritualNotificationIdFor(
    DateTime date,
    SpiritualNotificationTime slot,
  ) {
    final suffix = switch (slot) {
      SpiritualNotificationTime.morning => 31,
      SpiritualNotificationTime.midday => 32,
      SpiritualNotificationTime.night => 33,
    };
    return _namespacedNotificationId(date, suffix);
  }

  static int _namespacedNotificationId(DateTime date, int slot) {
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    return ymd * 100 + slot;
  }

  static Future<void> _enqueueScheduling(
    Future<void> Function() action,
  ) async {
    final completer = Completer<void>();
    _scheduleQueue = _scheduleQueue.then((_) async {
      try {
        await action();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
        rethrow;
      }
    }).catchError((_) {});
    return completer.future;
  }

  static SpiritualNotificationTime _spiritualSlotForTime(TimeOfDay time) {
    if (time.hour < 11) return SpiritualNotificationTime.morning;
    if (time.hour < 17) return SpiritualNotificationTime.midday;
    return SpiritualNotificationTime.night;
  }

  static String _spiritualPayloadType(SpiritualNotificationTime slot) {
    return switch (slot) {
      SpiritualNotificationTime.morning => spiritualMorningType,
      SpiritualNotificationTime.midday => spiritualMiddayType,
      SpiritualNotificationTime.night => spiritualNightType,
    };
  }

  static Future<_SpiritualNotificationContent>
      _buildSpiritualNotificationContent({
    required DateTime date,
    required SpiritualNotificationTime slot,
  }) async {
    final locale = Locale(LocalPreferencesService.language.value);
    final isTurkish = locale.languageCode.toLowerCase() == 'tr';

    switch (slot) {
      case SpiritualNotificationTime.morning:
        final ayah = DailyAyahService.getAyahWithContextForDate(
          date,
          QuranData.instance.ayahs,
          QuranData.instance.getSurahName,
        );
        final readable = await DailyAyahService.getAyahReadableText(
          surah: ayah.surahNumber,
          ayah: ayah.ayahNumber,
          locale: locale,
        );
        final reflection = isTurkish
            ? 'Bu ayeti bugünün niyeti gibi taşıyabilirsin.'
            : 'Carry this verse gently with you today.';
        return _SpiritualNotificationContent(
          title: isTurkish ? 'Sabaha bir ayet' : 'A verse for the morning',
          body: _joinNotificationParts([
            readable.isNotEmpty ? readable : ayah.turkishReadable,
            reflection,
          ]),
        );
      case SpiritualNotificationTime.midday:
        final reminder =
            await DailyContentService.getGentleReminderForDate(date, locale);
        return _SpiritualNotificationContent(
          title: isTurkish ? 'Niyetini tazele' : 'Return to your intention',
          body: reminder.trim().isNotEmpty
              ? reminder.trim()
              : (isTurkish
                  ? 'Bugünün içinde kısa bir durak ver.'
                  : 'Pause for a brief spiritual reset today.'),
        );
      case SpiritualNotificationTime.night:
        final useQuote = DailyContentService.stableHash(
                  '${_dateKey(date)}|night_content',
                ) %
                2 ==
            0;
        if (useQuote) {
          final quote = await DailyContentService.getQuoteForDate(date, locale);
          return _SpiritualNotificationContent(
            title: isTurkish ? 'Geceye bir düşünce' : 'A quiet thought for tonight',
            body: _joinNotificationParts([
              quote.text,
              if ((quote.source ?? '').trim().isNotEmpty) quote.source!.trim(),
            ]),
          );
        }
        final hadith = DailyContentService.getHadithForDate(date);
        final body = hadith?.text.trim();
        return _SpiritualNotificationContent(
          title:
              isTurkish ? 'Geceye bir hatırlatma' : 'A reflection for tonight',
          body: _joinNotificationParts([
            if (body != null && body.isNotEmpty) body,
            if ((hadith?.source ?? '').trim().isNotEmpty)
              hadith!.source!.trim(),
          ]),
        );
    }
  }

  static String _joinNotificationParts(List<String> parts) {
    return parts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join('\n');
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static void handleNotificationResponsePayload(String? payload) {
    lastNotificationTapPayload.value = payload;
    final type = notificationPayloadType(payload);
    if (type == iftarWarmupStartLiveActivityType ||
        type == _legacyIftarWarmupPayload) {
      final iftarEpochMs = notificationPayloadIftarEpochMs(payload);
      final timeZone = notificationPayloadTimeZone(payload);
      _log(
        'trigger event=$iftarWarmupStartLiveActivityType iftarEpochMs=${iftarEpochMs ?? 'missing'} timeZone=${timeZone ?? 'missing'}',
      );
      final handler = _notificationTapHandler;
      if (handler != null) {
        unawaited(handler(payload));
      }
      return;
    }
    if (type == _iftarAlarmPayload) {
      _log('trigger event=iftar_alarm_fired');
      final handler = _notificationTapHandler;
      if (handler != null) {
        unawaited(handler(payload));
      }
      return;
    }
    if (type == _iftarPostCleanupPayload) {
      _log('trigger event=iftar_post_cleanup');
      final handler = _notificationTapHandler;
      if (handler != null) {
        unawaited(handler(payload));
      }
      return;
    }
    _log('trigger event=other payload=${_redactPayload(payload)}');
    final handler = _notificationTapHandler;
    if (handler != null) {
      unawaited(handler(payload));
    }
  }

  static bool get _isTurkishLanguage =>
      LocalPreferencesService.language.value.toLowerCase() == 'tr';

  static String _warmupNotificationTitle() {
    if (_isTurkishLanguage) {
      return 'İftara 1 saat kaldı';
    }
    return '1 hour to Iftar';
  }

  static String _warmupNotificationBody() {
    if (_isTurkishLanguage) {
      return 'Geri sayımı başlatmak için dokun';
    }
    return 'Tap to start the countdown';
  }

  // ignore: unused_element
  static String _iftarWarmupTitle() {
    if (_isTurkishLanguage) {
      return 'İftar sayacı hazır — Dynamic Island’da görmek için aç.';
    }
    return 'Iftar countdown is ready — open the app for Dynamic Island.';
  }

  // ignore: unused_element
  static String _iftarWarmupBody() {
    if (_isTurkishLanguage) {
      return 'Canlı Etkinlik geri sayımı uygulamada başlatılır.';
    }
    return 'Live Activity countdown starts when the app is opened.';
  }

  static String _iftarAlarmTitle() {
    if (_isTurkishLanguage) {
      return 'İftar vakti';
    }
    return 'It is time for iftar';
  }

  static String _iftarAlarmBody(DateTime maghrib) {
    final hhmm = AdhanTimesService.formatHHmm(maghrib);
    if (_isTurkishLanguage) {
      return 'İftar saati geldi ($hhmm).';
    }
    return 'Iftar time has arrived ($hhmm).';
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AdhanNotifications] $message');
    }
  }
}

class _SpiritualNotificationContent {
  const _SpiritualNotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
