import 'package:adhan/adhan.dart';
import '../models/prayer_location.dart';

class AdhanDayTimes {
  const AdhanDayTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
}

class AdhanTimesService {
  AdhanTimesService._();

  // Fallback when no location is available (keeps app functional offline).
  static const defaultLat = 41.0082;
  static const defaultLng = 28.9784;

  static AdhanDayTimes computeTimes(
    DateTime date,
    PrayerLocation location, {
    String? countryHint,
  }) {
    final lat = location.hasCoordinates ? location.lat! : defaultLat;
    final lng = location.hasCoordinates ? location.lng! : defaultLng;
    final coords = Coordinates(lat, lng);

    final params = _resolveCalculationParams(countryHint: countryHint);
    params.madhab = Madhab.shafi;
    final components = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coords, components, params);

    return AdhanDayTimes(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }

  static String formatHHmm(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static CalculationParameters _resolveCalculationParams({String? countryHint}) {
    final country = (countryHint ?? '').trim().toLowerCase();
    if (country.isEmpty ||
        country.contains('turkey') ||
        country.contains('türkiye') ||
        country.contains('turkiye')) {
      // Diyanet is not exposed directly by adhan.
      // Turkey parameters are the closest built-in method.
      return CalculationMethod.turkey.getParameters();
    }
    return CalculationMethod.muslim_world_league.getParameters();
  }
}
