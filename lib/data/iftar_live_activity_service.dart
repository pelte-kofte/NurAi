import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter/services.dart';

import '../models/prayer_location.dart';
import 'adhan_notification_service.dart';
import 'adhan_times_service.dart';
import 'local_preferences_service.dart';

class IftarLiveActivityService {
  IftarLiveActivityService._();

  static const MethodChannel _channel = MethodChannel('nurai.widgets');
  static const Duration _countdownWindow = Duration(hours: 1);
  static const Duration _doneStateVisibleFor = Duration(seconds: 4);

  static const String _methodIsSupported = 'isIftarLiveActivitySupported';
  static const String _methodStart = 'startIftarLiveActivity';
  static const String _methodUpdate = 'updateIftarLiveActivity';
  static const String _methodEnd = 'endIftarLiveActivity';

  static final isSupported = ValueNotifier<bool>(false);

  static Timer? _windowStartTimer;
  static Timer? _maghribTimer;
  static bool _initialized = false;
  static bool _isShowingDoneState = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    isSupported.value = await _querySupport();
    LocalPreferencesService.adhanEnabled.addListener(_onConfigChanged);
    LocalPreferencesService.prayerLocation.addListener(_onConfigChanged);
    LocalPreferencesService.iftarLiveActivityEnabled.addListener(
      _onConfigChanged,
    );
  }

  static Future<void> scheduleIftarNotifications() async {
    if (!_isIosRuntime || !isSupported.value) return;

    final now = DateTime.now();
    final location = LocalPreferencesService.prayerLocation.value;

    await AdhanNotificationService.cancelIftarLiveActivityNotificationsForDate(
      now,
    );
    await AdhanNotificationService.cancelIftarLiveActivityNotificationsForDate(
      now.add(const Duration(days: 1)),
    );

    if (!_isFeatureEnabled || !location.hasCoordinates) return;

    final todayMaghrib = _maghribFor(now, location);
    final targetDate =
        now.isBefore(todayMaghrib) ? now : now.add(const Duration(days: 1));
    final targetMaghrib = _maghribFor(targetDate, location);
    await AdhanNotificationService.scheduleIftarLiveActivityNotifications(
      maghrib: targetMaghrib,
      timezoneName: location.timezone,
    );
  }

  static Future<void> maybeStartOrUpdate() async {
    if (!_isIosRuntime || !isSupported.value) return;

    final now = DateTime.now();
    final location = LocalPreferencesService.prayerLocation.value;
    final forcedByWarmupTap =
        AdhanNotificationService.consumeIftarWarmupTapFlag();

    if (!_isFeatureEnabled || !location.hasCoordinates) {
      _cancelTimers();
      await endIfNeeded();
      return;
    }

    final maghrib = _maghribFor(now, location);
    final windowStart = maghrib.subtract(_countdownWindow);

    if (!now.isBefore(maghrib)) {
      _cancelTimers();
      await _showDoneThenEnd();
      await scheduleIftarNotifications();
      return;
    }

    if (now.isBefore(windowStart) && !forcedByWarmupTap) {
      await endIfNeeded();
      _scheduleWindowTimers(windowStart: windowStart, maghrib: maghrib);
      return;
    }

    _scheduleWindowTimers(windowStart: windowStart, maghrib: maghrib);
    await _startOrUpdateCountdown(maghrib: maghrib);
  }

  static Future<void> endIfNeeded() async {
    _isShowingDoneState = false;
    await _invokeSafely(_methodEnd, const <String, dynamic>{});
  }

  static bool get _isIosRuntime => !kIsWeb && Platform.isIOS;
  static bool get _isFeatureEnabled =>
      LocalPreferencesService.adhanEnabled.value &&
      LocalPreferencesService.iftarLiveActivityEnabled.value;

  static void _onConfigChanged() {
    unawaited(scheduleIftarNotifications());
    unawaited(maybeStartOrUpdate());
  }

  static void _scheduleWindowTimers({
    required DateTime windowStart,
    required DateTime maghrib,
  }) {
    _windowStartTimer?.cancel();
    _maghribTimer?.cancel();

    final now = DateTime.now();
    if (now.isBefore(windowStart)) {
      _windowStartTimer = Timer(windowStart.difference(now), () {
        unawaited(maybeStartOrUpdate());
      });
    }

    if (now.isBefore(maghrib)) {
      _maghribTimer = Timer(maghrib.difference(now), () {
        unawaited(maybeStartOrUpdate());
      });
    }
  }

  static Future<void> _showDoneThenEnd() async {
    if (_isShowingDoneState) return;
    _isShowingDoneState = true;
    await _invokeSafely(
      _methodUpdate,
      <String, dynamic>{
        'title': 'Allah kabul etsin',
        'subtitle': 'İftar vakti.',
        'phase': 'done',
        'targetEpochMs': DateTime.now().millisecondsSinceEpoch,
      },
    );
    await Future<void>.delayed(_doneStateVisibleFor);
    await endIfNeeded();
  }

  static Future<void> _startOrUpdateCountdown({
    required DateTime maghrib,
  }) async {
    _isShowingDoneState = false;
    await _invokeSafely(
      _methodStart,
      <String, dynamic>{
        'title': 'İftara',
        'subtitle': 'Kalan süre',
        'phase': 'countdown',
        'targetEpochMs': maghrib.millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> _invokeSafely(
    String method,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _channel.invokeMethod<void>(method, payload);
    } catch (_) {
      // Best effort only.
    }
  }

  static Future<bool> _querySupport() async {
    if (!_isIosRuntime) return false;
    try {
      final result = await _channel.invokeMethod<bool>(_methodIsSupported);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static DateTime _maghribFor(DateTime day, PrayerLocation location) {
    final times = AdhanTimesService.computeTimes(
      DateTime(day.year, day.month, day.day),
      location,
      countryHint: _countryHintFromLocation(location),
    );
    return times.maghrib;
  }

  static String? _countryHintFromLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final label = location.cityName ?? '';
    final parts = label.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  static void _cancelTimers() {
    _windowStartTimer?.cancel();
    _windowStartTimer = null;
    _maghribTimer?.cancel();
    _maghribTimer = null;
  }
}
