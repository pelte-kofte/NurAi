import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../models/ayah.dart';

/// Displays a full surah for calm, focused reading.
/// Arabic text is visually dominant; Turkish readable text is subordinate.
/// No ayah numbers, no interactions, no distractions.
class AyahReadingScreen extends StatelessWidget {
  final int surahNumber;
  final String surahName;

  const AyahReadingScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    final ayahs = QuranData.instance.getAyahsForSurah(surahNumber);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: Color(0xFF7A746F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          surahName,
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        itemCount: ayahs.length,
        itemBuilder: (context, index) => _AyahBlock(ayah: ayahs[index]),
      ),
    );
  }
}

/// A single ayah displayed as a calm reading block.
/// Arabic text on top (large, RTL), Turkish readable below (smaller, muted).
class _AyahBlock extends StatelessWidget {
  final Ayah ayah;

  const _AyahBlock({required this.ayah});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic text — visually dominant
          Text(
            ayah.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          // Turkish readable — subordinate, softer
          Text(
            ayah.turkishReadable,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
