import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  AdhanNotificationService.handleNotificationResponsePayload(response.payload);
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
  static const _iftarWarmupOffset = Duration(hours: 1);
  static const _iftarWarmupPayload = 'iftar_live_activity_warmup';
  static const _iftarAtMaghribPayload = 'iftar_live_activity_maghrib';
  static bool _iftarWarmupTapped = false;

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
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
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
      );
    }
  }

  static Future<void> cancelIftarLiveActivityNotificationsForDate(
    DateTime date,
  ) async {
    if (kIsWeb) return;
    await _plugin.cancel(_iftarNotificationIdFor(date, isWarmup: true));
    await _plugin.cancel(_iftarNotificationIdFor(date, isWarmup: false));
  }

  static Future<void> scheduleIftarLiveActivityNotifications({
    required DateTime maghrib,
    String? timezoneName,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final warmupAt = maghrib.subtract(_iftarWarmupOffset);
    final warmupId = _iftarNotificationIdFor(maghrib, isWarmup: true);
    final maghribId = _iftarNotificationIdFor(maghrib, isWarmup: false);

    await _plugin.cancel(warmupId);
    await _plugin.cancel(maghribId);

    if (warmupAt.isAfter(now)) {
      await _schedule(
        id: warmupId,
        title: _iftarWarmupTitle(),
        body: _iftarWarmupBody(),
        dateTime: warmupAt,
        timezoneName: timezoneName,
        payload: _iftarWarmupPayload,
      );
    }

    if (maghrib.isAfter(now)) {
      await _schedule(
        id: maghribId,
        title: 'Allah kabul etsin',
        body: 'İftar vakti.',
        dateTime: maghrib,
        timezoneName: timezoneName,
        payload: _iftarAtMaghribPayload,
      );
    }
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
    String? timezoneName,
    String? payload,
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

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times',
          'Prayer Times',
          channelDescription: 'Prayer time reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  static int _iftarNotificationIdFor(DateTime date, {required bool isWarmup}) {
    final ymd = date.year * 10000 + date.month * 100 + date.day;
    return (ymd * 10 + (isWarmup ? 6 : 7));
  }

  static void handleNotificationResponsePayload(String? payload) {
    if (payload == _iftarWarmupPayload) {
      _iftarWarmupTapped = true;
    }
  }

  static bool consumeIftarWarmupTapFlag() {
    final wasTapped = _iftarWarmupTapped;
    _iftarWarmupTapped = false;
    return wasTapped;
  }

  static bool get _isTurkishLanguage =>
      LocalPreferencesService.language.value.toLowerCase() == 'tr';

  static String _iftarWarmupTitle() {
    if (_isTurkishLanguage) return 'İftara 1 saat kaldı';
    return '1 hour left until iftar';
  }

  static String _iftarWarmupBody() {
    if (_isTurkishLanguage) {
      return 'Sayaç için dokun ve kilit ekranına ekle.';
    }
    return 'Tap to start the countdown and add it to your lock screen.';
  }
}
