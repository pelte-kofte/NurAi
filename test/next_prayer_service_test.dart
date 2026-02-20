import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/adhan_times_service.dart';
import 'package:nurai/data/next_prayer_service.dart';

void main() {
  group('NextPrayerService', () {
    test('uses the same DateTime for display source and countdown', () {
      final now = DateTime(2026, 3, 1, 11, 30);
      final times = AdhanDayTimes(
        fajr: DateTime(2026, 3, 1, 5, 30),
        sunrise: DateTime(2026, 3, 1, 7, 0),
        dhuhr: DateTime(2026, 3, 1, 12, 45),
        asr: DateTime(2026, 3, 1, 16, 10),
        maghrib: DateTime(2026, 3, 1, 19, 2),
        isha: DateTime(2026, 3, 1, 20, 30),
      );

      final next =
          NextPrayerService.findNextPrayerForToday(now: now, times: times);
      expect(next, isNotNull);
      expect(next!.key, 'dhuhr');

      final displayedNextPrayerDateTime = next.time;
      final countdownTargetDateTime = next.time;
      final remaining = NextPrayerService.remaining(
        now: now,
        target: countdownTargetDateTime,
      );

      expect(displayedNextPrayerDateTime, countdownTargetDateTime);
      expect(remaining.inMinutes,
          displayedNextPrayerDateTime.difference(now).inMinutes);
    });

    test('clamps negative remaining to zero', () {
      final now = DateTime(2026, 3, 1, 13, 0);
      final target = DateTime(2026, 3, 1, 12, 59, 30);

      final remaining = NextPrayerService.remaining(now: now, target: target);
      expect(remaining, Duration.zero);
    });
  });
}
