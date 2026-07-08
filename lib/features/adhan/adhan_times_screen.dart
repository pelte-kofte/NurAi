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

const _prayerHeroBackgroundAsset = 'assets/images/prayer/prayer_hero_bg.png';

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
    if (!mounted) return;
    setState(() => _isLoading = false);
    unawaited(_runBootstrapSync());
  }

  Future<void> _runBootstrapSync() async {
    try {
      if (LocalPreferencesService.adhanEnabled.value) {
        await AdhanNotificationService.rescheduleForToday();
      }
      await WidgetPayloadService.writeNextPrayerPayload();
    } catch (error, stackTrace) {
      debugPrint('[AdhanTimesScreen] bootstrap_sync_failed: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'adhan_times_screen',
          context: ErrorDescription('while running Prayer Times bootstrap sync'),
        ),
      );
    }
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
    final statusLabel = isCurrentLocationActive
        ? S.get('prayer_times_location_active')
        : S.get('prayer_times_use_current');
    final detailLabel = _inlineMessage ??
        (hasCoordinates
            ? _selectedLocationLabel(location)
            : S.get('prayer_times_location_required'));

    return InkWell(
      onTap: isCurrentLocationActive ? null : _useCurrentLocation,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0E7DB)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3EC),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                isCurrentLocationActive
                    ? Icons.my_location_rounded
                    : Icons.place_outlined,
                size: 18,
                color: const Color(0xFF756455),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A8077),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detailLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2725),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: _chooseCity,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6A5F55),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
              ),
              label: Text(
                S.get('prayer_times_choose_city'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
            color: Color(0xFF9C9389),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F8F7E6E),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _prayerHeroBackgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      Color(0x2E000000),
                      Color(0x14000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (location.hasCoordinates)
                    Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x30000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    prayerLabel,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.12,
                      shadows: [
                        Shadow(
                          color: Color(0x34000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -1.4,
                      shadows: [
                        Shadow(
                          color: Color(0x36000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      remainingText ??
                          (location.hasCoordinates
                              ? S.get('next_prayer_none_title')
                              : S.get('next_prayer_set_location_cta')),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.rows});

  final List<_PrayerRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF0E7DB)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _PrayerTimeRow(row: rows[i]),
            if (i != rows.length - 1)
              Divider(
                height: 18,
                thickness: 1,
                color: const Color(0xFFF1E7DC).withValues(alpha: 0.7),
              ),
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
        ? const Color(0xFFF7EFE3)
        : Colors.transparent;
    final textColor =
        row.isHighlighted ? const Color(0xFF2D2621) : const Color(0xFF5D5650);
    final timeColor =
        row.isHighlighted ? const Color(0xFF231D19) : const Color(0xFF342E2A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
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
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
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
