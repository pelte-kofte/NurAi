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
  static const Color _secondaryIconColor = Color(0x992B2725);

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
              color: const Color(0xFFF3ECE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 17,
                  color: _secondaryIconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5F5954),
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
    final times = AdhanTimesService.computeTimes(
      now,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final next =
        NextPrayerService.findNextPrayerForToday(now: now, times: times);
    if (next == null) {
      return S.get('next_prayer_done_today');
    }
    final nextPrayerDateTime =
        _resolvePrayerTimeForKey(next.key, times).toLocal();
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
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours <= 0) {
      return '${S.get('next_prayer_in_prefix')} $minutes${S.get('next_prayer_min_short')}';
    }
    return '${S.get('next_prayer_in_prefix')} '
        '$hours${S.get('next_prayer_hour_short')} '
        '$minutes${S.get('next_prayer_min_short')}';
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

  DateTime _resolvePrayerTimeForKey(String key, AdhanDayTimes times) {
    switch (key) {
      case 'fajr':
        return times.fajr;
      case 'dhuhr':
        return times.dhuhr;
      case 'asr':
        return times.asr;
      case 'maghrib':
        return times.maghrib;
      case 'isha':
      default:
        return times.isha;
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
