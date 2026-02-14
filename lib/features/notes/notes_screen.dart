import 'package:flutter/material.dart';
import '../../data/ayah_notes_service.dart';
import '../../data/premium_service.dart';
import '../../data/quran_data.dart';
import '../../l10n/app_strings.dart';
import '../../models/note_entry.dart';
import '../premium/paywall_screen.dart';
import '../reading/ayah_reading_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.isPremium,
      builder: (context, isPremium, _) {
        if (!isPremium) {
          return _LockedNotesScreen();
        }
        return _NotesListScreen();
      },
    );
  }
}

class _LockedNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(S.get('my_notes')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, color: Color(0xFFB5AEA8)),
              const SizedBox(height: 10),
              Text(
                S.get('notes_premium_required'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF7A746F),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                child: Text(S.get('premium_title')),
              ),
            ],
          ),
        ),
      ),
    );
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
      body: ValueListenableBuilder<int>(
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
