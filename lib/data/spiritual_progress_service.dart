import 'package:shared_preferences/shared_preferences.dart';

import 'collective_reading_service.dart';

enum ReflectionPeriod { morning, evening }

class SpiritualReadResult {
  const SpiritualReadResult({
    required this.state,
    required this.dailyGoalCompletedNow,
    required this.streakContinued,
  });

  final SpiritualProgressState state;
  final bool dailyGoalCompletedNow;
  final bool streakContinued;
}

class ReflectionCompletionResult {
  const ReflectionCompletionResult({
    required this.reflectionStreakCount,
    required this.completedNow,
    required this.streakContinued,
  });

  final int reflectionStreakCount;
  final bool completedNow;
  final bool streakContinued;
}

class SpiritualProgressState {
  const SpiritualProgressState({
    required this.streakCount,
    required this.lastReadDate,
    required this.currentJuz,
    required this.highestCompletedJuz,
    required this.completedJuzCount,
    required this.allJuzCompleted,
    required this.dailyGoalDone,
    required this.dailyGoalDate,
    required this.reflectionStreakCount,
    required this.reflectionLastCompletedDate,
    required this.morningReflectionCompletedDate,
    required this.eveningReflectionCompletedDate,
  });

  final int streakCount;
  final String? lastReadDate;
  final int currentJuz;
  final int highestCompletedJuz;
  final int completedJuzCount;
  final bool allJuzCompleted;
  final bool dailyGoalDone;
  final String? dailyGoalDate;
  final int reflectionStreakCount;
  final String? reflectionLastCompletedDate;
  final String? morningReflectionCompletedDate;
  final String? eveningReflectionCompletedDate;
}

class SpiritualProgressService {
  SpiritualProgressService._();

  static const _keyStreakCount = 'spiritual_streak_count';
  static const _keyLastReadDate = 'spiritual_last_read_date';
  static const _keyCurrentJuz = 'spiritual_current_juz';
  static const _keyDailyGoalDone = 'spiritual_daily_goal_done';
  static const _keyDailyGoalDate = 'spiritual_daily_goal_date';
  static const _keyReflectionStreakCount = 'reflection_streak_count';
  static const _keyReflectionLastCompletedDate =
      'reflection_last_completed_date';
  static const _keyMorningReflectionCompletedDate =
      'morning_reflection_completed_date';
  static const _keyEveningReflectionCompletedDate =
      'evening_reflection_completed_date';
  static const _keyMorningReflectionMessageIndex =
      'morning_reflection_message_index';
  static const _keyEveningReflectionMessageIndex =
      'evening_reflection_message_index';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<SpiritualProgressState> loadState() async {
    final prefs = await _instance();
    final todayKey = _dateKey(DateTime.now());
    final storedDailyGoalDate = prefs.getString(_keyDailyGoalDate);
    var dailyGoalDone = prefs.getBool(_keyDailyGoalDone) ?? false;

    if (storedDailyGoalDate != todayKey && dailyGoalDone) {
      dailyGoalDone = false;
      await prefs.setBool(_keyDailyGoalDone, false);
    }

    final completedJuzs = CollectiveReadingService.getCompletedJuzs();
    final highestCompletedJuz = completedJuzs.isEmpty ? 0 : completedJuzs.last;
    final completedJuzCount = completedJuzs.length;
    final allJuzCompleted = completedJuzCount >= 30;
    final currentJuz = allJuzCompleted
        ? 30
        : highestCompletedJuz > 0
            ? (highestCompletedJuz + 1).clamp(1, 30)
            : 1;

    return SpiritualProgressState(
      streakCount: prefs.getInt(_keyStreakCount) ?? 0,
      lastReadDate: prefs.getString(_keyLastReadDate),
      currentJuz: currentJuz,
      highestCompletedJuz: highestCompletedJuz,
      completedJuzCount: completedJuzCount,
      allJuzCompleted: allJuzCompleted,
      dailyGoalDone: dailyGoalDone && storedDailyGoalDate == todayKey,
      dailyGoalDate: storedDailyGoalDate,
      reflectionStreakCount: prefs.getInt(_keyReflectionStreakCount) ?? 0,
      reflectionLastCompletedDate:
          prefs.getString(_keyReflectionLastCompletedDate),
      morningReflectionCompletedDate:
          prefs.getString(_keyMorningReflectionCompletedDate),
      eveningReflectionCompletedDate:
          prefs.getString(_keyEveningReflectionCompletedDate),
    );
  }

  static Future<SpiritualReadResult> recordRead(int surah, int ayah) async {
    final prefs = await _instance();
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastReadDate = prefs.getString(_keyLastReadDate);
    final storedDailyGoalDate = prefs.getString(_keyDailyGoalDate);
    final wasDailyGoalDoneToday = (prefs.getBool(_keyDailyGoalDone) ?? false) &&
        storedDailyGoalDate == todayKey;
    final streakContinued =
        lastReadDate == _dateKey(today.subtract(const Duration(days: 1)));
    var streakCount = prefs.getInt(_keyStreakCount) ?? 0;

    if (lastReadDate == todayKey) {
      if (streakCount <= 0) {
        streakCount = 1;
      }
    } else if (lastReadDate ==
        _dateKey(today.subtract(const Duration(days: 1)))) {
      streakCount = streakCount <= 0 ? 1 : streakCount + 1;
    } else {
      streakCount = 1;
    }

    await prefs.setInt(_keyStreakCount, streakCount);
    await prefs.setString(_keyLastReadDate, todayKey);

    final juzNumber = _resolveJuzNumber(surah, ayah);
    if (juzNumber != null) {
      await prefs.setInt(_keyCurrentJuz, juzNumber);
    }

    await prefs.setBool(_keyDailyGoalDone, true);
    await prefs.setString(_keyDailyGoalDate, todayKey);

    return SpiritualReadResult(
      state: await loadState(),
      dailyGoalCompletedNow: !wasDailyGoalDoneToday,
      streakContinued: streakContinued,
    );
  }

  static Future<ReflectionCompletionResult> completeReflection(
    ReflectionPeriod period,
  ) async {
    final prefs = await _instance();
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final periodKey = switch (period) {
      ReflectionPeriod.morning => _keyMorningReflectionCompletedDate,
      ReflectionPeriod.evening => _keyEveningReflectionCompletedDate,
    };
    final lastPeriodCompletion = prefs.getString(periodKey);
    if (lastPeriodCompletion == todayKey) {
      return ReflectionCompletionResult(
        reflectionStreakCount: prefs.getInt(_keyReflectionStreakCount) ?? 0,
        completedNow: false,
        streakContinued: false,
      );
    }

    await prefs.setString(periodKey, todayKey);

    final lastReflectionDate = prefs.getString(_keyReflectionLastCompletedDate);
    if (lastReflectionDate == todayKey) {
      return ReflectionCompletionResult(
        reflectionStreakCount: prefs.getInt(_keyReflectionStreakCount) ?? 0,
        completedNow: true,
        streakContinued: false,
      );
    }

    var streakCount = prefs.getInt(_keyReflectionStreakCount) ?? 0;
    final streakContinued =
        lastReflectionDate == _dateKey(today.subtract(const Duration(days: 1)));
    if (streakContinued) {
      streakCount = streakCount <= 0 ? 1 : streakCount + 1;
    } else {
      streakCount = 1;
    }

    await prefs.setInt(_keyReflectionStreakCount, streakCount);
    await prefs.setString(_keyReflectionLastCompletedDate, todayKey);
    return ReflectionCompletionResult(
      reflectionStreakCount: streakCount,
      completedNow: true,
      streakContinued: streakContinued,
    );
  }

  static Future<int> nextReflectionMessageIndex(ReflectionPeriod period) async {
    final prefs = await _instance();
    final key = switch (period) {
      ReflectionPeriod.morning => _keyMorningReflectionMessageIndex,
      ReflectionPeriod.evening => _keyEveningReflectionMessageIndex,
    };
    final current = prefs.getInt(key) ?? 0;
    final next = (current + 1) % 3;
    await prefs.setInt(key, next);
    return current;
  }

  static int? _resolveJuzNumber(int surah, int ayah) {
    for (final range in CollectiveReadingService.juzRanges) {
      if (range.containsAyah(surah, ayah)) {
        return range.juzNumber;
      }
    }
    return null;
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
