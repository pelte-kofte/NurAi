/// Represents surah metadata with names in multiple languages.
class Surah {
  final int id;
  final String nameArabic;
  final String nameTurkish;
  final String nameEnglish;
  final int ayahCount;

  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameTurkish,
    required this.nameEnglish,
    required this.ayahCount,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] as int,
      nameArabic: json['name_ar'] as String,
      nameTurkish: json['name_tr'] as String,
      nameEnglish: json['name_en'] as String,
      ayahCount: json['ayah_count'] as int,
    );
  }
}
