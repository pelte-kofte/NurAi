import 'package:flutter/material.dart';

import '../../data/collective_reading_service.dart';
import '../../data/quran_data.dart';
import '../../data/reading_progress_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/reading_context.dart';
import '../../models/surah.dart';
import '../../theme/app_theme.dart';
import '../bookmarks/bookmark_screen.dart';
import '../reading/ayah_reading_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({
    super.key,
    this.readingContext = const ReadingContext.explore(),
  });

  final ReadingContext readingContext;

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  int? _selectedJuz;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshJuzState();
  }

  void _refreshJuzState() {
    _selectedJuz = CollectiveReadingService.getSelectedJuz();
  }

  Future<void> _showJuzPicker() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completedJuzs = CollectiveReadingService.getCompletedJuzs();
    final chosenJuz = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('ramadan_juz_select'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(30, (index) {
                  final juzNumber = index + 1;
                  final isSelected = _selectedJuz == juzNumber;
                  final isCompleted = completedJuzs.contains(juzNumber);
                  return GestureDetector(
                    onTap: () =>
                        Navigator.of(bottomSheetContext).pop(juzNumber),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.surfaceContainerHighest
                            : isCompleted
                                ? AppColors.emphasisAccent.withValues(
                                    alpha: 0.08,
                                  )
                                : colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : isCompleted
                                  ? AppColors.emphasisAccent.withValues(
                                      alpha: 0.26,
                                    )
                                  : theme.dividerColor,
                        ),
                      ),
                      child: Text(
                        '$juzNumber',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: isSelected || isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.primary
                              : isCompleted
                                  ? AppColors.emphasisAccent
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );

    if (chosenJuz == null) return;
    await CollectiveReadingService.selectJuz(chosenJuz);
    _refreshJuzState();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openResumeReading() async {
    const readingContext = ReadingContext.explore();
    final progress = ReadingProgressService.getContextProgress(readingContext);
    if (progress == null) return;
    final languageCode = Localizations.localeOf(context).languageCode;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: progress.surah,
          surahName: QuranData.instance.getSurahName(
            progress.surah,
            languageCode: languageCode,
          ),
          readingContext: readingContext,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openJuzReading() async {
    if (_selectedJuz == null) {
      await _showJuzPicker();
      return;
    }

    await _openJuzReadingFor(_selectedJuz!);
  }

  Future<void> _openJuzReadingFor(int juzNumber) async {
    if (_selectedJuz != juzNumber) {
      await CollectiveReadingService.selectJuz(juzNumber);
      _refreshJuzState();
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    final ctx = ReadingContext.juz(juzNumber);
    final progress = ReadingProgressService.getContextProgress(ctx);
    final range = CollectiveReadingService.getJuzRange(juzNumber);
    final surah = progress?.surah ?? range?.startSurah ?? 1;
    final ayah = progress?.ayah ?? range?.startAyah ?? 1;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleJuzCompleted(int juzNumber) async {
    if (_selectedJuz != juzNumber) {
      await CollectiveReadingService.selectJuz(juzNumber);
      _refreshJuzState();
    }

    if (CollectiveReadingService.isCompleted(juzNumber)) {
      await CollectiveReadingService.undoCompleted(juzNumber);
    } else {
      await CollectiveReadingService.markCompleted();
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final surahs = QuranData.instance.surahs;
    const resumeContext = ReadingContext.explore();
    final readingProgress =
        ReadingProgressService.getContextProgress(resumeContext);
    final languageCode = Localizations.localeOf(context).languageCode;
    final resumeSubtitle = readingProgress == null
        ? S.t(context, 'quran_resume_empty_subtitle')
        : '${QuranData.instance.getSurahName(readingProgress.surah, languageCode: languageCode)} · ${readingProgress.ayah}. ${S.t(context, 'ayah_label')}';
    final selectedJuz = _selectedJuz;
    final selectedJuzProgress = selectedJuz == null
        ? null
        : ReadingProgressService.getContextProgress(
            ReadingContext.juz(selectedJuz));
    final completedJuzs = CollectiveReadingService.getCompletedJuzs().toSet();
    final juzSubtitle = selectedJuz == null
        ? S.t(context, 'quran_juz_empty_summary')
        : S
            .t(context, 'quran_juz_selected')
            .replaceAll('{juz}', '$selectedJuz');
    final continueJuzBody = selectedJuz == null || selectedJuzProgress == null
        ? null
        : '${QuranData.instance.getSurahName(selectedJuzProgress.surah, languageCode: languageCode)} · ${selectedJuzProgress.ayah}. ${S.t(context, 'ayah_label')}';

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
        title: Text(
          S.t(context, 'surahs'),
          style: const TextStyle(
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _QuranSegmentedSwitch(
            selectedIndex: _selectedTabIndex,
            onSelected: (index) => setState(() => _selectedTabIndex = index),
          ),
          const SizedBox(height: 18),
          if (_selectedTabIndex == 0) ...[
            _SectionLabel(title: S.t(context, 'quran_read_tab_title')),
            const SizedBox(height: 10),
            _QuranEntryCard(
              title: readingProgress == null
                  ? S.t(context, 'quran_resume_empty_title')
                  : S.t(context, 'quran_resume_title'),
              subtitle: resumeSubtitle,
              icon: Icons.menu_book_rounded,
              actionLabel:
                  readingProgress == null ? null : S.t(context, 'continue'),
              onTap: readingProgress == null ? null : _openResumeReading,
            ),
            const SizedBox(height: 18),
            _SectionLabel(title: S.t(context, 'quran_surah_list_title')),
            const SizedBox(height: 10),
            for (var index = 0; index < surahs.length; index++) ...[
              _SurahListItem(
                surah: surahs[index],
                readingContext: widget.readingContext,
              ),
              if (index != surahs.length - 1) const SizedBox(height: 8),
            ],
          ] else ...[
            _SectionLabel(title: S.t(context, 'quran_juz_journey_title')),
            const SizedBox(height: 10),
            _QuranEntryCard(
              title: S.t(context, 'quran_juz_journey_title'),
              subtitle: juzSubtitle,
              icon: Icons.auto_stories_rounded,
              footer: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showJuzPicker,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.indigoAccent,
                    ),
                    child: Text(
                      selectedJuz == null
                          ? S.t(context, 'quran_juz_pick')
                          : S.get('ramadan_change_juz'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              child: continueJuzBody == null
                  ? null
                  : _JourneyRow(
                      title: S.t(context, 'quran_juz_continue'),
                      body: continueJuzBody,
                      onTap: _openJuzReading,
                    ),
            ),
            const SizedBox(height: 18),
            _SectionLabel(title: S.t(context, 'quran_juz_list_title')),
            const SizedBox(height: 10),
            for (var juzNumber = 1; juzNumber <= 30; juzNumber++) ...[
              _JuzListItem(
                juzNumber: juzNumber,
                isSelected: selectedJuz == juzNumber,
                isCompleted: completedJuzs.contains(juzNumber),
                onToggleCompleted: () => _toggleJuzCompleted(juzNumber),
              ),
              if (juzNumber != 30) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _QuranSegmentedSwitch extends StatelessWidget {
  const _QuranSegmentedSwitch({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEE8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7DED7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: S.t(context, 'quran_tab_read'),
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentButton(
              label: S.t(context, 'quran_tab_juz'),
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDF9F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: selected ? Border.all(color: const Color(0xFFE6DDD6)) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? const Color(0xFF2B2725) : const Color(0xFF7A746F),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7A746F),
      ),
    );
  }
}

class _QuranEntryCard extends StatelessWidget {
  const _QuranEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onTap,
    this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Widget? child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEDE6E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF6F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.indigoAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2B2725),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7A746F),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.indigoAccent,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({
    required this.title,
    required this.body,
    this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2725),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.45,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }
}

class _JuzListItem extends StatelessWidget {
  const _JuzListItem({
    required this.juzNumber,
    required this.isSelected,
    required this.isCompleted,
    required this.onToggleCompleted,
  });

  final int juzNumber;
  final bool isSelected;
  final bool isCompleted;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final subtitle = isCompleted
        ? S.get('ramadan_completed')
        : isSelected
            ? S.t(context, 'quran_juz_continue')
            : S.t(context, 'quran_juz_pick');
    final cardColor = isSelected
        ? const Color(0xFFF3F7F1)
        : isCompleted
            ? const Color(0xFFF8F3EE)
            : const Color(0xFFFDF9F6);
    final borderColor = isSelected
        ? const Color(0xFFD7E5D2)
        : isCompleted
            ? const Color(0xFFE5D9CD)
            : const Color(0xFFEDE6E1);
    final badgeColor = isSelected
        ? AppColors.emphasisAccent.withValues(alpha: 0.12)
        : isCompleted
            ? const Color(0xFFF1E8DE)
            : const Color(0xFFFBF6F2);
    final badgeTextColor = isSelected
        ? AppColors.emphasisAccent
        : isCompleted
            ? const Color(0xFF9A8D80)
            : const Color(0xFF7A746F);
    final actionColor =
        isCompleted ? const Color(0xFF9A8D80) : AppColors.emphasisAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$juzNumber',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$juzNumber. ${S.t(context, 'reading_juz_label')}',
                  style: const TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2B2725),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7A746F),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onToggleCompleted,
            style: TextButton.styleFrom(
              foregroundColor: actionColor,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              isCompleted ? S.get('undo') : S.get('ramadan_mark_completed'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahListItem extends StatelessWidget {
  const _SurahListItem({
    required this.surah,
    required this.readingContext,
  });

  final Surah surah;
  final ReadingContext readingContext;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AyahReadingScreen(
              surahNumber: surah.id,
              surahName: QuranData.instance.getSurahName(
                surah.id,
                languageCode: languageCode,
              ),
              readingContext: readingContext,
            ),
          ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    QuranData.instance.getSurahName(
                      surah.id,
                      languageCode: languageCode,
                    ),
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
                    '${surah.ayahCount} ${S.t(context, 'ayah_count_suffix')}',
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
