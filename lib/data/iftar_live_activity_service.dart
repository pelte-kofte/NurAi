import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show ValueNotifier, debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';
import 'adhan_notification_service.dart';
import 'adhan_times_service.dart';
import 'local_preferences_service.dart';

class IftarLiveActivityService {
  IftarLiveActivityService._();

  static const MethodChannel _channel = MethodChannel('nurai.widgets');
  static const Duration _countdownWindow = Duration(hours: 1);
  static const String _methodIsSupported = 'isIftarLiveActivitySupported';
  static const String _methodStart = 'startIftarLiveActivity';
  static const String _methodUpdate = 'updateIftarLiveActivity';
  static const String _methodEnd = 'endIftarLiveActivity';

  static final isSupported = ValueNotifier<bool>(false);

  static Timer? _windowStartTimer;
  static Timer? _maghribTimer;
  static Timer? _foregroundTicker;
  static bool _initialized = false;
  static bool _isForeground = true;
  static bool _isTickUpdateInFlight = false;
  static final _lifecycleObserver = _IftarLifecycleObserver();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    isSupported.value = await _querySupport();
    AdhanNotificationService.setNotificationTapHandler((payload) async {
      if (payload == 'iftar_live_activity_warmup' ||
          payload == 'iftar_alarm_fired') {
        await maybeStartOrUpdate();
      }
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    LocalPreferencesService.prayerLocation.addListener(_onConfigChanged);
    LocalPreferencesService.adhanEnabled.addListener(_onConfigChanged);
    LocalPreferencesService.iftarLiveActivityEnabled.addListener(
      _onConfigChanged,
    );
  }

  static Future<void> scheduleIftarNotifications() async {
    if (kIsWeb) return;

    final now = DateTime.now();
    final location = LocalPreferencesService.prayerLocation.value;

    await AdhanNotificationService.cancelIftarLiveActivityNotificationsForDate(
      now,
    );
    await AdhanNotificationService.cancelIftarLiveActivityNotificationsForDate(
      now.add(const Duration(days: 1)),
    );

    final shouldScheduleIftarAlarm =
        LocalPreferencesService.adhanEnabled.value || _isFeatureEnabled;
    if (!shouldScheduleIftarAlarm || !location.hasCoordinates) {
      _log(
        'skip_iftar_notification_schedule enabled=$shouldScheduleIftarAlarm hasLocation=${location.hasCoordinates}',
      );
      return;
    }

    final todayMaghrib = _maghribFor(now, location);
    final targetDate =
        now.isBefore(todayMaghrib) ? now : now.add(const Duration(days: 1));
    final targetMaghrib = _maghribFor(targetDate, location);
    final includeWarmup =
        _isIosRuntime && isSupported.value && _isFeatureEnabled;
    _log(
      'schedule_iftar_notifications includeWarmup=$includeWarmup hasLocation=${location.hasCoordinates}',
    );
    await AdhanNotificationService.scheduleIftarLiveActivityNotifications(
      maghrib: targetMaghrib,
      timezoneName: location.timezone,
      includeWarmup: includeWarmup,
    );
    if (shouldStartNow(now, targetMaghrib)) {
      _log('schedule_trigger_start window_active');
      await startOrUpdate(targetMaghrib);
    }
  }

  static Future<void> maybeStartOrUpdate() async {
    if (!_isIosRuntime || !isSupported.value) {
      _log(
        'skip_start iosRuntime=$_isIosRuntime isSupported=${isSupported.value}',
      );
      return;
    }

    final now = DateTime.now();
    final location = LocalPreferencesService.prayerLocation.value;

    if (!_isFeatureEnabled || !location.hasCoordinates) {
      _log(
        'skip_start featureEnabled=$_isFeatureEnabled hasLocation=${location.hasCoordinates}',
      );
      _cancelTimers();
      await endIfNeeded();
      return;
    }

    final maghrib = _maghribFor(now, location);
    final windowStart = maghrib.subtract(_countdownWindow);

    if (!now.isBefore(maghrib)) {
      _log(
        'past_maghrib ending activity',
      );
      _cancelTimers();
      await endIfNeeded();
      await scheduleIftarNotifications();
      return;
    }

    _scheduleWindowTimers(windowStart: windowStart, maghrib: maghrib);
    if (!shouldStartNow(now, maghrib)) {
      _log('outside_start_window waiting_for_warmup_window');
      await endIfNeeded();
      return;
    }
    _log('start_or_update countdown_active');
    await startOrUpdate(maghrib);
  }

  static Future<void> endIfNeeded() async {
    _stopForegroundTicker();
    await _invokeSafely(_methodEnd, const <String, dynamic>{});
  }

  static bool get _isIosRuntime => !kIsWeb && Platform.isIOS;
  static bool get _isFeatureEnabled =>
      LocalPreferencesService.iftarLiveActivityEnabled.value;

  static void _onConfigChanged() {
    _log('config_changed');
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
        _log('window_start_timer_fired');
        unawaited(maybeStartOrUpdate());
      });
    }

    if (now.isBefore(maghrib)) {
      _maghribTimer = Timer(maghrib.difference(now), () {
        _log('maghrib_timer_fired');
        unawaited(maybeStartOrUpdate());
      });
    }
  }

  static void _startForegroundTicker({required DateTime maghrib}) {
    _foregroundTicker?.cancel();
    if (!_isForeground) return;
    _foregroundTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_tickForegroundCountdown(maghrib: maghrib));
    });
  }

  static void _stopForegroundTicker() {
    _foregroundTicker?.cancel();
    _foregroundTicker = null;
    _isTickUpdateInFlight = false;
  }

  static Future<void> _tickForegroundCountdown(
      {required DateTime maghrib}) async {
    if (_isTickUpdateInFlight) return;
    _isTickUpdateInFlight = true;
    try {
      final now = DateTime.now();
      if (!_isFeatureEnabled || !_isForeground) {
        _stopForegroundTicker();
        return;
      }
      if (!now.isBefore(maghrib)) {
        _log('foreground_tick_reached_maghrib');
        await maybeStartOrUpdate();
        return;
      }
      await _invokeSafely(
        _methodUpdate,
        <String, dynamic>{
          'title': S.get('iftar_countdown_title'),
          'subtitle': S.get('iftar_countdown_subtitle'),
          'phase': 'countdown',
          'targetEpochMs': maghrib.millisecondsSinceEpoch,
        },
      );
    } finally {
      _isTickUpdateInFlight = false;
    }
  }

  static void onAppLifecycleChanged(AppLifecycleState state) {
    final isNowForeground = state == AppLifecycleState.resumed;
    _isForeground = isNowForeground;
    _log('lifecycle_changed state=$state');
    if (isNowForeground) {
      unawaited(maybeStartOrUpdate());
    } else {
      _stopForegroundTicker();
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[IftarLiveActivity] $message');
    }
  }

  static Future<void> _startOrUpdateCountdown({
    required DateTime maghrib,
  }) async {
    await _invokeSafely(
      _methodStart,
      <String, dynamic>{
        'title': S.get('iftar_countdown_title'),
        'subtitle': S.get('iftar_countdown_subtitle'),
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
    } catch (error, stackTrace) {
      _log(
        'native_call_failed method=$method error=$error stack=$stackTrace',
      );
    }
  }

  static Future<bool> _querySupport() async {
    if (!_isIosRuntime) return false;
    try {
      final result = await _channel.invokeMethod<bool>(_methodIsSupported);
      final isEnabled = result ?? false;
      _log('support isSupported=$isEnabled areActivitiesEnabled=$isEnabled');
      return isEnabled;
    } catch (error) {
      _log('support_query_failed error=$error');
      return false;
    }
  }

  static bool shouldStartNow(DateTime now, DateTime iftarDate) {
    final location = LocalPreferencesService.prayerLocation.value;
    if (!_isIosRuntime) return false;
    if (!isSupported.value) return false;
    if (!_isFeatureEnabled) return false;
    if (!location.hasCoordinates) return false;
    if (!now.isBefore(iftarDate)) return false;

    final remaining = iftarDate.difference(now);
    return remaining <= _countdownWindow && remaining > Duration.zero;
  }

  static Future<void> startOrUpdate(DateTime iftarDate) async {
    await _startOrUpdateCountdown(maghrib: iftarDate);
    _startForegroundTicker(maghrib: iftarDate);
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
    _stopForegroundTicker();
  }
}

class _IftarLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    IftarLiveActivityService.onAppLifecycleChanged(state);
  }
}
