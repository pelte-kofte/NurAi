enum PrayerLocationMode { current, city }

class PrayerLocation {
  const PrayerLocation({
    required this.mode,
    this.lat,
    this.lng,
    this.cityName,
    this.cityId,
    this.timezone,
    required this.updatedAt,
  });

  final PrayerLocationMode mode;
  final double? lat;
  final double? lng;
  final String? cityName;
  final String? cityId;
  final String? timezone;
  final DateTime updatedAt;

  bool get hasCoordinates => lat != null && lng != null;

  PrayerLocation copyWith({
    PrayerLocationMode? mode,
    double? lat,
    double? lng,
    String? cityName,
    String? cityId,
    String? timezone,
    DateTime? updatedAt,
  }) {
    return PrayerLocation(
      mode: mode ?? this.mode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      cityName: cityName ?? this.cityName,
      cityId: cityId ?? this.cityId,
      timezone: timezone ?? this.timezone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'lat': lat,
      'lng': lng,
      'cityName': cityName,
      'cityId': cityId,
      'timezone': timezone,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static PrayerLocation fromJson(Map<String, dynamic> json) {
    final modeRaw = json['mode']?.toString();
    final mode = PrayerLocationMode.values.firstWhere(
      (item) => item.name == modeRaw,
      orElse: () => PrayerLocationMode.city,
    );

    return PrayerLocation(
      mode: mode,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      cityName: json['cityName']?.toString(),
      cityId: json['cityId']?.toString(),
      timezone: json['timezone']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static PrayerLocation initial() {
    return PrayerLocation(
      mode: PrayerLocationMode.city,
      updatedAt: DateTime.now(),
    );
  }
}
