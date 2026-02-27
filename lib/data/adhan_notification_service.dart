import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';
import 'adhan_times_service.dart';
import 'daily_content_service.dart';
import 'local_preferences_service.dart';
import 'prayer_location_service.dart';
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
  switch (payload) {
    case 'iftar_live_activity_warmup':
      return 'iftar_live_activity_warmup';
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
  static const _prayerChannelIdAlarm = 'adhan_channel_v2';
  static const _prayerChannelNameAlarm = 'Prayer Times Alarm';
  static const _iftarChannelIdAlarm = 'iftar_alarm_v2';
  static const _iftarChannelNameAlarm = 'Iftar Alarm';
  static const _iftarWarmupOffset = Duration(hours: 1);
  static const _iftarWarmupPayload = 'iftar_live_activity_warmup';
  static const _iftarAlarmPayload = 'iftar_alarm_fired';
  static const _iftarPostCleanupPayload = 'iftar_post_cleanup';
  static Future<void> Function(String? payload)? _notificationTapHandler;
  static bool? _lastIosAlertPermissionEnabled;
  static bool? _lastIosBadgePermissionEnabled;
  static bool? _lastIosSoundPermissionEnabled;

  static void setNotificationTapHandler(
    Future<void> Function(String? payload)? handler,
  ) {
    _notificationTapHandler = handler;
  }

  static bool get isIosSoundPermissionGranted =>
      _lastIosSoundPermissionEnabled ?? false;

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
    await cancelAll();
    await WidgetPayloadService.writeNextPrayerPayload();
  }

  static Future<AdhanEnableResult> enableForTodayAndRescheduleDaily() async {
    return enable();
  }

  static Future<void> disableAndCancelAll() async {
    await disable();
  }

  static Future<void> rescheduleForToday() async {
    if (kIsWeb) return;
    if (!LocalPreferencesService.adhanEnabled.value) return;

    final selection = LocalPreferencesService.prayerLocation.value;
    if (!selection.hasCoordinates) return;

    final today = DateTime.now();
    await schedulePrayerNotificationsFor(today, selection);
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

  static Future<void> schedulePrayerNotificationsFor(
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
      );
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
    final now = DateTime.now();
    final warmupAt = maghrib.subtract(_iftarWarmupOffset);
    final warmupId = _iftarNotificationIdFor(maghrib, isWarmup: true);
    final maghribId = _iftarNotificationIdFor(maghrib, isWarmup: false);

    await _plugin.cancel(warmupId);
    await _plugin.cancel(maghribId);

    if (includeWarmup && warmupAt.isAfter(now)) {
      await _schedule(
        id: warmupId,
        title: _iftarWarmupTitle(),
        body: _iftarWarmupBody(),
        dateTime: warmupAt,
        timezoneName: timezoneName,
        payload: _iftarWarmupPayload,
        withSound: false,
      );
      _log(
        'iftar_warmup_scheduled channel=$_prayerChannelIdNormal importance=default soundEnabled=false',
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
    if (kIsWeb) return;
    await _plugin.cancelAll();
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
    final iosSoundName = withSound ? 'default' : null;
    final iosDetails = withSound
        ? const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
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
            )
          : AndroidNotificationDetails(
              resolvedAndroidChannelId,
              resolvedAndroidChannelName,
              channelDescription: 'Prayer time reminders',
              importance: resolvedImportance,
              priority: Priority.defaultPriority,
            ),
      iOS: iosDetails,
    );
    _log(
      'schedule_ios id=$id scheduledEpochMs=${dateTime.millisecondsSinceEpoch} withSound=$withSound presentSound=$iosPresentSound soundName=${iosSoundName ?? 'none'} interruptionLevel=${iosInterruptionLevel.name}',
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
      _startDailyMaintenance();
    });
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
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    return ymd * 10 + prayerIndex;
  }

  static int _iftarNotificationIdFor(DateTime date, {required bool? isWarmup}) {
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    final suffix = switch (isWarmup) {
      true => 6,
      false => 7,
      null => 8,
    };
    return (ymd * 10 + suffix);
  }

  static void handleNotificationResponsePayload(String? payload) {
    if (payload == _iftarWarmupPayload) {
      _log('trigger event=iftar_live_activity_warmup');
      final handler = _notificationTapHandler;
      if (handler != null) {
        unawaited(handler(payload));
      }
      return;
    }
    if (payload == _iftarAlarmPayload) {
      _log('trigger event=iftar_alarm_fired');
      final handler = _notificationTapHandler;
      if (handler != null) {
        unawaited(handler(payload));
      }
      return;
    }
    if (payload == _iftarPostCleanupPayload) {
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

  static String _iftarWarmupTitle() {
    if (_isTurkishLanguage) {
      return 'İftar sayacı hazır — Dynamic Island’da görmek için aç.';
    }
    return 'Iftar countdown is ready — open the app for Dynamic Island.';
  }

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
