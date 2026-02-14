import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/adhan_notification_service.dart';
import '../../data/adhan_times_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/prayer_location_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/prayer_location.dart';
import 'city_picker_screen.dart';

class AdhanTimesScreen extends StatefulWidget {
  const AdhanTimesScreen({super.key});

  @override
  State<AdhanTimesScreen> createState() => _AdhanTimesScreenState();
}

class _AdhanTimesScreenState extends State<AdhanTimesScreen> {
  bool _isLoading = true;
  PrayerLocationActionResult? _lastLocationResult;
  String? _countryHint;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (LocalPreferencesService.adhanEnabled.value) {
      await AdhanNotificationService.rescheduleForToday();
    }
    final location = LocalPreferencesService.prayerLocation.value;
    _countryHint = _countryFromLocation(location);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('prayer_times_title'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<PrayerLocation>(
        valueListenable: LocalPreferencesService.prayerLocation,
        builder: (context, location, _) {
          if (_isLoading) return _buildLoading();
          _countryHint = _countryFromLocation(location);
          if (!location.hasCoordinates) return _buildEmptyState();
          return _buildTimes(location);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Text(
        S.get('prayer_times_loading'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF7A746F),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final denied = _lastLocationResult == PrayerLocationActionResult.permissionDenied ||
        _lastLocationResult == PrayerLocationActionResult.permissionDeniedForever;
    final deniedMessage = _lastLocationResult == PrayerLocationActionResult.permissionDeniedForever
        ? S.get('location_permission_denied_forever')
        : S.get('prayer_times_permission_denied');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _InfoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                S.get('prayer_times_enable_location_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.get('prayer_times_enable_location_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                  height: 1.4,
                ),
              ),
              if (_lastLocationResult != null) ...[
                const SizedBox(height: 10),
                Text(
                  denied ? deniedMessage : _locationErrorMessage(_lastLocationResult!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB5AEA8),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _enableLocation,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7BAEAC)),
                  ),
                  child: Text(S.get('prayer_times_use_current')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _chooseCity,
                  child: Text(S.get('prayer_times_choose_city')),
                ),
              ),
              if (denied) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: Geolocator.openAppSettings,
                    child: Text(S.get('prayer_times_open_settings')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimes(PrayerLocation location) {
    final today = DateTime.now();
    final times = AdhanTimesService.computeTimes(
      today,
      location,
      countryHint: _countryHint,
    );
    final notificationsOn = LocalPreferencesService.adhanEnabled.value;
    final rows = <_PrayerRowData>[
      _PrayerRowData(label: S.get('fajr'), time: times.fajr),
      _PrayerRowData(label: S.get('dhuhr'), time: times.dhuhr),
      _PrayerRowData(label: S.get('asr'), time: times.asr),
      _PrayerRowData(label: S.get('maghrib'), time: times.maghrib),
      _PrayerRowData(label: S.get('isha'), time: times.isha),
    ];
    final nextPrayer = _findNextPrayer(rows);
    final showTimezoneDisclaimer =
        (location.timezone ?? '').trim().isEmpty && location.mode == PrayerLocationMode.city;
    final locationTitle = location.mode == PrayerLocationMode.current
        ? S.get('prayer_times_subtitle_current')
        : '${S.get('prayer_times_subtitle_city_prefix')}: ${location.cityName ?? S.get('prayer_times_no_location')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('prayer_times_selected_location'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A746F),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                locationTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${location.lat?.toStringAsFixed(4)}, ${location.lng?.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                ),
              ),
              if (showTimezoneDisclaimer) ...[
                const SizedBox(height: 4),
                Text(
                  S.get('prayer_timezone_device_disclaimer'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB5AEA8),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                notificationsOn
                    ? S.get('prayer_times_notifications_on')
                    : S.get('prayer_times_notifications_off'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: notificationsOn
                      ? const Color(0xFF7BAEAC)
                      : const Color(0xFF7A746F),
                ),
              ),
              const SizedBox(height: 8),
              if (nextPrayer != null) ...[
                Text(
                  '${S.get('prayer_times_next_prayer')}: ${nextPrayer.label} • ${_countdownText(nextPrayer.time)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7A746F),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                S.get('prayer_times_today'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A746F),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...rows.map(
          (row) => _buildPrayerRow(
            row,
            isNext: nextPrayer?.label == row.label,
            notificationsOn: notificationsOn,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerRow(
    _PrayerRowData row, {
    required bool isNext,
    required bool notificationsOn,
  }) {
    final isFuture = row.time.isAfter(DateTime.now());
    final isScheduled = notificationsOn && isFuture;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNext ? const Color(0xFF7BAEAC) : const Color(0xFFEDE6E1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isNext ? const Color(0xFF7BAEAC) : const Color(0xFFEDE6E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isFuture ? const Color(0xFF2B2725) : const Color(0xFFB5AEA8),
              ),
            ),
          ),
          if (isScheduled) ...[
            const Icon(
              Icons.notifications_active_outlined,
              size: 14,
              color: Color(0xFF7BAEAC),
            ),
            const SizedBox(width: 6),
            Text(
              S.get('prayer_times_scheduled'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7BAEAC),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isFuture) ...[
            Text(
              S.get('prayer_times_passed'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB5AEA8),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            AdhanTimesService.formatHHmm(row.time),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isFuture ? const Color(0xFF2B2725) : const Color(0xFFB5AEA8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLocation() async {
    setState(() => _isLoading = true);
    final result = await PrayerLocationService.useCurrentLocation();
    if (!mounted) return;
    setState(() {
      _lastLocationResult = result;
      _countryHint = null;
      _isLoading = false;
    });
    if (result == PrayerLocationActionResult.permissionDenied ||
        result == PrayerLocationActionResult.permissionDeniedForever ||
        result == PrayerLocationActionResult.serviceDisabled) {
      _showLocationPermissionSheet();
    }
  }

  Future<void> _chooseCity() async {
    final result = await Navigator.of(context).push<CityPickerResult>(
      MaterialPageRoute(builder: (_) => const CityPickerScreen()),
    );
    if (result == null || !mounted) return;

    setState(() => _isLoading = true);
    await PrayerLocationService.setCityLocation(
      cityName: result.label,
      lat: result.lat,
      lng: result.lng,
      timezoneId: result.timezone,
    );
    if (!mounted) return;
    setState(() {
      _countryHint = result.country;
      _lastLocationResult = PrayerLocationActionResult.success;
      _isLoading = false;
    });
  }

  String _locationErrorMessage(PrayerLocationActionResult result) {
    switch (result) {
      case PrayerLocationActionResult.serviceDisabled:
        return S.get('location_service_disabled');
      case PrayerLocationActionResult.permissionDenied:
      case PrayerLocationActionResult.permissionDeniedForever:
        return S.get('prayer_times_permission_denied');
      case PrayerLocationActionResult.unavailableOnWeb:
        return S.get('location_unavailable_web');
      case PrayerLocationActionResult.failed:
        return S.get('location_read_failed');
      case PrayerLocationActionResult.success:
        return S.get('ok');
    }
  }

  String? _countryFromLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final label = location.cityName ?? '';
    final parts = label.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  _PrayerRowData? _findNextPrayer(List<_PrayerRowData> rows) {
    final now = DateTime.now();
    for (final row in rows) {
      if (row.time.isAfter(now)) return row;
    }
    return null;
  }

  String _countdownText(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return '00:00';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _showLocationPermissionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFBF6F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('prayer_location_needed_title'),
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.get('prayer_location_needed_body'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(S.get('prayer_notif_open_settings')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _chooseCity();
                  },
                  child: Text(S.get('prayer_choose_city_instead')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerRowData {
  const _PrayerRowData({
    required this.label,
    required this.time,
  });

  final String label;
  final DateTime time;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1)),
      ),
      child: child,
    );
  }
}
