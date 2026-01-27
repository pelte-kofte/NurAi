import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../data/reading_progress_service.dart';
import '../../data/bookmark_service.dart';
import '../../data/collective_reading_service.dart';
import '../../models/ayah.dart';
import '../surah/surah_list_screen.dart';

/// Displays a full surah for calm, focused reading.
class AyahReadingScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialAyah;

  const AyahReadingScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialAyah,
  });

  @override
  State<AyahReadingScreen> createState() => _AyahReadingScreenState();
}

class _AyahReadingScreenState extends State<AyahReadingScreen> {
  final ScrollController _scrollController = ScrollController();
  late final List<Ayah> _ayahs;
  late final int? _scrollToAyah;
  late int _currentLastReadAyah;
  JuzRange? _activeJuzRange;

  static const double _ayahBlockHeight = 180.0;

  @override
  void initState() {
    super.initState();
    _ayahs = QuranData.instance.getAyahsForSurah(widget.surahNumber);
    _activeJuzRange = CollectiveReadingService.getSelectedJuzRange();

    // Determine scroll target: explicit initialAyah or saved progress
    if (widget.initialAyah != null) {
      _scrollToAyah = widget.initialAyah;
      _currentLastReadAyah = widget.initialAyah!;
    } else {
      final savedSurah = ReadingProgressService.getLastSurah();
      if (savedSurah == widget.surahNumber) {
        final savedAyah = ReadingProgressService.getLastAyah();
        _scrollToAyah = savedAyah;
        _currentLastReadAyah = savedAyah;
      } else {
        _scrollToAyah = null;
        _currentLastReadAyah = 1;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
  }

  void _scrollToTarget() {
    if (_scrollToAyah == null || _scrollToAyah! <= 1) return;

    final index = _ayahs.indexWhere((a) => a.ayahNumber == _scrollToAyah);
    if (index > 0) {
      final offset = index * _ayahBlockHeight;
      _scrollController
          .jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    }
  }

  void _onAyahTap(int ayahNumber) {
    setState(() => _currentLastReadAyah = ayahNumber);
    ReadingProgressService.saveProgress(widget.surahNumber, ayahNumber);
    // Silent tracking for collective reading (no UI feedback)
    CollectiveReadingService.recordAyahRead(widget.surahNumber, ayahNumber);
  }

  bool _isAyahWithinJuzRange(Ayah ayah) {
    if (_activeJuzRange == null) return false;
    if (CollectiveReadingService.isCompleted()) return false;
    return _activeJuzRange!.containsAyah(ayah.surah, ayah.ayahNumber);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          widget.surahName,
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.list_rounded,
              size: 22,
              color: Color(0xFF7A746F),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SurahListScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        itemCount: _ayahs.length,
        itemBuilder: (context, index) {
          final ayah = _ayahs[index];
          return _AyahBlock(
            ayah: ayah,
            isLastRead: ayah.ayahNumber == _currentLastReadAyah,
            isWithinJuzRange: _isAyahWithinJuzRange(ayah),
            onTap: () => _onAyahTap(ayah.ayahNumber),
          );
        },
      ),
    );
  }
}

/// A single ayah with subtle bookmark toggle and last-read indicator.
class _AyahBlock extends StatefulWidget {
  final Ayah ayah;
  final bool isLastRead;
  final bool isWithinJuzRange;
  final VoidCallback? onTap;

  const _AyahBlock({
    required this.ayah,
    this.isLastRead = false,
    this.isWithinJuzRange = false,
    this.onTap,
  });

  @override
  State<_AyahBlock> createState() => _AyahBlockState();
}

class _AyahBlockState extends State<_AyahBlock> {
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = BookmarkService.isBookmarked(
      widget.ayah.surah,
      widget.ayah.ayahNumber,
    );
  }

  Future<void> _toggleBookmark() async {
    final newState = await BookmarkService.toggle(
      widget.ayah.surah,
      widget.ayah.ayahNumber,
    );
    setState(() => _isBookmarked = newState);
  }

  @override
  Widget build(BuildContext context) {
    // Subtle color variations for Juz range
    final arabicColor = widget.isWithinJuzRange
        ? const Color(0xFF1F1D1C) // Slightly darker
        : const Color(0xFF2B2725);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.isLastRead
              ? const Color(0xFFF4EFEA)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtle left dot for Juz range indicator (ambient, not instructional)
            if (widget.isWithinJuzRange && !widget.isLastRead)
              const Padding(
                padding: EdgeInsets.only(top: 14, right: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFD4CCC6),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 4, height: 4),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dot marker above Arabic text for last-read ayah
                  if (widget.isLastRead)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFB57A5A),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 6, height: 6),
                        ),
                      ),
                    ),
                  // Arabic text
                  Text(
                    widget.ayah.arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: arabicColor,
                      height: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Turkish text and bookmark
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.ayah.turkishReadable,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7A746F),
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: const Color(0xFF7A746F),
                          ),
                        ),
                      ),
                    ],
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
