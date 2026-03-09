import 'dart:async';

import 'package:flutter/material.dart';

import '../data/adhan_times_service.dart';
import '../data/local_preferences_service.dart';
import '../data/next_prayer_service.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_location.dart';

class NextPrayerPill extends StatefulWidget {
  const NextPrayerPill({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<NextPrayerPill> createState() => _NextPrayerPillState();
}

class _NextPrayerPillState extends State<NextPrayerPill> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 1-second updates keep countdown and prayer rollover in sync.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PrayerLocation>(
      valueListenable: LocalPreferencesService.prayerLocation,
      builder: (context, location, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final text = _buildPillText(context, location);
        return GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 17,
                  color: colorScheme.onSurface.withValues(alpha: 0.62),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildPillText(BuildContext context, PrayerLocation location) {
    if (!location.hasCoordinates) {
      return S.get('next_prayer_set_location_cta');
    }

    final now = _now.toLocal();
    final todayTimes = AdhanTimesService.computeTimes(
      now,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final tomorrowTimes = AdhanTimesService.computeTimes(
      now.add(const Duration(days: 1)),
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final next = NextPrayerService.findNextPrayer(
      now: now,
      todayTimes: todayTimes,
      tomorrowTimes: tomorrowTimes,
      logger: (message) {
        assert(() {
          debugPrint('[NextPrayerPill] $message');
          return true;
        }());
      },
    );
    if (next == null) {
      assert(() {
        debugPrint('[NextPrayerPill] next_prayer_none_today_shown');
        return true;
      }());
      return S.get('next_prayer_none_title');
    }
    final nextPrayerDateTime = next.time.toLocal();
    final remaining = NextPrayerService.remaining(
      now: DateTime.now().toLocal(),
      target: nextPrayerDateTime,
    );

    final localizations = MaterialLocalizations.of(context);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(nextPrayerDateTime),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final prayerLabel = _labelForKey(next.key);

    assert(() {
      final realDiff = nextPrayerDateTime.difference(DateTime.now().toLocal());
      debugPrint(
        '[NextPrayerPill] prayer=$prayerLabel time=$timeText '
        'remaining=${remaining.inMinutes}m '
        'realDiff=${realDiff.inMinutes}m',
      );
      return true;
    }());

    if (remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    }

    return '$prayerLabel - $timeText - ${_remainingText(remaining)}';
  }

  String _remainingText(Duration remaining) {
    final totalMinutes = remaining.inMinutes <= 0 ? 1 : remaining.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final prefix = S.get('next_prayer_in_prefix');
    final hourUnit = S.get('next_prayer_hour_short');
    final minuteUnit = S.get('next_prayer_min_short');
    final suffix = S.get('next_prayer_remaining_suffix');

    if (hours > 0 && minutes > 0) {
      return '$prefix$hours$hourUnit $minutes$minuteUnit$suffix';
    }
    if (hours > 0) {
      return '$prefix$hours$hourUnit$suffix';
    }
    return '$prefix$minutes$minuteUnit$suffix';
  }

  String _labelForKey(String key) {
    switch (key) {
      case 'fajr':
        return S.get('fajr');
      case 'dhuhr':
        return S.get('dhuhr');
      case 'asr':
        return S.get('asr');
      case 'maghrib':
        return S.get('maghrib');
      case 'isha':
      default:
        return S.get('isha');
    }
  }

  String? _countryFromPrayerLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final raw = location.cityName ?? '';
    final parts = raw.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }
}
