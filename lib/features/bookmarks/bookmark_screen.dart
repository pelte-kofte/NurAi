import 'package:flutter/material.dart';
import '../../data/bookmark_service.dart';
import '../../data/quran_data.dart';
import '../../models/ayah.dart';
import '../reading/ayah_reading_screen.dart';

/// Displays bookmarked ayahs in a calm, return-to-later format.
/// No delete actions here — removal happens in AyahReadingScreen.
class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = BookmarkService.getAllBookmarks();

    // Sort by surah, then ayah
    bookmarks.sort((a, b) {
      final surahCompare = a.$1.compareTo(b.$1);
      if (surahCompare != 0) return surahCompare;
      return a.$2.compareTo(b.$2);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: Color(0xFF7A746F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kaydedilenler',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        centerTitle: false,
      ),
      body: bookmarks.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              itemCount: bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 36),
              itemBuilder: (context, index) {
                final (surahNumber, ayahNumber) = bookmarks[index];
                final ayah = _findAyah(surahNumber, ayahNumber);
                if (ayah == null) return const SizedBox.shrink();

                final surahName = QuranData.instance.getSurahName(surahNumber);
                return _BookmarkItem(
                  ayah: ayah,
                  surahName: surahName,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AyahReadingScreen(
                          surahNumber: surahNumber,
                          surahName: surahName,
                          initialAyah: ayahNumber,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Ayah? _findAyah(int surah, int ayahNumber) {
    final ayahs = QuranData.instance.getAyahsForSurah(surah);
    for (final a in ayahs) {
      if (a.ayahNumber == ayahNumber) return a;
    }
    return null;
  }
}

/// Empty state when no bookmarks exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Henüz kaydettiğiniz ayet yok.\n\nOkurken bir ayeti kaydetmek için\nyer imi simgesine dokunun.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7A746F),
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

/// A single bookmark item — calm, text-focused, no icons or borders.
class _BookmarkItem extends StatelessWidget {
  final Ayah ayah;
  final String surahName;
  final VoidCallback onTap;

  const _BookmarkItem({
    required this.ayah,
    required this.surahName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surah name and ayah number
          Text(
            '$surahName · ${ayah.ayahNumber}. Ayet',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
            ),
          ),
          const SizedBox(height: 12),
          // Arabic text
          SizedBox(
            width: double.infinity,
            child: Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B2725),
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Turkish readable
          Text(
            ayah.turkishReadable,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
