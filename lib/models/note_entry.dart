import 'dart:convert';

class NoteEntry {
  const NoteEntry({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int surah;
  final int ayah;
  final String text;
  final int createdAt;
  final int updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surah': surah,
      'ayah': ayah,
      'text': text,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String toRawJson() => jsonEncode(toJson());

  static NoteEntry fromJson(Map<String, dynamic> json) {
    return NoteEntry(
      id: json['id']?.toString() ?? '',
      surah: (json['surah'] as num?)?.toInt() ?? 0,
      ayah: (json['ayah'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  static NoteEntry? fromRawJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
