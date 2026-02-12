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

  static Future<void> load() async {
    if (_cache != null) return;
    final data = await rootBundle.load('assets/ramadan/daily_notes_tr.json');
    final decoded = utf8.decode(data.buffer.asUint8List());
    final raw = jsonDecode(decoded) as List<dynamic>;
    _cache = raw
        .map((e) => RamadanDailyNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static RamadanDailyNote? getTodayNote() {
    final notes = _cache;
    if (notes == null || notes.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return notes[dayOfYear % notes.length];
  }
}
