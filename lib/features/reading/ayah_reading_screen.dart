import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import '../../data/adhan_notification_service.dart';
import '../../data/quran_data.dart';
import '../../data/reading_progress_service.dart';
import '../../data/bookmark_service.dart';
import '../../data/ayah_notes_service.dart';
import '../../data/collective_reading_service.dart';
import '../../data/quran_translation_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/ayah.dart';
import '../../models/reading_context.dart';
import '../surah/surah_list_screen.dart';

/// Displays a full surah for calm, focused reading.
enum _SecondaryTextMode { transliteration, translation }

class AyahReadingScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialAyah;
  final bool openNoteEditorOnStart;
  final ReadingContext readingContext;

  const AyahReadingScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialAyah,
    this.openNoteEditorOnStart = false,
    this.readingContext = const ReadingContext.explore(),
  });

  @override
  State<AyahReadingScreen> createState() => _AyahReadingScreenState();
}

class _AyahReadingScreenState extends State<AyahReadingScreen> {
  static const _validatedReadingDelay = Duration(seconds: 12);
  static const _meaningfulAyahInteractionCount = 3;
  final ItemScrollController _itemScrollController = ItemScrollController();
  late final List<Ayah> _ayahs;
  late final bool _isJuzMode;
  late final DateTime _sessionStartedAt;
  late int _currentLastReadSurah;
  late int _currentLastReadAyah;
  int? _scrollToSurah;
  int? _scrollToAyah;
  JuzRange? _activeJuzRange;
  bool _didOpenInitialNoteEditor = false;
  bool _usedSavedContextProgress = false;
  int? _resumeHighlightSurah;
  int? _resumeHighlightAyah;
  bool _showResumeHighlight = false;
  Timer? _resumeHighlightTimer;
  Timer? _validatedReadingTimer;
  _SecondaryTextMode? _secondaryTextMode;
  Ayah? _pendingValidatedAyah;
  bool _hasRecordedValidatedSession = false;
  final Set<String> _engagedAyahKeys = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_secondaryTextMode != null) return;
    final languageCode =
        Localizations.localeOf(context).languageCode.toLowerCase();
    _secondaryTextMode = languageCode == 'tr'
        ? _SecondaryTextMode.transliteration
        : _SecondaryTextMode.translation;
  }

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _isJuzMode = widget.readingContext.type == ReadingContextType.juz;

    if (_isJuzMode) {
      _initJuzMode();
    } else {
      _initSurahMode();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTarget();
      _maybeOpenInitialNoteEditor();
    });
  }

  @override
  void dispose() {
    _resumeHighlightTimer?.cancel();
    _validatedReadingTimer?.cancel();
    super.dispose();
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
      _usedSavedContextProgress = true;
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
        _usedSavedContextProgress = true;
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
    if (index < 0) {
      if (_usedSavedContextProgress) {
        ReadingProgressService.clearContextProgress(widget.readingContext);
      }
      _scrollToSurah = null;
      _scrollToAyah = null;
      return;
    }

    final listIndex = _isJuzMode ? index + 1 : index;
    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: listIndex);
      _showResumeJumpHighlight(_ayahs[index]);
    }
  }

  void _showResumeJumpHighlight(Ayah ayah) {
    _resumeHighlightTimer?.cancel();
    setState(() {
      _resumeHighlightSurah = ayah.surah;
      _resumeHighlightAyah = ayah.ayahNumber;
      _showResumeHighlight = true;
    });

    _resumeHighlightTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showResumeHighlight = false);
    });
  }

  bool _isResumeHighlight(Ayah ayah) {
    return _showResumeHighlight &&
        ayah.surah == _resumeHighlightSurah &&
        ayah.ayahNumber == _resumeHighlightAyah;
  }

  void _onAyahTap(Ayah ayah) {
    setState(() {
      _currentLastReadSurah = ayah.surah;
      _currentLastReadAyah = ayah.ayahNumber;
    });
    HapticFeedback.selectionClick();
    ReadingProgressService.saveGlobalLastRead(ayah.surah, ayah.ayahNumber);
    ReadingProgressService.saveContextProgress(
      widget.readingContext,
      ayah.surah,
      ayah.ayahNumber,
    );
    CollectiveReadingService.recordAyahRead(ayah.surah, ayah.ayahNumber);
    AdhanNotificationService.syncReadingReminder();
    _engagedAyahKeys.add('${ayah.surah}:${ayah.ayahNumber}');
    _queueValidatedReadingSession(ayah);
  }

  void _queueValidatedReadingSession(Ayah ayah) {
    _pendingValidatedAyah = ayah;
    if (_hasRecordedValidatedSession) return;

    if (_engagedAyahKeys.length >= _meaningfulAyahInteractionCount) {
      unawaited(_completeValidatedReadingSession());
      return;
    }

    final elapsed = DateTime.now().difference(_sessionStartedAt);
    if (elapsed >= _validatedReadingDelay) {
      unawaited(_completeValidatedReadingSession());
      return;
    }

    _validatedReadingTimer?.cancel();
    _validatedReadingTimer = Timer(_validatedReadingDelay - elapsed, () {
      if (!mounted ||
          _hasRecordedValidatedSession ||
          _pendingValidatedAyah == null) {
        return;
      }
      unawaited(_completeValidatedReadingSession());
    });
  }

  Future<void> _completeValidatedReadingSession() async {
    if (_hasRecordedValidatedSession) return;
    final ayah = _pendingValidatedAyah;
    if (ayah == null) return;

    _hasRecordedValidatedSession = true;
    final result = await SpiritualProgressService.recordRead(
      ayah.surah,
      ayah.ayahNumber,
    );
    if (!mounted) return;
    _showValidatedReadingFeedback(result);
  }

  void _showValidatedReadingFeedback(SpiritualReadResult result) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    var message = S.get('spiritual_reading_complete_message');
    if (result.streakContinued) {
      message =
          '$message · ${S.get('spiritual_streak_continues_suffix').replaceAll('{count}', '${result.state.streakCount}')}';
    } else if (result.dailyGoalCompletedNow) {
      message = '$message · ${S.get('spiritual_daily_status_done')}';
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
      return '${widget.readingContext.juzNumber}. ${S.get('reading_juz_label')}';
    }
    return widget.surahName;
  }

  bool get _canGoPreviousSurah => !_isJuzMode && widget.surahNumber > 1;

  bool get _canGoNextSurah =>
      !_isJuzMode && widget.surahNumber < QuranData.instance.getSurahCount();

  String _localizedSurahName(int surahNumber) {
    return QuranData.instance.getSurahName(
      surahNumber,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

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
          surahName: _localizedSurahName(surahNumber),
          initialAyah: initialAyah,
          openNoteEditorOnStart: false,
          readingContext: widget.readingContext,
        ),
      ),
    );
  }

  Future<void> _maybeOpenInitialNoteEditor() async {
    if (!widget.openNoteEditorOnStart || _didOpenInitialNoteEditor) return;
    final targetSurah = _scrollToSurah ?? widget.surahNumber;
    final targetAyah = _scrollToAyah;
    if (targetAyah == null) return;
    final target = _ayahs
        .where((a) => a.surah == targetSurah && a.ayahNumber == targetAyah);
    if (target.isEmpty) return;
    _didOpenInitialNoteEditor = true;
    await _openNoteEditorForAyah(target.first);
  }

  Future<void> _openNoteEditorForAyah(Ayah ayah) async {
    await showAyahNoteEditorSheet(
      context: context,
      surahName: _localizedSurahName(ayah.surah),
      ayah: ayah,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final mutedTextColor = theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withValues(alpha: 0.56);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: secondaryTextColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _title,
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (!_isJuzMode) ...[
            IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: secondaryTextColor,
              ),
              onPressed: _canGoPreviousSurah
                  ? () => _openAdjacentSurah(widget.surahNumber - 1)
                  : null,
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: secondaryTextColor,
              ),
              onPressed: _canGoNextSurah
                  ? () => _openAdjacentSurah(widget.surahNumber + 1)
                  : null,
            ),
            IconButton(
              icon: Icon(
                Icons.list_rounded,
                size: 22,
                color: secondaryTextColor,
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
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.28,
                child: Transform.scale(
                  scale: 1.05,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 1.1, sigmaY: 1.1),
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
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.03),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.09),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildSecondaryModeSelector(),
              Expanded(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  itemCount: _ayahs.length + (_isJuzMode ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Subtle header for juz mode
                    if (_isJuzMode && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          S
                              .get(
                                'reading_juz_companion_subtitle',
                              )
                              .replaceFirst('{juz}',
                                  '${widget.readingContext.juzNumber}'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: mutedTextColor,
                            height: 1.4,
                          ),
                        ),
                      );
                    }

                    final ayahIndex = _isJuzMode ? index - 1 : index;
                    final ayah = _ayahs[ayahIndex];
                    final languageCode = Localizations.localeOf(context)
                        .languageCode
                        .toLowerCase();
                    final secondaryMode = _secondaryTextMode ??
                        _SecondaryTextMode.transliteration;
                    return _AyahBlock(
                      ayah: ayah,
                      surahName: _localizedSurahName(ayah.surah),
                      secondaryTextMode: secondaryMode,
                      languageCode: languageCode,
                      isLastRead: _isLastRead(ayah),
                      isResumeHighlight: _isResumeHighlight(ayah),
                      isWithinJuzRange: _isAyahWithinJuzRange(ayah),
                      onTap: () => _onAyahTap(ayah),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryModeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final languageCode =
        Localizations.localeOf(context).languageCode.toLowerCase();
    final selectedMode =
        _secondaryTextMode ?? _SecondaryTextMode.transliteration;
    final options = languageCode == 'tr'
        ? const <_SecondaryTextMode>[
            _SecondaryTextMode.transliteration,
            _SecondaryTextMode.translation,
          ]
        : const <_SecondaryTextMode>[
            _SecondaryTextMode.translation,
            _SecondaryTextMode.transliteration,
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(
                  option == _SecondaryTextMode.transliteration
                      ? S.get('quran_mode_transliteration')
                      : S.get('quran_mode_translation'),
                ),
                selected: selectedMode == option,
                onSelected: (_) {
                  if (_secondaryTextMode == option) return;
                  setState(() => _secondaryTextMode = option);
                },
                labelStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: selectedMode == option
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selectedMode == option
                      ? colorScheme.onSurface
                      : secondaryTextColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selectedMode == option
                        ? colorScheme.primary.withValues(alpha: 0.45)
                        : theme.dividerColor.withValues(alpha: 0.72),
                  ),
                ),
                selectedColor: colorScheme.primary.withValues(alpha: 0.12),
                backgroundColor: colorScheme.surface,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

/// A single ayah with subtle bookmark toggle and last-read indicator.
class _AyahBlock extends StatefulWidget {
  final Ayah ayah;
  final String surahName;
  final _SecondaryTextMode secondaryTextMode;
  final String languageCode;
  final bool isLastRead;
  final bool isResumeHighlight;
  final bool isWithinJuzRange;
  final VoidCallback? onTap;

  const _AyahBlock({
    required this.ayah,
    required this.surahName,
    required this.secondaryTextMode,
    required this.languageCode,
    this.isLastRead = false,
    this.isResumeHighlight = false,
    this.isWithinJuzRange = false,
    this.onTap,
  });

  @override
  State<_AyahBlock> createState() => _AyahBlockState();
}

class _AyahBlockState extends State<_AyahBlock> {
  late bool _isBookmarked;
  late bool _hasNote;
  bool _isSecondaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _isBookmarked = BookmarkService.isBookmarked(
      widget.ayah.surah,
      widget.ayah.ayahNumber,
    );
    _hasNote =
        AyahNotesService.hasNote(widget.ayah.surah, widget.ayah.ayahNumber);
  }

  @override
  void didUpdateWidget(covariant _AyahBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secondaryTextMode != widget.secondaryTextMode ||
        oldWidget.ayah.surah != widget.ayah.surah ||
        oldWidget.ayah.ayahNumber != widget.ayah.ayahNumber) {
      _isSecondaryExpanded = false;
    }
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.selectionClick();
    final newState = await BookmarkService.toggle(
      widget.ayah.surah,
      widget.ayah.ayahNumber,
    );
    setState(() => _isBookmarked = newState);
  }

  Future<void> _openNote() async {
    await showAyahNoteEditorSheet(
      context: context,
      surahName: widget.surahName,
      ayah: widget.ayah,
    );
    if (mounted) {
      setState(() {
        _hasNote =
            AyahNotesService.hasNote(widget.ayah.surah, widget.ayah.ayahNumber);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final readAccent = colorScheme.primary;
    final isHighlighted = widget.isResumeHighlight || widget.isLastRead;
    final arabicColor = widget.isWithinJuzRange
        ? colorScheme.onSurface.withValues(alpha: 0.92)
        : colorScheme.onSurface;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.isResumeHighlight
              ? readAccent.withValues(alpha: 0.22)
              : (widget.isLastRead
                  ? readAccent.withValues(alpha: 0.15)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: isHighlighted
              ? Border.all(
                  color: readAccent.withValues(
                    alpha: widget.isResumeHighlight ? 0.52 : 0.34,
                  ),
                  width: widget.isResumeHighlight ? 1.2 : 1,
                )
              : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: readAccent.withValues(
                      alpha: widget.isResumeHighlight ? 0.12 : 0.08,
                    ),
                    blurRadius: widget.isResumeHighlight ? 18 : 14,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlighted)
              Container(
                width: 3,
                margin: const EdgeInsets.only(right: 10, top: 4),
                decoration: BoxDecoration(
                  color: readAccent.withValues(
                    alpha: widget.isResumeHighlight ? 0.95 : 0.78,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              )
            else
            // Subtle left dot for Juz range indicator (ambient, not instructional)
            if (widget.isWithinJuzRange)
              Padding(
                padding: const EdgeInsets.only(top: 14, right: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 4, height: 4),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dot marker above Arabic text for last-read ayah
                  if (widget.isLastRead)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: readAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: readAccent.withValues(alpha: 0.22),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const SizedBox(width: 6, height: 6),
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
                        child: _buildSecondaryArea(),
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
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _openNote,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            _hasNote
                                ? Icons.sticky_note_2_rounded
                                : Icons.sticky_note_2_outlined,
                            size: 20,
                            color: _hasNote
                                ? colorScheme.primary
                                : secondaryTextColor,
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

  Widget _buildSecondaryArea() {
    if (widget.secondaryTextMode == _SecondaryTextMode.transliteration) {
      return _buildSecondaryText(widget.ayah.turkishReadable);
    }

    return FutureBuilder<String?>(
      future: QuranTranslationService.getTranslation(
        widget.ayah.surah,
        widget.ayah.ayahNumber,
        Locale(widget.languageCode),
      ),
      builder: (context, snapshot) {
        final translation = snapshot.data?.trim();
        final text = (translation != null && translation.isNotEmpty)
            ? translation
            : S.get('meal_not_available');
        return _buildSecondaryText(text);
      },
    );
  }

  Widget _buildSecondaryText(String text) {
    final isLong = text.length > 180;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          textAlign: TextAlign.start,
          maxLines: _isSecondaryExpanded ? null : 4,
          overflow: _isSecondaryExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.6,
          ),
        ),
        if (isLong)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _isSecondaryExpanded = !_isSecondaryExpanded),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _isSecondaryExpanded ? S.get('show_less') : S.get('show_more'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showAyahNoteEditorSheet({
  required BuildContext context,
  required String surahName,
  required Ayah ayah,
}) async {
  final existing = AyahNotesService.getNote(ayah.surah, ayah.ayahNumber);
  final controller = TextEditingController(text: existing?.text ?? '');
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
      colorScheme.onSurface.withValues(alpha: 0.72);
  final mutedTextColor = theme.textTheme.bodySmall?.color ??
      colorScheme.onSurface.withValues(alpha: 0.56);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.get('note_title'),
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$surahName · ${ayah.ayahNumber}. ${S.get('ayah_label')}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 8,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: S.get('note_hint'),
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: mutedTextColor,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await AyahNotesService.saveNote(
                    surah: ayah.surah,
                    ayah: ayah.ayahNumber,
                    text: controller.text,
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text(
                  S.get('save'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  controller.dispose();
}
