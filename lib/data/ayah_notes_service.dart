import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_entry.dart';
import 'secure_storage_service.dart';

class AyahNotesService {
  AyahNotesService._();

  static const _keyIndex = 'notes_index';
  static const _prefix = 'note_';
  static const _secureNotesMapKey = 'secure_ayah_notes_map_v1';

  static SharedPreferences? _prefs;
  static final revision = ValueNotifier<int>(0);

  static Map<String, String> _noteCache = <String, String>{};

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadFromSecureOrMigrate();
  }

  static String keyFor(int surah, int ayah) => '$_prefix${surah}_$ayah';

  static NoteEntry? getNote(int surah, int ayah) {
    return NoteEntry.fromRawJson(_noteCache[keyFor(surah, ayah)]);
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

    _noteCache[keyFor(surah, ayah)] = entry.toRawJson();
    await _persistCache();
    _bump();
  }

  static Future<void> deleteNote(int surah, int ayah) async {
    _noteCache.remove(keyFor(surah, ayah));
    await _persistCache();
    _bump();
  }

  static Future<void> deleteEntry(NoteEntry entry) async {
    await deleteNote(entry.surah, entry.ayah);
  }

  static List<NoteEntry> getAllNotes() {
    final notes = <NoteEntry>[];
    for (final raw in _noteCache.values) {
      final note = NoteEntry.fromRawJson(raw);
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

  static Future<void> _loadFromSecureOrMigrate() async {
    final secureRaw = await SecureStorageService.read(_secureNotesMapKey);
    final secureMap = _decodeRawMap(secureRaw);

    if (secureMap.isNotEmpty) {
      _noteCache = secureMap;
      await _clearLegacyPrefsNotes();
      return;
    }

    final legacyMap = _readLegacyMapFromPrefs();
    _noteCache = legacyMap;
    if (legacyMap.isNotEmpty) {
      await _persistCache();
    }
    await _clearLegacyPrefsNotes();
  }

  static Map<String, String> _readLegacyMapFromPrefs() {
    final keys = _prefs?.getKeys() ?? const <String>{};
    final mapped = <String, String>{};

    for (final key in keys) {
      if (!key.startsWith(_prefix)) continue;
      final raw = _prefs?.getString(key);
      final note = NoteEntry.fromRawJson(raw);
      if (note == null || note.text.trim().isEmpty) continue;
      mapped[key] = note.toRawJson();
    }

    return mapped;
  }

  static Map<String, String> _decodeRawMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};
      final result = <String, String>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value?.toString();
        if (!key.startsWith(_prefix) || value == null || value.isEmpty) {
          continue;
        }
        final note = NoteEntry.fromRawJson(value);
        if (note == null || note.text.trim().isEmpty) continue;
        result[key] = note.toRawJson();
      }
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> _persistCache() async {
    await SecureStorageService.write(
        _secureNotesMapKey, jsonEncode(_noteCache));
  }

  static Future<void> _clearLegacyPrefsNotes() async {
    final keys = _prefs?.getKeys() ?? const <String>{};
    for (final key in keys) {
      if (!key.startsWith(_prefix)) continue;
      await _prefs?.remove(key);
    }
    await _prefs?.remove(_keyIndex);
  }
}
