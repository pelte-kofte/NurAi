import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local notifications for the five daily prayer times.
///
/// Uses Diyanet (Turkey) calculation method with Istanbul coordinates
/// as default. Pre-schedules 7 days ahead and refreshes each time
/// the app launches while enabled.
class AdhanNotificationService {
  AdhanNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // Default: Istanbul
  static const _defaultLat = 41.0082;
  static const _defaultLng = 28.9784;

  static const _prayerBodies = [
    'Sabah vakti girdi.',
    '\u00d6\u011fle vakti girdi.',
    '\u0130kindi vakti girdi.',
    'Ak\u015fam vakti girdi.',
    'Yats\u0131 vakti girdi.',
  ];

  // ── Initialization ──────────────────────────────────────────────

  /// Initialize timezone data and notification plugin.
  /// Call once at app startup.
  static Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // ── Permissions ─────────────────────────────────────────────────

  /// Request notification permissions. Returns true if granted.
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    // iOS
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

  // ── Scheduling ──────────────────────────────────────────────────

  /// Schedule prayer notifications for the next 7 days.
  /// Cancels any existing scheduled notifications first.
  /// Call this on toggle-enable and on every app launch (if enabled).
  static Future<void> schedulePrayerNotifications({
    double lat = _defaultLat,
    double lng = _defaultLng,
  }) async {
    if (kIsWeb) return;

    await cancelAll();

    final coords = Coordinates(lat, lng);
    final params = CalculationMethod.turkey.getParameters();
    final now = DateTime.now();

    for (int day = 0; day < 7; day++) {
      final date = now.add(Duration(days: day));
      final components = DateComponents(date.year, date.month, date.day);
      final prayers = PrayerTimes(coords, components, params);

      final times = [
        prayers.fajr,
        prayers.dhuhr,
        prayers.asr,
        prayers.maghrib,
        prayers.isha,
      ];

      for (int i = 0; i < 5; i++) {
        if (times[i].isAfter(now)) {
          await _schedule(
            id: day * 10 + i,
            body: _prayerBodies[i],
            dateTime: times[i],
          );
        }
      }
    }
  }

  static Future<void> _schedule({
    required int id,
    required String body,
    required DateTime dateTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      'Vakit',
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times',
          'Namaz Vakitleri',
          channelDescription: 'Ezan vakti bildirimleri',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ── Cancel ──────────────────────────────────────────────────────

  /// Cancel all scheduled prayer notifications.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
