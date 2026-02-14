import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  String? _inlineMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (LocalPreferencesService.adhanEnabled.value) {
      await AdhanNotificationService.rescheduleForToday();
    }
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
          if (_isLoading) {
            return Center(
              child: Text(
                S.get('prayer_times_loading'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF7A746F),
                ),
              ),
            );
          }

          final today = DateTime.now();
          final times = AdhanTimesService.computeTimes(
            today,
            location,
            countryHint: _countryFromLocation(location),
          );
          final rows = <_PrayerRowData>[
            _PrayerRowData(label: S.get('fajr'), time: times.fajr),
            _PrayerRowData(label: S.get('dhuhr'), time: times.dhuhr),
            _PrayerRowData(label: S.get('asr'), time: times.asr),
            _PrayerRowData(label: S.get('maghrib'), time: times.maghrib),
            _PrayerRowData(label: S.get('isha'), time: times.isha),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              _buildLocationCard(location),
              const SizedBox(height: 14),
              ValueListenableBuilder<bool>(
                valueListenable: LocalPreferencesService.adhanEnabled,
                builder: (context, enabled, _) {
                  final nextPrayer = _findNextPrayer(rows);
                  return _buildNotificationCard(
                    enabled: enabled,
                    nextPrayer: nextPrayer,
                  );
                },
              ),
              const SizedBox(height: 14),
              _buildTodayTimesCard(rows),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(PrayerLocation location) {
    final label = _selectedLocationLabel(location);
    return _CardBox(
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
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B2725),
            ),
          ),
          if (_inlineMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _inlineMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.my_location_rounded,
            label: S.get('prayer_times_use_current'),
            onTap: _useCurrentLocation,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.location_city_rounded,
            label: S.get('prayer_times_choose_city'),
            onTap: _chooseCity,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required bool enabled,
    required _PrayerRowData? nextPrayer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7BAEAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.get('adhan_alarms'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF2B2725),
                  ),
                ),
              ),
              CupertinoSwitch(
                value: enabled,
                activeTrackColor: const Color(0xFFB57A5A),
                onChanged: _toggleNotifications,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            enabled
                ? S.get('adhan_preview_subtitle_on')
                : S.get('adhan_preview_subtitle_off'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
            ),
          ),
          if (enabled && nextPrayer != null) ...[
            const SizedBox(height: 4),
            Text(
              S.get('prayer_times_next_line')
                  .replaceAll('{prayer}', nextPrayer.label)
                  .replaceAll('{time}', AdhanTimesService.formatHHmm(nextPrayer.time)),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayTimesCard(List<_PrayerRowData> rows) {
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('prayer_times_today'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ...rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: Color(0xFF2B2725),
                        ),
                      ),
                    ),
                    Text(
                      AdhanTimesService.formatHHmm(row.time),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2B2725),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _isLoading = true);
    if (value) {
      final result =
          await AdhanNotificationService.enableForTodayAndRescheduleDaily();
      if (!mounted) return;
      setState(() {
        _inlineMessage = switch (result) {
          AdhanEnableResult.enabled => null,
          AdhanEnableResult.notificationPermissionDenied =>
            S.get('prayer_notif_permission_body'),
          AdhanEnableResult.locationServiceDisabled =>
            S.get('location_service_disabled'),
          AdhanEnableResult.locationPermissionDenied ||
          AdhanEnableResult.locationPermissionDeniedForever =>
            S.get('prayer_times_permission_denied'),
          AdhanEnableResult.locationMissing =>
            S.get('prayer_times_location_required'),
          AdhanEnableResult.locationFailed => S.get('location_read_failed'),
          AdhanEnableResult.unavailableOnWeb => S.get('location_unavailable_web'),
        };
        _isLoading = false;
      });
      return;
    }

    await AdhanNotificationService.disableAndCancelAll();
    if (!mounted) return;
    setState(() {
      _inlineMessage = null;
      _isLoading = false;
    });
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
        return '${S.get('prayer_times_current_prefix')}: $city';
      }
      return '${S.get('prayer_times_current_prefix')}: '
          '${location.lat!.toStringAsFixed(4)}, ${location.lng!.toStringAsFixed(4)}';
    }

    final city = (location.cityName ?? '').trim();
    if (city.isEmpty) {
      return S.get('prayer_times_not_set');
    }
    return '${S.get('prayer_times_city_prefix')}: $city';
  }

  _PrayerRowData? _findNextPrayer(List<_PrayerRowData> rows) {
    final now = DateTime.now();
    for (final row in rows) {
      if (row.time.isAfter(now)) return row;
    }
    return null;
  }
}

class _PrayerRowData {
  const _PrayerRowData({required this.label, required this.time});

  final String label;
  final DateTime time;
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child});

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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7A746F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF2B2725),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Color(0xFFB5AEA8),
          ),
        ],
      ),
    );
  }
}
