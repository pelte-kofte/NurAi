import 'adhan_times_service.dart';

class NextPrayerEntry {
  const NextPrayerEntry({
    required this.key,
    required this.time,
  });

  final String key;
  final DateTime time;
}

class NextPrayerService {
  NextPrayerService._();

  static const Duration _clockDriftTolerance = Duration(seconds: 10);

  static NextPrayerEntry? findNextPrayerForToday({
    required DateTime now,
    required AdhanDayTimes times,
  }) {
    return findNextPrayer(
      now: now,
      todayTimes: times,
      tomorrowTimes: null,
    );
  }

  static NextPrayerEntry? findNextPrayer({
    required DateTime now,
    required AdhanDayTimes todayTimes,
    AdhanDayTimes? tomorrowTimes,
    void Function(String message)? logger,
  }) {
    final rows = <NextPrayerEntry>[
      NextPrayerEntry(key: 'fajr', time: todayTimes.fajr),
      NextPrayerEntry(key: 'dhuhr', time: todayTimes.dhuhr),
      NextPrayerEntry(key: 'asr', time: todayTimes.asr),
      NextPrayerEntry(key: 'maghrib', time: todayTimes.maghrib),
      NextPrayerEntry(key: 'isha', time: todayTimes.isha),
    ];
    final nowWithDrift = now.add(_clockDriftTolerance);

    logger?.call(
      'next_prayer_decision nowEpochMs=${now.millisecondsSinceEpoch} '
      'dayStart=${DateTime(now.year, now.month, now.day).millisecondsSinceEpoch} '
      'dayEnd=${DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch} '
      'todayPrayerEpochs=${rows.map((e) => e.time.millisecondsSinceEpoch).join(",")}',
    );

    for (final row in rows) {
      if (row.time.isAfter(nowWithDrift)) {
        logger?.call(
          'next_prayer_selected selectedPrayerName=${row.key} selectedPrayerTime=${row.time.millisecondsSinceEpoch}',
        );
        return row;
      }
    }

    if (tomorrowTimes == null) {
      logger?.call('next_prayer_none_today_shown');
      return null;
    }

    final tomorrowFirst =
        NextPrayerEntry(key: 'fajr', time: tomorrowTimes.fajr);
    logger?.call(
      'next_prayer_selected selectedPrayerName=${tomorrowFirst.key} selectedPrayerTime=${tomorrowFirst.time.millisecondsSinceEpoch}',
    );
    return tomorrowFirst;
  }

  static Duration remaining({
    required DateTime now,
    required DateTime target,
  }) {
    final diff = target.difference(now);
    if (diff.isNegative) return Duration.zero;
    return diff;
  }
}
