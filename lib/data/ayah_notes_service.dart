import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_entry.dart';

class AyahNotesService {
  AyahNotesService._();

  static const _keyIndex = 'notes_index';
  static const _prefix = 'note_';
  static SharedPreferences? _prefs;

  static final revision = ValueNotifier<int>(0);

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _normalizeIndex();
  }

  static String keyFor(int surah, int ayah) => '$_prefix${surah}_$ayah';

  static NoteEntry? getNote(int surah, int ayah) {
    return NoteEntry.fromRawJson(_prefs?.getString(keyFor(surah, ayah)));
  }

  static bool hasNote(int surah, int ayah) {
    final note = getNote(surah, ayah);
    return note != null && note.text.trim().isNotEmpty;
  }

  static Future<void> saveNote({
    required int surah,
    required int ayah,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await deleteNote(surah, ayah);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = getNote(surah, ayah);
    final entry = NoteEntry(
      id: existing?.id ?? '${surah}_${ayah}_$now',
      surah: surah,
      ayah: ayah,
      text: trimmed,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final key = keyFor(surah, ayah);
    await _prefs?.setString(key, entry.toRawJson());
    final index = [...(_prefs?.getStringList(_keyIndex) ?? const <String>[])];
    index.removeWhere((item) => item == key);
    index.add(key);
    await _prefs?.setStringList(_keyIndex, index);
    await _normalizeIndex();
    _bump();
  }

  static Future<void> deleteNote(int surah, int ayah) async {
    final key = keyFor(surah, ayah);
    await _prefs?.remove(key);
    final index = [...(_prefs?.getStringList(_keyIndex) ?? const <String>[])];
    index.removeWhere((item) => item == key);
    await _prefs?.setStringList(_keyIndex, index);
    await _normalizeIndex();
    _bump();
  }

  static Future<void> deleteEntry(NoteEntry entry) async {
    await deleteNote(entry.surah, entry.ayah);
  }

  static List<NoteEntry> getAllNotes() {
    final index = _prefs?.getStringList(_keyIndex) ?? const <String>[];
    final notes = <NoteEntry>[];
    for (final key in index) {
      final note = NoteEntry.fromRawJson(_prefs?.getString(key));
      if (note != null && note.text.trim().isNotEmpty) {
        notes.add(note);
      }
    }
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static void _bump() {
    revision.value = revision.value + 1;
  }

  static Future<void> _normalizeIndex() async {
    final raw = _prefs?.getStringList(_keyIndex) ?? const <String>[];
    final unique = <String>{};
    final normalized = <String>[];

    for (final key in raw) {
      if (!key.startsWith(_prefix)) continue;
      if (!unique.add(key)) continue;
      final note = NoteEntry.fromRawJson(_prefs?.getString(key));
      if (note == null || note.text.trim().isEmpty) continue;
      normalized.add(key);
    }

    if (_listEquals(raw, normalized)) return;
    await _prefs?.setStringList(_keyIndex, normalized);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
