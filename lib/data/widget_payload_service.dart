import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/services.dart';

import 'daily_content_service.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';
import 'adhan_times_service.dart';
import 'local_preferences_service.dart';
import 'next_prayer_service.dart';

class WidgetPayloadService {
  WidgetPayloadService._();

  static const String _channelName = 'nurai.widgets';
  static const String _methodSetPayload = 'setNextPrayerPayload';
  static const String _methodSetDailyContentPayload = 'setDailyContentPayload';
  static const String _methodRefreshWidgets = 'refreshWidgets';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WidgetPayload] $message');
    }
  }

  static Future<void> writeNextPrayerPayload({bool refresh = true}) async {
    final now = DateTime.now();
    final payload = _buildPayload(now);
    final payloadJson = jsonEncode(payload);
    final dailyContentPayloadJson = jsonEncode(
      await _buildDailyContentPayload(now),
    );

    if (kIsWeb) return;
    try {
      _log(
        'write_next_prayer_payload generatedAt=${now.millisecondsSinceEpoch} '
        'nextPrayerName=${payload['nextPrayerName'] ?? 'none'} '
        'nextPrayerEpochMs=${payload['nextPrayerTimeEpochMs'] ?? 'none'} '
        'upcomingCount=${(payload['upcomingPrayers'] as List<dynamic>? ?? const []).length}',
      );
      await _channel.invokeMethod<void>(
        _methodSetPayload,
        <String, dynamic>{'payload': payloadJson},
      );
      try {
        await _channel.invokeMethod<void>(
          _methodSetDailyContentPayload,
          <String, dynamic>{'payload': dailyContentPayloadJson},
        );
      } catch (_) {
        // Some platforms may not implement this method yet.
      }
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

    if (!location.hasCoordinates) {
      _log('build_payload missing_location');
      return <String, dynamic>{
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'lang': LocalPreferencesService.language.value,
        'isWidgetEnabled': true,
        'timeZone': location.timezone ?? now.timeZoneName,
        'upcomingPrayers': const <Map<String, dynamic>>[],
      };
    }

    final upcoming = _buildUpcomingPrayers(now, location);
    final next =
        upcoming.isNotEmpty ? upcoming.first : _findNextPrayer(now, location);
    _log(
      'build_payload rollover_check now=${now.millisecondsSinceEpoch} '
      'nextPrayerKey=${next.key} '
      'nextPrayerEpochMs=${next.time.millisecondsSinceEpoch} '
      'upcomingEpochs=${upcoming.map((entry) => entry.time.millisecondsSinceEpoch).join(",")}',
    );
    return <String, dynamic>{
      'generatedAtEpochMs': now.millisecondsSinceEpoch,
      'lang': LocalPreferencesService.language.value,
      'isWidgetEnabled': true,
      'nextPrayerName': next.label,
      'nextPrayerTimeEpochMs': next.time.millisecondsSinceEpoch,
      'timeZone': location.timezone ?? now.timeZoneName,
      'locationLabel': locationLabel,
      'upcomingPrayers': upcoming
          .map(
            (entry) => <String, dynamic>{
              'name': entry.label,
              'timeEpochMs': entry.time.millisecondsSinceEpoch,
            },
          )
          .toList(),
    };
  }

  static Future<Map<String, dynamic>> _buildDailyContentPayload(
    DateTime now,
  ) async {
    final hadith = DailyContentService.todayHadith;
    final languageCode = LocalPreferencesService.language.value;
    final dateString = _dateString(now);

    return <String, dynamic>{
      'schema': 1,
      'lang': languageCode,
      'date': dateString,
      'hadith': <String, dynamic>{
        'title': S.get('daily_hadith_title'),
        'text': hadith?.text ?? S.get('daily_hadith_empty'),
        'ref': hadith?.source ?? '',
      },
      'updatedAt': now.millisecondsSinceEpoch,
    };
  }

  static String _dateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static _PrayerEntry _findNextPrayer(DateTime now, PrayerLocation location) {
    final countryHint = _countryFromPrayerLocation(location);
    final today = AdhanTimesService.computeTimes(
      now,
      location,
      countryHint: countryHint,
    );
    final tomorrow = AdhanTimesService.computeTimes(
      now.add(const Duration(days: 1)),
      location,
      countryHint: countryHint,
    );
    final resolved = NextPrayerService.findNextPrayer(
      now: now,
      todayTimes: today,
      tomorrowTimes: tomorrow,
      logger: _log,
    );
    if (resolved != null) {
      return _PrayerEntry(
        resolved.key,
        _labelForPrayerKey(resolved.key),
        resolved.time,
      );
    }
    return _PrayerEntry('fajr', S.get('fajr'), tomorrow.fajr);
  }

  static List<_PrayerEntry> _buildUpcomingPrayers(
    DateTime now,
    PrayerLocation location,
  ) {
    final nowWithDrift = now.add(const Duration(seconds: 10));
    final todayEntries = _prayerEntriesForDate(now, location);
    final tomorrowEntries = _prayerEntriesForDate(
      now.add(const Duration(days: 1)),
      location,
    );

    final upcoming = <_PrayerEntry>[
      for (final entry in todayEntries)
        if (entry.time.isAfter(nowWithDrift)) entry,
    ];

    for (final entry in tomorrowEntries) {
      final alreadyIncluded = upcoming.any(
        (existing) => existing.key == entry.key && existing.time == entry.time,
      );
      if (!alreadyIncluded) {
        upcoming.add(entry);
      }
    }

    _log(
      'build_upcoming_prayers now=${now.millisecondsSinceEpoch} '
      'todayRemaining=${todayEntries.where((entry) => entry.time.isAfter(nowWithDrift)).length} '
      'tomorrowIncluded=${tomorrowEntries.length}',
    );
    return upcoming;
  }

  static List<_PrayerEntry> _prayerEntriesForDate(
    DateTime date,
    PrayerLocation location,
  ) {
    final day = AdhanTimesService.computeTimes(
      date,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    return <_PrayerEntry>[
      _PrayerEntry('fajr', S.get('fajr'), day.fajr),
      _PrayerEntry('dhuhr', S.get('dhuhr'), day.dhuhr),
      _PrayerEntry('asr', S.get('asr'), day.asr),
      _PrayerEntry('maghrib', S.get('maghrib'), day.maghrib),
      _PrayerEntry('isha', S.get('isha'), day.isha),
    ];
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

  static String _labelForPrayerKey(String key) {
    return switch (key) {
      'fajr' => S.get('fajr'),
      'dhuhr' => S.get('dhuhr'),
      'asr' => S.get('asr'),
      'maghrib' => S.get('maghrib'),
      'isha' => S.get('isha'),
      _ => key,
    };
  }
}

class _PrayerEntry {
  const _PrayerEntry(this.key, this.label, this.time);

  final String key;
  final String label;
  final DateTime time;
}
