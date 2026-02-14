import 'dart:convert';
import 'package:flutter/services.dart';

class RamadanDailyNote {
  final String id;
  final String text;

  const RamadanDailyNote({
    required this.id,
    required this.text,
  });

  factory RamadanDailyNote.fromJson(Map<String, dynamic> json) {
    return RamadanDailyNote(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class RamadanDailyNoteService {
  static List<RamadanDailyNote>? _cache;
  static String? _loadedAssetPath;

  static Future<void> load({required String assetPath}) async {
    if (_cache != null && _loadedAssetPath == assetPath) return;
    final loaded = await _loadList(assetPath);
    if (loaded.isNotEmpty) {
      _cache = loaded;
      _loadedAssetPath = assetPath;
      return;
    }

    // Fallback to English localized notes to avoid crashes on missing assets.
    const fallbackPath = 'assets/ramadan/daily_notes_en.json';
    final fallback = await _loadList(fallbackPath);
    _cache = fallback;
    _loadedAssetPath = fallbackPath;
  }

  static RamadanDailyNote? getTodayNote() {
    final notes = _cache;
    if (notes == null || notes.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return notes[dayOfYear % notes.length];
  }

  static Future<List<RamadanDailyNote>> _loadList(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final decoded = utf8.decode(data.buffer.asUint8List());
      final raw = jsonDecode(decoded) as List<dynamic>;
      return raw
          .map((e) => RamadanDailyNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
