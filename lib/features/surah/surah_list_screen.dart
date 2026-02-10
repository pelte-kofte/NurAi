import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../models/reading_context.dart';
import '../../models/surah.dart';
import '../bookmarks/bookmark_screen.dart';
import '../reading/ayah_reading_screen.dart';

/// Displays the list of 114 surahs in a calm, readable format.
/// No icons, no gamification — just a quiet list for browsing.
class SurahListScreen extends StatelessWidget {
  final ReadingContext readingContext;

  const SurahListScreen({
    super.key,
    this.readingContext = const ReadingContext.explore(),
  });

  @override
  Widget build(BuildContext context) {
    final surahs = QuranData.instance.surahs;

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
          'Sureler',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border_rounded,
              size: 22,
              color: Color(0xFF7A746F),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarkScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: surahs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _SurahListItem(
          surah: surahs[index],
          readingContext: readingContext,
        ),
      ),
    );
  }
}

/// A single surah item in the list.
/// Shows surah number, Turkish name, and ayah count.
class _SurahListItem extends StatelessWidget {
  final Surah surah;
  final ReadingContext readingContext;

  const _SurahListItem({
    required this.surah,
    required this.readingContext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AyahReadingScreen(
              surahNumber: surah.id,
              surahName: surah.nameTurkish,
              readingContext: readingContext,
            ),
          ),
          (route) => route.isFirst,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFEDE6E1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Surah number in a subtle circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF6F2),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                '${surah.id}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A746F),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Surah name and ayah count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameTurkish,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.ayahCount} ayet',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A746F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
