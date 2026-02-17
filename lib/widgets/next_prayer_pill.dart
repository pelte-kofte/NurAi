import 'dart:async';

import 'package:flutter/material.dart';

import '../data/adhan_times_service.dart';
import '../data/local_preferences_service.dart';
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
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
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

    final times = AdhanTimesService.computeTimes(
      _now,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final rows = <_PrayerRow>[
      _PrayerRow(S.get('fajr'), times.fajr),
      _PrayerRow(S.get('dhuhr'), times.dhuhr),
      _PrayerRow(S.get('asr'), times.asr),
      _PrayerRow(S.get('maghrib'), times.maghrib),
      _PrayerRow(S.get('isha'), times.isha),
    ];
    final next = _findNextPrayer(rows);
    if (next == null) {
      return S.get('next_prayer_done_today');
    }

    final localizations = MaterialLocalizations.of(context);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(next.time),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    return '${next.label} - $timeText - ${_remainingText(next.time)}';
  }

  _PrayerRow? _findNextPrayer(List<_PrayerRow> rows) {
    for (final row in rows) {
      if (row.time.isAfter(_now)) return row;
    }
    return null;
  }

  String _remainingText(DateTime target) {
    final diff = target.difference(_now);
    if (diff.isNegative) return '0m';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours <= 0) {
      return '${S.get('next_prayer_in_prefix')} $minutes${S.get('next_prayer_min_short')}';
    }
    return '${S.get('next_prayer_in_prefix')} '
        '$hours${S.get('next_prayer_hour_short')} '
        '$minutes${S.get('next_prayer_min_short')}';
  }

  String? _countryFromPrayerLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final raw = location.cityName ?? '';
    final parts = raw.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }
}

class _PrayerRow {
  const _PrayerRow(this.label, this.time);
  final String label;
  final DateTime time;
}
