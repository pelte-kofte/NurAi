import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'collective_reading_service.dart';
import 'local_data_recovery.dart';

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
    final storedDailyGoalDate =
        await _readCanonicalDateKey(prefs, _keyDailyGoalDate);
    var dailyGoalDone = LocalDataRecovery.getBool(prefs, _keyDailyGoalDone);

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
      streakCount: _sanitizeNonNegativeInt(
        prefs,
        _keyStreakCount,
      ),
      lastReadDate: await _readCanonicalDateKey(prefs, _keyLastReadDate),
      currentJuz: currentJuz,
      highestCompletedJuz: highestCompletedJuz,
      completedJuzCount: completedJuzCount,
      allJuzCompleted: allJuzCompleted,
      dailyGoalDone: dailyGoalDone && storedDailyGoalDate == todayKey,
      dailyGoalDate: storedDailyGoalDate,
      reflectionStreakCount: _sanitizeNonNegativeInt(
        prefs,
        _keyReflectionStreakCount,
      ),
      reflectionLastCompletedDate: await _readCanonicalDateKey(
        prefs,
        _keyReflectionLastCompletedDate,
      ),
      morningReflectionCompletedDate: await _readCanonicalDateKey(
          prefs, _keyMorningReflectionCompletedDate),
      eveningReflectionCompletedDate: await _readCanonicalDateKey(
          prefs, _keyEveningReflectionCompletedDate),
    );
  }

  static Future<SpiritualReadResult> recordRead(int surah, int ayah) async {
    final prefs = await _instance();
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastReadDate = await _readCanonicalDateKey(prefs, _keyLastReadDate);
    final storedDailyGoalDate =
        await _readCanonicalDateKey(prefs, _keyDailyGoalDate);
    final wasDailyGoalDoneToday =
        LocalDataRecovery.getBool(prefs, _keyDailyGoalDone) &&
            storedDailyGoalDate == todayKey;
    final streakContinued =
        lastReadDate == _dateKey(today.subtract(const Duration(days: 1)));
    var streakCount = _sanitizeNonNegativeInt(prefs, _keyStreakCount);

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
    return _completeReflectionForDate(period, DateTime.now(), prefs);
  }

  static Future<ReflectionCompletionResult> _completeReflectionForDate(
    ReflectionPeriod period,
    DateTime now,
    SharedPreferences prefs,
  ) async {
    final todayKey = _dateKey(now);
    final periodKey = switch (period) {
      ReflectionPeriod.morning => _keyMorningReflectionCompletedDate,
      ReflectionPeriod.evening => _keyEveningReflectionCompletedDate,
    };
    final lastPeriodCompletion = await _readCanonicalDateKey(prefs, periodKey);
    if (lastPeriodCompletion == todayKey) {
      return ReflectionCompletionResult(
        reflectionStreakCount:
            _sanitizeNonNegativeInt(prefs, _keyReflectionStreakCount),
        completedNow: false,
        streakContinued: false,
      );
    }

    await prefs.setString(periodKey, todayKey);

    final lastReflectionDate = await _readCanonicalDateKey(
      prefs,
      _keyReflectionLastCompletedDate,
    );
    if (lastReflectionDate == todayKey) {
      return ReflectionCompletionResult(
        reflectionStreakCount:
            _sanitizeNonNegativeInt(prefs, _keyReflectionStreakCount),
        completedNow: true,
        streakContinued: false,
      );
    }

    var streakCount = _sanitizeNonNegativeInt(prefs, _keyReflectionStreakCount);
    final dayGap = _dayGap(lastReflectionDate, todayKey);
    final streakContinued = dayGap == 1;
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

  static Future<String?> _readCanonicalDateKey(
    SharedPreferences prefs,
    String key,
  ) async {
    final rawValue = LocalDataRecovery.getString(prefs, key);
    final normalized = _normalizeDateKey(rawValue);
    if (normalized != null && normalized != rawValue) {
      await prefs.setString(key, normalized);
    }
    if (normalized == null && rawValue != null && rawValue.isNotEmpty) {
      await LocalDataRecovery.clearPrefsKeys(prefs, [key]);
    }
    return normalized;
  }

  static String? _normalizeDateKey(String? value) {
    if (value == null || value.isEmpty) return null;
    final directMatch = RegExp(r'^\d{4}-\d{2}-\d{2}$').firstMatch(value);
    if (directMatch != null) {
      return directMatch.group(0);
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return _dateKey(parsed.toLocal());
  }

  static int? _dayGap(String? earlierDateKey, String laterDateKey) {
    final earlier = _dateFromKey(earlierDateKey);
    final later = _dateFromKey(laterDateKey);
    if (earlier == null || later == null) return null;
    return later.difference(earlier).inDays;
  }

  static DateTime? _dateFromKey(String? value) {
    final normalized = _normalizeDateKey(value);
    if (normalized == null) return null;
    final parts = normalized.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static Future<int> nextReflectionMessageIndex(ReflectionPeriod period) async {
    final prefs = await _instance();
    final key = switch (period) {
      ReflectionPeriod.morning => _keyMorningReflectionMessageIndex,
      ReflectionPeriod.evening => _keyEveningReflectionMessageIndex,
    };
    final current = _sanitizeNonNegativeInt(prefs, key) % 3;
    final next = (current + 1) % 3;
    await prefs.setInt(key, next);
    return current;
  }

  static int _sanitizeNonNegativeInt(SharedPreferences prefs, String key) {
    final value = LocalDataRecovery.getInt(prefs, key) ?? 0;
    if (value >= 0) return value;
    unawaited(LocalDataRecovery.clearPrefsKeys(prefs, [key]));
    return 0;
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

  static Future<ReflectionCompletionResult> completeReflectionForTesting({
    required ReflectionPeriod period,
    required DateTime now,
  }) async {
    final prefs = await _instance();
    return _completeReflectionForDate(period, now, prefs);
  }

  static void resetForTesting() {
    _prefs = null;
  }
}
