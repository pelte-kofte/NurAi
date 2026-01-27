/// Service for occasional daily wisdom/hadith display.
/// Not every day — deterministic based on date.
/// No tracking, no interactions.
class DailyWisdomService {
  /// Collection of wisdom and hadith (attributed when possible).
  static const List<DailyWisdom> _wisdomCollection = [
    DailyWisdom(
      text: 'Kolaylaştırın, zorlaştırmayın. Müjdeleyin, nefret ettirmeyin.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'Sabır, acı bir ağaçtır; fakat meyvesi tatlıdır.',
      source: 'İslam Hikmeti',
    ),
    DailyWisdom(
      text: 'İnsanların en hayırlısı, insanlara en faydalı olandır.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'Güzel söz sadakadır.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'Kim bir müminin dünya sıkıntılarından birini giderirse, '
          'Allah da onun kıyamet sıkıntılarından birini giderir.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'Tefekkür ibadetin yarısıdır.',
      source: 'İslam Hikmeti',
    ),
    DailyWisdom(
      text: 'Öfkelendiğin zaman sus.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'Şüphesiz Allah, işini sağlam yapan kulunu sever.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'İlim Çin\'de bile olsa gidip alınız.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
    DailyWisdom(
      text: 'Utanmadıktan sonra dilediğini yap.',
      source: 'Hz. Muhammed (s.a.v.)',
    ),
  ];

  /// Determines if wisdom should be shown today (not every day).
  /// Uses date-based deterministic logic — roughly 3 days a week.
  static bool shouldShowToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // Show on days where (dayOfYear * 7) % 17 < 7
    // This creates a pseudo-random but consistent pattern
    return ((dayOfYear * 7) % 17) < 7;
  }

  /// Get today's wisdom if it should be shown.
  static DailyWisdom? getTodayWisdom() {
    if (!shouldShowToday()) return null;

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // Deterministic selection based on date
    final index = (dayOfYear * 13) % _wisdomCollection.length;
    return _wisdomCollection[index];
  }
}

/// A piece of daily wisdom or hadith.
class DailyWisdom {
  final String text;
  final String source;

  const DailyWisdom({
    required this.text,
    required this.source,
  });
}
