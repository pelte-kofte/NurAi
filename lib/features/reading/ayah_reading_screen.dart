import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/quran_data.dart';
import '../../data/reading_progress_service.dart';
import '../../data/bookmark_service.dart';
import '../../data/collective_reading_service.dart';
import '../../data/local_preferences_service.dart';
import '../../models/ayah.dart';
import '../../models/reading_context.dart';
import '../surah/surah_list_screen.dart';

/// Displays a full surah for calm, focused reading.
class AyahReadingScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialAyah;
  final ReadingContext readingContext;

  const AyahReadingScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialAyah,
    this.readingContext = const ReadingContext.explore(),
  });

  @override
  State<AyahReadingScreen> createState() => _AyahReadingScreenState();
}

class _AyahReadingScreenState extends State<AyahReadingScreen> {
  final ScrollController _scrollController = ScrollController();
  late final List<Ayah> _ayahs;
  late final bool _isJuzMode;
  late int _currentLastReadSurah;
  late int _currentLastReadAyah;
  int? _scrollToSurah;
  int? _scrollToAyah;
  JuzRange? _activeJuzRange;

  static const double _ayahBlockHeight = 180.0;

  @override
  void initState() {
    super.initState();
    _isJuzMode = widget.readingContext.type == ReadingContextType.juz;

    if (_isJuzMode) {
      _initJuzMode();
    } else {
      _initSurahMode();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
  }

  void _initJuzMode() {
    final juzNumber = widget.readingContext.juzNumber!;
    final range = CollectiveReadingService.getJuzRange(juzNumber);
    _activeJuzRange = range;

    if (range != null) {
      _ayahs = QuranData.instance.getAyahsInRange(
        range.startSurah,
        range.startAyah,
        range.endSurah,
        range.endAyah,
      );
    } else {
      _ayahs = [];
    }

    final ctxProgress =
        ReadingProgressService.getContextProgress(widget.readingContext);
    if (ctxProgress != null) {
      _scrollToSurah = ctxProgress.surah;
      _scrollToAyah = ctxProgress.ayah;
      _currentLastReadSurah = ctxProgress.surah;
      _currentLastReadAyah = ctxProgress.ayah;
    } else if (_ayahs.isNotEmpty) {
      _currentLastReadSurah = _ayahs.first.surah;
      _currentLastReadAyah = _ayahs.first.ayahNumber;
    } else {
      _currentLastReadSurah = 0;
      _currentLastReadAyah = 0;
    }
  }

  void _initSurahMode() {
    _ayahs = QuranData.instance.getAyahsForSurah(widget.surahNumber);
    _activeJuzRange = CollectiveReadingService.getSelectedJuzRange();

    if (widget.initialAyah != null) {
      _scrollToSurah = widget.surahNumber;
      _scrollToAyah = widget.initialAyah;
      _currentLastReadSurah = widget.surahNumber;
      _currentLastReadAyah = widget.initialAyah!;
    } else {
      final ctxProgress =
          ReadingProgressService.getContextProgress(widget.readingContext);
      if (ctxProgress != null && ctxProgress.surah == widget.surahNumber) {
        _scrollToSurah = ctxProgress.surah;
        _scrollToAyah = ctxProgress.ayah;
        _currentLastReadSurah = widget.surahNumber;
        _currentLastReadAyah = ctxProgress.ayah;
      } else {
        _currentLastReadSurah = widget.surahNumber;
        _currentLastReadAyah = 1;
      }
    }
  }

  void _scrollToTarget() {
    if (_scrollToAyah == null) return;

    final index = _ayahs.indexWhere((a) =>
        a.surah == (_scrollToSurah ?? widget.surahNumber) &&
        a.ayahNumber == _scrollToAyah);
    if (index > 0) {
      final offset = index * _ayahBlockHeight;
      _scrollController
          .jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    }
  }

  void _onAyahTap(Ayah ayah) {
    setState(() {
      _currentLastReadSurah = ayah.surah;
      _currentLastReadAyah = ayah.ayahNumber;
    });
    if (LocalPreferencesService.hapticsEnabled.value) {
      HapticFeedback.selectionClick();
    }
    ReadingProgressService.saveGlobalLastRead(ayah.surah, ayah.ayahNumber);
    ReadingProgressService.saveContextProgress(
      widget.readingContext,
      ayah.surah,
      ayah.ayahNumber,
    );
    CollectiveReadingService.recordAyahRead(ayah.surah, ayah.ayahNumber);
  }

  bool _isAyahWithinJuzRange(Ayah ayah) {
    if (_isJuzMode) return false; // All ayahs are within range in juz mode
    if (_activeJuzRange == null) return false;
    if (CollectiveReadingService.isCompleted()) return false;
    return _activeJuzRange!.containsAyah(ayah.surah, ayah.ayahNumber);
  }

  bool _isLastRead(Ayah ayah) {
    return ayah.surah == _currentLastReadSurah &&
        ayah.ayahNumber == _currentLastReadAyah;
  }

  String get _title {
    if (_isJuzMode) {
      return '${widget.readingContext.juzNumber}. Cüz';
    }
    return widget.surahName;
  }

  bool get _canGoPreviousSurah => !_isJuzMode && widget.surahNumber > 1;

  bool get _canGoNextSurah =>
      !_isJuzMode && widget.surahNumber < QuranData.instance.getSurahCount();

  void _openAdjacentSurah(int surahNumber) {
    final initialAyah = ReadingProgressService.getLastAyahForContext(
          widget.readingContext,
          surahNumber,
        ) ??
        1;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surahNumber,
          surahName: QuranData.instance.getSurahName(surahNumber),
          initialAyah: initialAyah,
          readingContext: widget.readingContext,
        ),
      ),
    );
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
          _title,
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        actions: [
          if (!_isJuzMode) ...[
            IconButton(
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: Color(0xFF7A746F),
              ),
              onPressed: _canGoPreviousSurah
                  ? () => _openAdjacentSurah(widget.surahNumber - 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFF7A746F),
              ),
              onPressed: _canGoNextSurah
                  ? () => _openAdjacentSurah(widget.surahNumber + 1)
                  : null,
            ),
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
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        itemCount: _ayahs.length + (_isJuzMode ? 1 : 0),
        itemBuilder: (context, index) {
          // Subtle header for juz mode
          if (_isJuzMode && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '${widget.readingContext.juzNumber}. Cüz · Sessizce eşlik ediyorsunuz',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB5AEA8),
                  height: 1.4,
                ),
              ),
            );
          }

          final ayahIndex = _isJuzMode ? index - 1 : index;
          final ayah = _ayahs[ayahIndex];
          return _AyahBlock(
            ayah: ayah,
            isLastRead: _isLastRead(ayah),
            isWithinJuzRange: _isAyahWithinJuzRange(ayah),
            onTap: () => _onAyahTap(ayah),
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
    if (LocalPreferencesService.hapticsEnabled.value) {
      HapticFeedback.selectionClick();
    }
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

