import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';
import 'adhan_times_service.dart';
import 'local_preferences_service.dart';

class WidgetPayloadService {
  WidgetPayloadService._();

  static const String _channelName = 'nurai.widgets';
  static const String _methodSetPayload = 'setNextPrayerPayload';
  static const String _methodRefreshWidgets = 'refreshWidgets';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static Future<void> writeNextPrayerPayload({bool refresh = true}) async {
    final payload = _buildPayload(DateTime.now());
    final payloadJson = jsonEncode(payload);

    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>(
        _methodSetPayload,
        <String, dynamic>{'payload': payloadJson},
      );
      if (refresh) {
        await refreshWidgets();
      }
    } catch (_) {
      // Widgets are optional; ignore channel failures.
    }
  }

  static Future<void> refreshWidgets() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>(_methodRefreshWidgets);
    } catch (_) {
      // Best effort only.
    }
  }

  static Map<String, dynamic> _buildPayload(DateTime now) {
    final location = LocalPreferencesService.prayerLocation.value;
    final locationLabel = _locationLabel(location);
    final notificationsEnabled = LocalPreferencesService.adhanEnabled.value;

    if (!location.hasCoordinates) {
      return <String, dynamic>{
        'updatedAtEpochMs': now.millisecondsSinceEpoch,
        'locationLabel': locationLabel,
        'nextPrayerKey': '',
        'nextPrayerLabel': S.get('prayer_times_no_location'),
        'nextPrayerTime': '--:--',
        'countdownLabel': S.get('next_prayer_set_location_cta'),
        'isNotificationsEnabled': notificationsEnabled,
      };
    }

    final next = _findNextPrayer(now, location);
    return <String, dynamic>{
      'updatedAtEpochMs': now.millisecondsSinceEpoch,
      'locationLabel': locationLabel,
      'nextPrayerKey': next.key,
      'nextPrayerLabel': next.label,
      'nextPrayerTime': AdhanTimesService.formatHHmm(next.time),
      'countdownLabel': _countdownLabel(now, next.time),
      'isNotificationsEnabled': notificationsEnabled,
    };
  }

  static _PrayerEntry _findNextPrayer(DateTime now, PrayerLocation location) {
    final today = AdhanTimesService.computeTimes(
      now,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final todaysEntries = <_PrayerEntry>[
      _PrayerEntry('fajr', S.get('fajr'), today.fajr),
      _PrayerEntry('dhuhr', S.get('dhuhr'), today.dhuhr),
      _PrayerEntry('asr', S.get('asr'), today.asr),
      _PrayerEntry('maghrib', S.get('maghrib'), today.maghrib),
      _PrayerEntry('isha', S.get('isha'), today.isha),
    ];
    for (final entry in todaysEntries) {
      if (entry.time.isAfter(now)) return entry;
    }

    final tomorrowDate = now.add(const Duration(days: 1));
    final tomorrow = AdhanTimesService.computeTimes(
      tomorrowDate,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    return _PrayerEntry('fajr', S.get('fajr'), tomorrow.fajr);
  }

  static String _countdownLabel(DateTime now, DateTime target) {
    final diff = target.difference(now);
    if (diff.isNegative) {
      return '${S.get('next_prayer_in_prefix')} 0${S.get('next_prayer_min_short')}';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours <= 0) {
      return '${S.get('next_prayer_in_prefix')} $minutes${S.get('next_prayer_min_short')}';
    }
    return '${S.get('next_prayer_in_prefix')} '
        '$hours${S.get('next_prayer_hour_short')} '
        '$minutes${S.get('next_prayer_min_short')}';
  }

  static String _locationLabel(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) {
      return S.get('prayer_times_current_prefix');
    }
    final city = (location.cityName ?? '').trim();
    if (city.isNotEmpty) return city;
    return S.get('prayer_times_no_location');
  }

  static String? _countryFromPrayerLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final raw = location.cityName ?? '';
    final parts = raw.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }
}

class _PrayerEntry {
  const _PrayerEntry(this.key, this.label, this.time);

  final String key;
  final String label;
  final DateTime time;
}
