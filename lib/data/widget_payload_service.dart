import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'daily_ayah_service.dart';
import 'daily_content_service.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';
import 'adhan_times_service.dart';
import 'local_preferences_service.dart';
import 'quran_data.dart';

class WidgetPayloadService {
  WidgetPayloadService._();

  static const String _channelName = 'nurai.widgets';
  static const String _methodSetPayload = 'setNextPrayerPayload';
  static const String _methodSetDailyContentPayload = 'setDailyContentPayload';
  static const String _methodRefreshWidgets = 'refreshWidgets';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static Future<void> writeNextPrayerPayload({bool refresh = true}) async {
    final now = DateTime.now();
    final payload = _buildPayload(now);
    final payloadJson = jsonEncode(payload);
    final dailyContentPayloadJson = jsonEncode(_buildDailyContentPayload(now));

    if (kIsWeb) return;
    try {
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
    final widgetEnabled = LocalPreferencesService.nextPrayerWidgetEnabled.value;
    if (!widgetEnabled) {
      return <String, dynamic>{
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'isWidgetEnabled': false,
        'upcomingPrayers': const <Map<String, dynamic>>[],
      };
    }

    final location = LocalPreferencesService.prayerLocation.value;
    final locationLabel = _locationLabel(location);

    if (!location.hasCoordinates) {
      return <String, dynamic>{
        'generatedAtEpochMs': now.millisecondsSinceEpoch,
        'isWidgetEnabled': true,
        'timeZone': location.timezone ?? now.timeZoneName,
        'upcomingPrayers': const <Map<String, dynamic>>[],
      };
    }

    final upcoming = _buildUpcomingPrayers(now, location);
    final next = upcoming.isNotEmpty ? upcoming.first : _findNextPrayer(now, location);
    return <String, dynamic>{
      'generatedAtEpochMs': now.millisecondsSinceEpoch,
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

  static Map<String, dynamic> _buildDailyContentPayload(DateTime now) {
    final dailyAyah = DailyAyahService.getTodayAyahWithContext(
      QuranData.instance.ayahs,
      QuranData.instance.getSurahName,
    );
    final hadith = DailyContentService.todayHadith;
    final languageCode = LocalPreferencesService.language.value;
    final asma = _asmaForDate(now, languageCode);
    final dateString = _dateString(now);

    return <String, dynamic>{
      'schema': 1,
      'lang': languageCode,
      'date': dateString,
      'verse': <String, dynamic>{
        'title': S.get('daily_ayah'),
        'text': dailyAyah.turkishReadable,
        'ref': dailyAyah.reference,
      },
      'hadith': <String, dynamic>{
        'title': S.get('daily_hadith_title'),
        'text': hadith?.text ?? S.get('daily_hadith_empty'),
        'ref': hadith?.source ?? '',
      },
      'asma': <String, dynamic>{
        'name': '${asma.arabic} - ${asma.transliteration}',
        'meaning': asma.meaningFor(languageCode),
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

  static _AsmaItem _asmaForDate(DateTime date, String languageCode) {
    final index =
        DailyContentService.reminderIndexForDate(date, _asmaItems.length);
    return _asmaItems[index];
  }

  static const List<_AsmaItem> _asmaItems = <_AsmaItem>[
    _AsmaItem(
      arabic: 'الرَّحْمَٰنُ',
      transliteration: 'Ar-Rahman',
      trMeaning: 'Sonsuz merhamet sahibi.',
      enMeaning: 'The Entirely Merciful.',
    ),
    _AsmaItem(
      arabic: 'الرَّحِيمُ',
      transliteration: 'Ar-Rahim',
      trMeaning: 'Ahirette rahmetiyle muamele eden.',
      enMeaning: 'The Especially Merciful.',
    ),
    _AsmaItem(
      arabic: 'الْمَلِكُ',
      transliteration: 'Al-Malik',
      trMeaning: 'Tum alemlerin mutlak sahibi.',
      enMeaning: 'The Absolute Sovereign.',
    ),
    _AsmaItem(
      arabic: 'الْقُدُّوسُ',
      transliteration: 'Al-Quddus',
      trMeaning: 'Her eksiklikten uzak olan.',
      enMeaning: 'The Most Pure.',
    ),
    _AsmaItem(
      arabic: 'السَّلَامُ',
      transliteration: 'As-Salam',
      trMeaning: 'Esenligin ve selametin kaynagi.',
      enMeaning: 'The Source of Peace.',
    ),
    _AsmaItem(
      arabic: 'الْغَفُورُ',
      transliteration: 'Al-Ghafur',
      trMeaning: 'Cokca bagislayan.',
      enMeaning: 'The All-Forgiving.',
    ),
    _AsmaItem(
      arabic: 'الْوَكِيلُ',
      transliteration: 'Al-Wakil',
      trMeaning: 'Kendisine dayanilan en guvenilir vekil.',
      enMeaning: 'The Trustee.',
    ),
    _AsmaItem(
      arabic: 'الْهَادِي',
      transliteration: 'Al-Hadi',
      trMeaning: 'Dogru yola ileten.',
      enMeaning: 'The Guide.',
    ),
  ];

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

    if (tomorrowEntries.isNotEmpty) {
      final tomorrowFajr = tomorrowEntries.first;
      final hasTomorrowFajr = upcoming.any(
        (entry) => entry.key == tomorrowFajr.key && entry.time == tomorrowFajr.time,
      );
      if (!hasTomorrowFajr) {
        upcoming.add(tomorrowFajr);
      }
    }

    if (upcoming.length < 3) {
      for (final entry in tomorrowEntries.skip(1)) {
        upcoming.add(entry);
        if (upcoming.length >= 3) break;
      }
    }

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
}

class _PrayerEntry {
  const _PrayerEntry(this.key, this.label, this.time);

  final String key;
  final String label;
  final DateTime time;
}

class _AsmaItem {
  const _AsmaItem({
    required this.arabic,
    required this.transliteration,
    required this.trMeaning,
    required this.enMeaning,
  });

  final String arabic;
  final String transliteration;
  final String trMeaning;
  final String enMeaning;

  String meaningFor(String languageCode) {
    if (languageCode.toLowerCase() == 'tr') return trMeaning;
    return enMeaning;
  }
}
