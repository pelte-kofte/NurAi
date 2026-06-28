import 'package:flutter_test/flutter_test.dart';
import 'package:nurai/data/spiritual_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpiritualProgressService.resetForTesting();
  });

  group('SpiritualProgressService reflection streaks', () {
    test('increments on consecutive calendar days', () async {
      final dayOne =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 20, 23, 30),
      );
      final dayTwo =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 21, 8, 0),
      );

      expect(dayOne.reflectionStreakCount, 1);
      expect(dayTwo.reflectionStreakCount, 2);
      expect(dayTwo.streakContinued, isTrue);
    });

    test('does not increment multiple times on the same day', () async {
      final morning =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.morning,
        now: DateTime(2026, 4, 21, 7, 0),
      );
      final evening =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 21, 21, 0),
      );
      final repeatedEvening =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 21, 22, 0),
      );

      expect(morning.reflectionStreakCount, 1);
      expect(evening.reflectionStreakCount, 1);
      expect(evening.completedNow, isTrue);
      expect(evening.streakContinued, isFalse);
      expect(repeatedEvening.reflectionStreakCount, 1);
      expect(repeatedEvening.completedNow, isFalse);
    });

    test('resets to 1 when more than one day is skipped', () async {
      await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 18, 21, 0),
      );
      final afterGap =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 21, 21, 0),
      );

      expect(afterGap.reflectionStreakCount, 1);
      expect(afterGap.streakContinued, isFalse);
    });

    test('normalizes legacy timestamp values to calendar days', () async {
      SharedPreferences.setMockInitialValues({
        'reflection_streak_count': 4,
        'reflection_last_completed_date': '2026-04-20T23:45:00.000Z',
      });
      SpiritualProgressService.resetForTesting();

      final result =
          await SpiritualProgressService.completeReflectionForTesting(
        period: ReflectionPeriod.evening,
        now: DateTime(2026, 4, 21, 22, 0),
      );
      final state = await SpiritualProgressService.loadState();

      expect(result.reflectionStreakCount, 5);
      expect(state.reflectionLastCompletedDate, '2026-04-21');
    });
  });
}
