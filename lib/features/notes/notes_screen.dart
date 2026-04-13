import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../data/ayah_notes_service.dart';
import '../../data/quran_data.dart';
import '../../l10n/app_strings.dart';
import '../../models/note_entry.dart';
import '../reading/ayah_reading_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _NotesListScreen();
  }
}

class _NotesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.get('my_notes'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Transform.scale(
                  scale: 1.08,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                    child: Image.asset(
                      'assets/images/mosque_bg_2.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFBF6F2).withValues(alpha: 0.08),
                      const Color(0xFFFBF6F2).withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: AyahNotesService.revision,
            builder: (context, _, __) {
              final notes = AyahNotesService.getAllNotes();
              if (notes.isEmpty) {
                return Center(
                  child: Text(
                    S.get('notes_empty'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF7A746F),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                itemCount: notes.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x33B5AEA8)),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final surahName = QuranData.instance.getSurahName(note.surah);
                  final preview = note.text.replaceAll('\n', ' ').trim();
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AyahReadingScreen(
                            surahNumber: note.surah,
                            surahName: surahName,
                            initialAyah: note.ayah,
                            openNoteEditorOnStart: true,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _confirmDelete(context, note),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$surahName · ${note.ayah}. ${S.get('ayah_label')}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF7A746F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 14,
                              color: Color(0xFF2B2725),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, NoteEntry note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF6F2),
        content: Text(S.get('note_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.get('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AyahNotesService.deleteEntry(note);
    }
  }
}
