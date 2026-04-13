import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/adhan_notification_service.dart';
import '../../data/adhan_times_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/next_prayer_service.dart';
import '../../data/prayer_location_service.dart';
import '../../data/widget_payload_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/prayer_location.dart';
import '../../theme/app_theme.dart';
import 'city_picker_screen.dart';

class AdhanTimesScreen extends StatefulWidget {
  const AdhanTimesScreen({super.key});

  @override
  State<AdhanTimesScreen> createState() => _AdhanTimesScreenState();
}

class _AdhanTimesScreenState extends State<AdhanTimesScreen> {
  bool _isLoading = true;
  String? _inlineMessage;
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _bootstrap();
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

  Future<void> _bootstrap() async {
    if (LocalPreferencesService.adhanEnabled.value) {
      await AdhanNotificationService.rescheduleForToday();
    }
    await WidgetPayloadService.writeNextPrayerPayload();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('prayer_times_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF2B2725),
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<PrayerLocation>(
        valueListenable: LocalPreferencesService.prayerLocation,
        builder: (context, location, _) {
          if (_isLoading) {
            return Center(
              child: Text(
                S.get('prayer_times_loading'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7A746F),
                ),
              ),
            );
          }

          final now = _now.toLocal();
          final todayTimes = AdhanTimesService.computeTimes(
            now,
            location,
            countryHint: _countryFromLocation(location),
          );
          final tomorrowTimes = AdhanTimesService.computeTimes(
            now.add(const Duration(days: 1)),
            location,
            countryHint: _countryFromLocation(location),
          );
          final nextPrayer = NextPrayerService.findNextPrayer(
            now: now,
            todayTimes: todayTimes,
            tomorrowTimes: tomorrowTimes,
          );
          final activePrayerKey = nextPrayer?.key;
          final rows = _buildPrayerRows(todayTimes, activePrayerKey);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _HeroCard(
                prayer: nextPrayer,
                location: location,
                now: now,
                locationLabel: _selectedLocationLabel(location),
                remainingText: nextPrayer == null
                    ? null
                    : _remainingText(
                        NextPrayerService.remaining(
                          now: now,
                          target: nextPrayer.time.toLocal(),
                        ),
                      ),
                labelForKey: _labelForKey,
              ),
              const SizedBox(height: 16),
              _buildLocationPanel(location),
              const SizedBox(height: 22),
              _buildScheduleHeader(context),
              const SizedBox(height: 12),
              _ScheduleCard(rows: rows),
            ],
          );
        },
      ),
    );
  }

  List<_PrayerRowData> _buildPrayerRows(
    AdhanDayTimes times,
    String? activePrayerKey,
  ) {
    return <_PrayerRowData>[
      _PrayerRowData(
        key: 'fajr',
        label: S.get('fajr'),
        time: times.fajr,
        isHighlighted: activePrayerKey == 'fajr',
      ),
      _PrayerRowData(
        key: 'dhuhr',
        label: S.get('dhuhr'),
        time: times.dhuhr,
        isHighlighted: activePrayerKey == 'dhuhr',
      ),
      _PrayerRowData(
        key: 'asr',
        label: S.get('asr'),
        time: times.asr,
        isHighlighted: activePrayerKey == 'asr',
      ),
      _PrayerRowData(
        key: 'maghrib',
        label: S.get('maghrib'),
        time: times.maghrib,
        isHighlighted: activePrayerKey == 'maghrib',
      ),
      _PrayerRowData(
        key: 'isha',
        label: S.get('isha'),
        time: times.isha,
        isHighlighted: activePrayerKey == 'isha',
      ),
    ];
  }

  Widget _buildLocationPanel(PrayerLocation location) {
    final bool hasCoordinates = location.hasCoordinates;
    final bool isCurrentLocationActive =
        location.mode == PrayerLocationMode.current && hasCoordinates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.86),
            const Color(0xFFF8F1E8).withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAE1D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A8F7E6E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: Color(0xFF756455),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.get('location'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A8077),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedLocationLabel(location),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2725),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_inlineMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _inlineMessage!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF776F68),
                  height: 1.35,
                ),
              ),
            ),
          ] else if (!hasCoordinates) ...[
            const SizedBox(height: 12),
            Text(
              S.get('prayer_times_location_required'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF8A8077),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (isCurrentLocationActive)
                _CompactActionChip(
                  icon: Icons.my_location_rounded,
                  label: S.get('prayer_times_location_active'),
                  onTap: () {},
                )
              else
                _CompactActionChip(
                  icon: Icons.my_location_rounded,
                  label: S.get('prayer_times_use_current'),
                  onTap: _useCurrentLocation,
                ),
              _CompactActionChip(
                icon: Icons.location_city_rounded,
                label: S.get('prayer_times_choose_city'),
                onTap: _chooseCity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          S.get('prayer_times_today'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF2B2725),
              ),
        ),
        const Spacer(),
        Text(
          S.get('prayer_timezone_device_disclaimer'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFF8E857C),
          ),
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    final result = await PrayerLocationService.useCurrentLocation();
    if (!mounted) return;
    setState(() {
      _inlineMessage = switch (result) {
        PrayerLocationActionResult.success => null,
        PrayerLocationActionResult.serviceDisabled =>
          S.get('location_service_disabled'),
        PrayerLocationActionResult.permissionDenied ||
        PrayerLocationActionResult.permissionDeniedForever =>
          S.get('adhan_location_permission_fallback_note'),
        PrayerLocationActionResult.unavailableOnWeb =>
          S.get('location_unavailable_web'),
        PrayerLocationActionResult.failed => S.get('location_read_failed'),
      };
      _isLoading = false;
      _now = DateTime.now();
    });
  }

  Future<void> _chooseCity() async {
    final result = await Navigator.of(context).push<CityPickerResult>(
      MaterialPageRoute(builder: (_) => const CityPickerScreen()),
    );
    if (result == null || !mounted) return;

    setState(() => _isLoading = true);
    await PrayerLocationService.setCityLocation(
      cityName: result.label,
      cityId: result.id,
      lat: result.lat,
      lng: result.lng,
      timezoneId: result.timezone,
    );
    if (!mounted) return;
    setState(() {
      _inlineMessage = null;
      _isLoading = false;
      _now = DateTime.now();
    });
  }

  String? _countryFromLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final label = location.cityName ?? '';
    final parts = label.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  String _selectedLocationLabel(PrayerLocation location) {
    if (!location.hasCoordinates) {
      return S.get('prayer_times_not_set');
    }

    if (location.mode == PrayerLocationMode.current) {
      final city = (location.cityName ?? '').trim();
      if (city.isNotEmpty) {
        return city;
      }
      return '${location.lat!.toStringAsFixed(4)}, '
          '${location.lng!.toStringAsFixed(4)}';
    }

    final city = (location.cityName ?? '').trim();
    if (city.isEmpty) {
      return S.get('prayer_times_not_set');
    }
    return city;
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
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.prayer,
    required this.location,
    required this.now,
    required this.locationLabel,
    required this.remainingText,
    required this.labelForKey,
  });

  final NextPrayerEntry? prayer;
  final PrayerLocation location;
  final DateTime now;
  final String locationLabel;
  final String? remainingText;
  final String Function(String key) labelForKey;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final prayerTime = prayer?.time.toLocal();
    final timeText = prayerTime == null
        ? '--:--'
        : material.formatTimeOfDay(
            TimeOfDay.fromDateTime(prayerTime),
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );
    final prayerLabel = prayer == null
        ? S.get('next_prayer_none_title')
        : labelForKey(prayer!.key);
    final heroPalette = _heroPaletteFor(now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: heroPalette.colors,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: heroPalette.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A8F7E6E),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -54,
              top: -42,
              child: IgnorePointer(
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: heroPalette.orbColors,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -28,
              bottom: -34,
              child: IgnorePointer(
                child: Container(
                  width: 150,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: heroPalette.sweepColors,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 56,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emphasisAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              AppColors.emphasisAccent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.emphasisAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            S.get('prayer_times_next_prayer'),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emphasisAccent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (location.hasCoordinates)
                      Text(
                        locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6E6259),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.emphasisAccent.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayerLabel,
                        style: const TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 31,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF2E2621),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emphasisAccent,
                          height: 1,
                          letterSpacing: -1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.emphasisAccent.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    remainingText ??
                        (location.hasCoordinates
                            ? S.get('next_prayer_none_title')
                            : S.get('next_prayer_set_location_cta')),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF53463E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _HeroPalette _heroPaletteFor(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 11) {
      return const _HeroPalette(
        colors: [Color(0xFFF8F2E7), Color(0xFFF0E8DB)],
        border: Color(0xFFE6DAC8),
        orbColors: [Color(0x66FFF7EC), Color(0x00FFF7EC)],
        sweepColors: [Color(0x30FFFFFF), Color(0x00FFFFFF)],
      );
    }
    if (hour >= 17 && hour < 21) {
      return const _HeroPalette(
        colors: [Color(0xFFF4E8D9), Color(0xFFE8D7C7)],
        border: Color(0xFFE2CFBB),
        orbColors: [Color(0x52FFE8C9), Color(0x00FFE8C9)],
        sweepColors: [Color(0x24FFF7EE), Color(0x00FFF7EE)],
      );
    }
    if (hour >= 21 || hour < 5) {
      return const _HeroPalette(
        colors: [Color(0xFFE7E0D8), Color(0xFFDAD2C8)],
        border: Color(0xFFD3C8BD),
        orbColors: [Color(0x48FFF7EF), Color(0x00FFF7EF)],
        sweepColors: [Color(0x20FFFFFF), Color(0x00FFFFFF)],
      );
    }
    return const _HeroPalette(
      colors: [Color(0xFFF5EFE5), Color(0xFFEBE3D8)],
      border: Color(0xFFE1D6C9),
      orbColors: [Color(0x4DFFF5EA), Color(0x00FFF5EA)],
      sweepColors: [Color(0x24FFFFFF), Color(0x00FFFFFF)],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.rows});

  final List<_PrayerRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            const Color(0xFFF8F2EA).withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEAE1D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x088F7E6E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _PrayerTimeRow(row: rows[i]),
            if (i != rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({required this.row});

  final _PrayerRowData row;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = row.isHighlighted
        ? AppColors.emphasisAccent.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.55);
    final borderColor = row.isHighlighted
        ? AppColors.emphasisAccent.withValues(alpha: 0.22)
        : const Color(0xF0EEE4D9);
    final textColor =
        row.isHighlighted ? const Color(0xFF2D2621) : const Color(0xFF5D5650);
    final timeColor =
        row.isHighlighted ? const Color(0xFF231D19) : const Color(0xFF342E2A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: row.isHighlighted
              ? [
                  AppColors.emphasisAccent.withValues(alpha: 0.16),
                  const Color(0xFFF4ECE3),
                ]
              : [
                  backgroundColor,
                  const Color(0xFFF8F4EE),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: row.isHighlighted
            ? const [
                BoxShadow(
                  color: Color(0x126E878A),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: row.isHighlighted
                  ? AppColors.emphasisAccent
                  : const Color(0xFFD9CCBE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                fontFamily: row.isHighlighted ? 'Merriweather' : 'Inter',
                fontSize: row.isHighlighted ? 17 : 15,
                fontWeight:
                    row.isHighlighted ? FontWeight.w400 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          if (row.isHighlighted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.emphasisAccent.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                S.get('prayer_times_next_prayer'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emphasisAccent,
                  letterSpacing: 0.35,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            AdhanTimesService.formatHHmm(row.time),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: row.isHighlighted ? 19 : 16,
              fontWeight: FontWeight.w600,
              color: timeColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionChip extends StatelessWidget {
  const _CompactActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.72),
              const Color(0xFFF4ECE3),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE6DDD2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6A5F55)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF403934),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRowData {
  const _PrayerRowData({
    required this.key,
    required this.label,
    required this.time,
    required this.isHighlighted,
  });

  final String key;
  final String label;
  final DateTime time;
  final bool isHighlighted;
}

class _HeroPalette {
  const _HeroPalette({
    required this.colors,
    required this.border,
    required this.orbColors,
    required this.sweepColors,
  });

  final List<Color> colors;
  final Color border;
  final List<Color> orbColors;
  final List<Color> sweepColors;
}
