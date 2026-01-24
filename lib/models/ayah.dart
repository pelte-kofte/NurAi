/// Represents a single Quranic verse with Arabic text and Turkish-readable transliteration.
class Ayah {
  final int surah;
  final int ayahNumber;
  final String arabic;
  final String turkishReadable;

  const Ayah({
    required this.surah,
    required this.ayahNumber,
    required this.arabic,
    required this.turkishReadable,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      surah: json['surah'] as int,
      ayahNumber: json['ayah'] as int,
      arabic: json['ar'] as String,
      turkishReadable: json['tr_readable'] as String,
    );
  }
}
