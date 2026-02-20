import 'package:flutter/material.dart';

import '../../data/adhan_notification_service.dart';
import '../../data/adhan_times_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/prayer_location_service.dart';
import '../../data/widget_payload_service.dart';
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
  bool _isUpdatingNotifications = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
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
              _buildPrayerNotificationsCard(),
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
          ...rows.map(
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

  Widget _buildPrayerNotificationsCard() {
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('prayer_notifications'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: LocalPreferencesService.adhanEnabled,
            builder: (context, enabled, _) {
              return _switchRow(
                label: S.get('adhan_alarms'),
                value: enabled,
                busy: _isUpdatingNotifications,
                onChanged: _toggleAdhanNotifications,
              );
            },
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<bool>(
            valueListenable: LocalPreferencesService.ezanAlarmSoundEnabled,
            builder: (context, withSound, _) {
              final notificationsEnabled =
                  LocalPreferencesService.adhanEnabled.value;
              return _switchRow(
                label: S.get('ezan_alarm_sound'),
                value: withSound,
                enabled: notificationsEnabled && !_isUpdatingNotifications,
                onChanged: _toggleEzanAlarmSound,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    bool busy = false,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Row(
        children: [
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
          if (busy)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: const Color(0xFF7BAEAC),
          ),
        ],
      ),
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

  Future<void> _toggleAdhanNotifications(bool value) async {
    if (_isUpdatingNotifications) return;
    setState(() => _isUpdatingNotifications = true);
    try {
      if (!value) {
        await AdhanNotificationService.disable();
        return;
      }
      final result = await AdhanNotificationService.enable();
      if (!mounted) return;
      switch (result) {
        case AdhanEnableResult.enabled:
          _inlineMessage = S.get('prayer_notif_scheduled');
          break;
        case AdhanEnableResult.notificationPermissionDenied:
          _inlineMessage = S.get('prayer_notif_permission_body');
          break;
        case AdhanEnableResult.locationServiceDisabled:
          _inlineMessage = S.get('location_service_disabled');
          break;
        case AdhanEnableResult.locationPermissionDenied:
        case AdhanEnableResult.locationPermissionDeniedForever:
          _inlineMessage = S.get('adhan_location_permission_fallback_note');
          break;
        case AdhanEnableResult.locationMissing:
          _inlineMessage = S.get('prayer_location_needed_body');
          break;
        case AdhanEnableResult.locationFailed:
          _inlineMessage = S.get('location_read_failed');
          break;
        case AdhanEnableResult.unavailableOnWeb:
          _inlineMessage = S.get('location_unavailable_web');
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingNotifications = false);
      }
    }
  }

  Future<void> _toggleEzanAlarmSound(bool value) async {
    await LocalPreferencesService.setEzanAlarmSoundEnabled(value);
    if (LocalPreferencesService.adhanEnabled.value) {
      await AdhanNotificationService.rescheduleForToday();
    }
    if (!mounted) return;
    setState(() {});
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
