import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import '../models/prayer_location.dart';
import 'adhan_notification_service.dart';
import 'local_preferences_service.dart';

enum PrayerLocationActionResult {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailableOnWeb,
  failed,
}

class PrayerLocationService {
  PrayerLocationService._();

  static Future<void> hydrateCurrentLocationIfPermitted() async {
    if (kIsWeb) return;
    final current = LocalPreferencesService.prayerLocation.value;
    if (current.mode != PrayerLocationMode.current) return;
    if (current.hasCoordinates) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!granted) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final tzName = await _safeTimezone();
      await LocalPreferencesService.setPrayerLocation(
        PrayerLocation(
          mode: PrayerLocationMode.current,
          lat: pos.latitude,
          lng: pos.longitude,
          cityId: null,
          timezone: tzName,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Keep existing persisted location as-is.
    }
  }

  static Future<PrayerLocationActionResult> useCurrentLocation() async {
    if (kIsWeb) return PrayerLocationActionResult.unavailableOnWeb;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return PrayerLocationActionResult.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return PrayerLocationActionResult.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return PrayerLocationActionResult.permissionDeniedForever;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final tzName = await _safeTimezone();
      final location = PrayerLocation(
        mode: PrayerLocationMode.current,
        lat: pos.latitude,
        lng: pos.longitude,
        cityName: null,
        cityId: null,
        timezone: tzName,
        updatedAt: DateTime.now(),
      );
      await LocalPreferencesService.setPrayerLocation(location);
      await _rescheduleIfNeeded();
      return PrayerLocationActionResult.success;
    } catch (_) {
      return PrayerLocationActionResult.failed;
    }
  }

  static Future<void> selectCityPlaceholder() async {
    final current = LocalPreferencesService.prayerLocation.value;
    final location = PrayerLocation(
      mode: PrayerLocationMode.city,
      lat: null,
      lng: null,
      cityName: null,
      cityId: current.cityId ?? 'city_stub',
      timezone: current.timezone,
      updatedAt: DateTime.now(),
    );
    await LocalPreferencesService.setPrayerLocation(location);
    await _rescheduleIfNeeded();
  }

  static Future<void> setCityLocation({
    required String cityName,
    required double lat,
    required double lng,
    String? timezoneId,
  }) async {
    final tzName = timezoneId ?? await _safeTimezone();
    final location = PrayerLocation(
      mode: PrayerLocationMode.city,
      lat: lat,
      lng: lng,
      cityName: cityName,
      cityId: cityName,
      timezone: tzName,
      updatedAt: DateTime.now(),
    );
    await LocalPreferencesService.setPrayerLocation(location);
    await _rescheduleIfNeeded();
  }

  static Future<void> _rescheduleIfNeeded() async {
    if (LocalPreferencesService.adhanEnabled.value) {
      await AdhanNotificationService.rescheduleForToday();
    }
  }

  static Future<String?> _safeTimezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return null;
    }
  }
}
