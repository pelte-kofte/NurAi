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

  static NextPrayerEntry? findNextPrayerForToday({
    required DateTime now,
    required AdhanDayTimes times,
  }) {
    final rows = <NextPrayerEntry>[
      NextPrayerEntry(key: 'fajr', time: times.fajr),
      NextPrayerEntry(key: 'dhuhr', time: times.dhuhr),
      NextPrayerEntry(key: 'asr', time: times.asr),
      NextPrayerEntry(key: 'maghrib', time: times.maghrib),
      NextPrayerEntry(key: 'isha', time: times.isha),
    ];

    for (final row in rows) {
      if (row.time.isAfter(now)) return row;
    }
    return null;
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
