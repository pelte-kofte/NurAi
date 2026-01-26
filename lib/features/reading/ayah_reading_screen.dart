import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../data/reading_progress_service.dart';
import '../../data/bookmark_service.dart';
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

  static const double _ayahBlockHeight = 180.0;

  @override
  void initState() {
    super.initState();
    _ayahs = QuranData.instance.getAyahsForSurah(widget.surahNumber);

    // Determine scroll/highlight target: explicit initialAyah or saved progress
    if (widget.initialAyah != null) {
      _scrollToAyah = widget.initialAyah;
    } else {
      final savedSurah = ReadingProgressService.getLastSurah();
      _scrollToAyah = (savedSurah == widget.surahNumber)
          ? ReadingProgressService.getLastAyah()
          : null;
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
          final isTarget =
              _scrollToAyah != null && ayah.ayahNumber == _scrollToAyah;
          return _AyahBlock(
            ayah: ayah,
            isNavigationTarget: isTarget,
            onTap: () {
              ReadingProgressService.saveProgress(
                widget.surahNumber,
                ayah.ayahNumber,
              );
            },
          );
        },
      ),
    );
  }
}

/// A single ayah with subtle bookmark toggle and navigation target indicator.
class _AyahBlock extends StatefulWidget {
  final Ayah ayah;
  final bool isNavigationTarget;
  final VoidCallback? onTap;

  const _AyahBlock({
    required this.ayah,
    this.isNavigationTarget = false,
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
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: widget.isNavigationTarget
              ? const Color(0xFFF6F1ED)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            // Dot marker for navigation target ayah
            if (widget.isNavigationTarget)
              const Positioned(
                left: 0,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFB57A5A),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 6, height: 6),
                ),
              ),
            // Ayah content
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.ayah.arabic,
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
