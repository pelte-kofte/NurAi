import 'package:flutter/material.dart';
import '../../core/config/seasonal_config.dart';
import '../../data/collective_reading_service.dart';
import '../../data/quran_data.dart';
import '../../data/ramadan_daily_note_service.dart';
import '../../data/reading_progress_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/reading_context.dart';
import '../reading/ayah_reading_screen.dart';
import '../ramadan/ramadan_suggestions_screen.dart';

class RamadanHubScreen extends StatefulWidget {
  const RamadanHubScreen({super.key});

  @override
  State<RamadanHubScreen> createState() => _RamadanHubScreenState();
}

class _RamadanHubScreenState extends State<RamadanHubScreen> {
  RamadanDailyNote? _dailyNote;
  int? _selectedJuz;
  bool _isJuzCompleted = false;
  String? _loadedLanguageCode;

  @override
  void initState() {
    super.initState();
    _refreshJuzState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedLanguageCode != languageCode) {
      _loadedLanguageCode = languageCode;
      _loadDailyNote(languageCode);
    }
  }

  Future<void> _loadDailyNote(String languageCode) async {
    if (!SeasonalConfig.isRamadanSeason) {
      if (!mounted) return;
      setState(() => _dailyNote = null);
      return;
    }
    final assetPath = switch (languageCode) {
      'tr' => 'assets/ramadan/daily_notes_tr.json',
      'en' => 'assets/ramadan/daily_notes_en.json',
      'ar' => 'assets/ramadan/daily_notes_ar.json',
      'de' => 'assets/ramadan/daily_notes_de.json',
      'fr' => 'assets/ramadan/daily_notes_fr.json',
      _ => 'assets/ramadan/daily_notes_en.json',
    };
    await RamadanDailyNoteService.load(assetPath: assetPath);
    if (!mounted) return;
    setState(() {
      _dailyNote = RamadanDailyNoteService.getTodayNote();
    });
  }

  void _openHatimReading() {
    const ctx = ReadingContext.hatim();
    final progress = ReadingProgressService.getContextProgress(ctx);
    final surah = progress?.surah ?? 1;
    final ayah = progress?.ayah ?? 1;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
  }

  void _refreshJuzState() {
    _selectedJuz = CollectiveReadingService.getSelectedJuz();
    _isJuzCompleted = CollectiveReadingService.isCompleted();
  }

  Future<void> _showJuzPicker() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
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
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$juzNumber',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.primary
                              : secondaryTextColor,
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
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  Future<void> _markJuzCompleted() async {
    await CollectiveReadingService.markCompleted();
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  void _openJuzReading() {
    if (_selectedJuz == null) return;

    final juzNumber = _selectedJuz!;
    final ctx = ReadingContext.juz(juzNumber);
    final progress = ReadingProgressService.getContextProgress(ctx);
    final range = CollectiveReadingService.getJuzRange(juzNumber);
    final surah = progress?.surah ?? range?.startSurah ?? 1;
    final ayah = progress?.ayah ?? range?.startAyah ?? 1;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
  }

  void _openDuas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RamadanSuggestionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    const hatimCtx = ReadingContext.hatim();
    final hatimProgress = ReadingProgressService.getContextProgress(hatimCtx);
    final hatimSubtitle = hatimProgress != null
        ? '${QuranData.instance.getSurahName(hatimProgress.surah)} \u00b7 ${hatimProgress.ayah}. ${S.get('ayah_label')}'
        : S.get('ramadan_hatim_subtitle');
    final hatimCta =
        hatimProgress != null ? S.get('continue') : S.get('ramadan_start');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: secondaryTextColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.get('ramadan_hub_title'),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        children: [
          Text(
            S.get('ramadan_intro'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(S.get('ramadan_section_reading')),
          const SizedBox(height: 10),
          _ReadingCard(
            title: S.get('hatim_title'),
            subtitle: hatimSubtitle,
            cta: hatimCta,
            onTap: _openHatimReading,
          ),
          const SizedBox(height: 22),
          _SectionHeader(S.get('juz_title')),
          const SizedBox(height: 10),
          _buildJuzIntentionCard(),
          if (SeasonalConfig.isRamadanSeason) ...[
            const SizedBox(height: 22),
            _SectionHeader(S.get('ramadan_section_daily_note')),
            const SizedBox(height: 10),
            _DailyNoteCard(
              text: _dailyNote?.text ?? S.get('prayer_times_loading'),
            ),
            const SizedBox(height: 22),
            _SectionHeader(S.get('ramadan_section_duas')),
            const SizedBox(height: 10),
            _SimpleNavCard(
              title: S.get('ramadan_suggestions_entry'),
              leadingIcon: Icons.menu_book_outlined,
              onTap: _openDuas,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJuzIntentionCard() {
    if (_selectedJuz == null) {
      return _SimpleNavCard(
        title: S.get('ramadan_juz_select'),
        subtitle: S.get('ramadan_juz_select_subtitle'),
        onTap: _showJuzPicker,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${S.get('ramadan_selected_juz')}: $_selectedJuz',
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (_isJuzCompleted) ...[
            const SizedBox(height: 4),
            Text(
              S.get('ramadan_completed'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _JuzActionButton(
                  label: S.get('ramadan_continue_juz'),
                  primary: true,
                  onTap: _openJuzReading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _JuzActionButton(
                  label: S.get('ramadan_change_juz'),
                  onTap: _showJuzPicker,
                ),
              ),
            ],
          ),
          if (!_isJuzCompleted) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _markJuzCompleted,
              child: Text(
                S.get('ramadan_mark_completed'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.bodyMedium?.color ??
            theme.colorScheme.onSurface.withValues(alpha: 0.72),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _ReadingCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: theme.textTheme.bodyMedium?.color ??
                          colorScheme.onSurface.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cta,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyNoteCard extends StatelessWidget {
  final String text;
  const _DailyNoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                size: 16,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                S.get('ramadan_note_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _JuzActionButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _JuzActionButton({
    required this.label,
    this.primary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary ? colorScheme.primary : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primary
                ? colorScheme.primary
                : theme.textTheme.bodyMedium?.color ??
                    colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _SimpleNavCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback onTap;

  const _SimpleNavCard({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final chevron = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 17, color: secondaryTextColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              chevron,
              size: 20,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
