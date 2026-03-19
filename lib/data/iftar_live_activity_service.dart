import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show ValueNotifier, debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/config/seasonal_config.dart';
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
  static const String _methodEnd = 'endIftarLiveActivity';
  static const String _methodEndAll = 'endAllIftarActivities';
  static const String _methodScheduleBackgroundTasks =
      'scheduleIftarLiveActivityBackgroundTasks';
  static const String _methodCancelBackgroundTasks =
      'cancelIftarLiveActivityBackgroundTasks';
  static const String _payloadPostCleanup = 'iftar_post_cleanup';
  static const Duration _postWindow = Duration(minutes: 5);

  static final isSupported = ValueNotifier<bool>(false);

  static Timer? _windowStartTimer;
  static Timer? _maghribTimer;
  static Timer? _postEndTimer;
  static bool _initialized = false;
  static final _lifecycleObserver = _IftarLifecycleObserver();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    isSupported.value = await _querySupport();
    AdhanNotificationService.setNotificationTapHandler((payload) async {
      final type = AdhanNotificationService.notificationPayloadType(payload);
      if (type == AdhanNotificationService.iftarWarmupStartLiveActivityType ||
          type == 'iftar_live_activity_warmup') {
        final iftarEpochMs =
            AdhanNotificationService.notificationPayloadIftarEpochMs(payload);
        final timeZone =
            AdhanNotificationService.notificationPayloadTimeZone(payload);
        if (iftarEpochMs == null) {
          _log(
              'tap_start_missing_iftar_epoch_ms type=$type timeZone=$timeZone');
          await maybeStartOrUpdate();
          return;
        }
        final iftarDate = DateTime.fromMillisecondsSinceEpoch(iftarEpochMs);
        _log(
          'tap_start_live_activity iftarEpochMs=$iftarEpochMs timeZone=${timeZone ?? 'local'} iftarIsFuture=${iftarDate.isAfter(DateTime.now())}',
        );
        await startOrUpdate(iftarDate);
        _log(
          'tap_start_live_activity_completed iftarEpochMs=$iftarEpochMs timeZone=${timeZone ?? 'local'}',
        );
        return;
      }
      if (type == 'iftar_alarm_fired' || type == _payloadPostCleanup) {
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
    if (!SeasonalConfig.isRamadanSeason) {
      _cancelTimers();
      await _cancelBackgroundTasks();
      await endIfNeeded();
      return;
    }

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
      await _cancelBackgroundTasks();
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
    if (includeWarmup) {
      await _scheduleBackgroundTasks(
        iftarDate: targetMaghrib,
        postEndsAt: targetMaghrib.add(_postWindow),
      );
    } else {
      await _cancelBackgroundTasks();
    }
    if (shouldStartNow(now, targetMaghrib)) {
      _log('schedule_trigger_start window_active');
      await startOrUpdate(targetMaghrib);
    }
    if (now.isBefore(todayMaghrib)) {
      unawaited(maybeStartOrUpdate());
    }
  }

  static Future<void> maybeStartOrUpdate() async {
    if (!SeasonalConfig.isRamadanSeason) {
      _cancelTimers();
      await _cancelBackgroundTasks();
      await endIfNeeded();
      return;
    }
    if (!_isIosRuntime || !isSupported.value) {
      _log(
        'skip_start iosRuntime=$_isIosRuntime isSupported=${isSupported.value}',
      );
      return;
    }

    final now = DateTime.now();
    final location = LocalPreferencesService.prayerLocation.value;
    await _endAfterPostIfNeeded(
      now: now,
      location: location,
      reason: 'safety_check',
    );

    if (!_isFeatureEnabled || !location.hasCoordinates) {
      _log(
        'skip_start featureEnabled=$_isFeatureEnabled hasLocation=${location.hasCoordinates}',
      );
      _cancelTimers();
      await _cancelBackgroundTasks();
      await endIfNeeded();
      return;
    }

    final maghrib = _maghribFor(now, location);
    final windowStart = maghrib.subtract(_countdownWindow);

    if (!now.isBefore(maghrib)) {
      final postEndsAt = maghrib.add(_postWindow);
      if (now.isBefore(postEndsAt)) {
        _log(
          'activity_reached_target grace_active=true targetEpochMs=${maghrib.millisecondsSinceEpoch} graceEndEpochMs=${postEndsAt.millisecondsSinceEpoch}',
        );
        await _startOrUpdateActivity(
          targetDate: maghrib,
          postEndsAt: postEndsAt,
        );
        _schedulePostEndTimer(postEndsAt: postEndsAt);
        return;
      }
      _log('past_maghrib_and_post_window_finished ending activity');
      _cancelTimers();
      await _endAllActivities(
        reason: 'post_window_finished',
      );
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
    await _invokeSafely(_methodEnd, const <String, dynamic>{});
  }

  static Future<void> _endAllActivities({required String reason}) async {
    _log('live_activity_end_after_post reason=$reason');
    _cancelTimers();
    await _invokeSafely(_methodEndAll, const <String, dynamic>{});
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
    _postEndTimer?.cancel();

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

  static void _schedulePostEndTimer({
    required DateTime postEndsAt,
  }) {
    _postEndTimer?.cancel();
    final now = DateTime.now();
    if (!now.isBefore(postEndsAt)) {
      unawaited(
        _endAllActivities(
          reason: 'post_window_finished',
        ),
      );
      return;
    }
    _postEndTimer = Timer(postEndsAt.difference(now), () {
      _log('post_end_timer_fired');
      unawaited(
        _endAllActivities(
          reason: 'post_window_finished',
        ),
      );
    });
  }

  static void onAppLifecycleChanged(AppLifecycleState state) {
    _log('lifecycle_changed state=$state');
    if (state == AppLifecycleState.resumed) {
      unawaited(maybeStartOrUpdate());
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[IftarLiveActivity] $message');
    }
  }

  static Future<void> _startOrUpdateActivity({
    required DateTime targetDate,
    required DateTime postEndsAt,
  }) async {
    final now = DateTime.now();
    final phase = now.isBefore(targetDate) ? 'countdown' : 'completed';
    final payload = _activityPayload(
      iftarDate: targetDate,
      postEndsAt: postEndsAt,
      phase: phase,
    );
    _log(
      'activity_start iftarEpochMs=${targetDate.millisecondsSinceEpoch} endEpochMs=${postEndsAt.millisecondsSinceEpoch} phase=$phase',
    );
    await _invokeSafely(_methodStart, payload);
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
    final now = DateTime.now();
    _log(
      'start_or_update_called iftarEpochMs=${iftarDate.millisecondsSinceEpoch} nowEpochMs=${now.millisecondsSinceEpoch} iftarIsFuture=${iftarDate.isAfter(now)}',
    );
    final postEndsAt = iftarDate.add(_postWindow);
    await AdhanNotificationService.scheduleIftarPostCleanupNotification(
      postEndsAt: postEndsAt,
      timezoneName: LocalPreferencesService.prayerLocation.value.timezone,
    );
    _schedulePostEndTimer(postEndsAt: postEndsAt);
    await _scheduleBackgroundTasks(
      iftarDate: iftarDate,
      postEndsAt: postEndsAt,
    );
    await _startOrUpdateActivity(
      targetDate: iftarDate,
      postEndsAt: postEndsAt,
    );
    _log(
      'start_or_update_finished iftarEpochMs=${iftarDate.millisecondsSinceEpoch} endEpochMs=${postEndsAt.millisecondsSinceEpoch}',
    );
  }

  static Map<String, dynamic> _activityPayload({
    required DateTime iftarDate,
    required DateTime postEndsAt,
    String phase = 'countdown',
  }) {
    return <String, dynamic>{
      'title': S.get('iftar_countdown_title'),
      'subtitle': S.get('iftar_countdown_subtitle'),
      'lang': LocalPreferencesService.language.value,
      'mode': 'countdown',
      'postMessage': _postMessageForLocale(),
      'phase': phase,
      'iftarEpochMs': iftarDate.millisecondsSinceEpoch,
      'endEpochMs': postEndsAt.millisecondsSinceEpoch,
    };
  }

  static Future<void> _scheduleBackgroundTasks({
    required DateTime iftarDate,
    required DateTime postEndsAt,
  }) async {
    if (!_isIosRuntime || !isSupported.value || !_isFeatureEnabled) {
      return;
    }
    final windowStart = iftarDate.subtract(_countdownWindow);
    _log(
      'bg_schedule_requested startEpochMs=${windowStart.millisecondsSinceEpoch} endEpochMs=${postEndsAt.millisecondsSinceEpoch}',
    );
    await _invokeSafely(
      _methodScheduleBackgroundTasks,
      <String, dynamic>{
        'payload':
            _activityPayload(iftarDate: iftarDate, postEndsAt: postEndsAt),
        'startEpochMs': windowStart.millisecondsSinceEpoch,
        'endEpochMs': postEndsAt.millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> _cancelBackgroundTasks() async {
    if (!_isIosRuntime) return;
    await _invokeSafely(
        _methodCancelBackgroundTasks, const <String, dynamic>{});
  }

  static String _postMessageForLocale() {
    final languageCode = LocalPreferencesService.language.value.toLowerCase();
    if (languageCode == 'tr') return S.get('iftar_post_message_tr');
    return S.get('iftar_post_message_en');
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
    _postEndTimer?.cancel();
    _postEndTimer = null;
  }

  static Future<void> _endAfterPostIfNeeded({
    required DateTime now,
    required PrayerLocation location,
    required String reason,
  }) async {
    if (!_isIosRuntime || !isSupported.value || !location.hasCoordinates) {
      return;
    }
    final todayMaghrib = _maghribFor(now, location);
    final activeMaghrib = now.isBefore(todayMaghrib)
        ? _maghribFor(now.subtract(const Duration(days: 1)), location)
        : todayMaghrib;
    final postEndsAt = activeMaghrib.add(_postWindow);
    if (now.isBefore(postEndsAt)) {
      return;
    }
    await _endAllActivities(
      reason: 'post_window_finished',
    );
    _log(
      'live_activity_end_after_post safety_reason=$reason maghribEpochMs=${activeMaghrib.millisecondsSinceEpoch} postEndsAtEpochMs=${postEndsAt.millisecondsSinceEpoch}',
    );
  }
}

class _IftarLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    IftarLiveActivityService.onAppLifecycleChanged(state);
  }
}
