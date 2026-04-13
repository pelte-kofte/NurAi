import 'package:flutter/material.dart';
import '../../core/config/seasonal_config.dart';
import '../../data/adhan_notification_service.dart';
import '../../data/collective_reading_service.dart';
import '../../data/quran_data.dart';
import '../../data/ramadan_daily_note_service.dart';
import '../../data/reading_progress_service.dart';
import '../../data/premium_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/reading_context.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_cta_button.dart';
import '../adhan/adhan_times_screen.dart';
import '../home/today_screen.dart';
import '../reading/ayah_reading_screen.dart';
import '../ramadan/ramadan_suggestions_screen.dart';
import '../settings/premium_page.dart';
import '../tasbih/tasbih_screen.dart';

enum _GuidedHelperOption {
  calmer,
  readQuran,
  shortDhikr,
  dailyReminder,
  beforeSleep,
  prepareForPrayer,
}

class RamadanHubScreen extends StatefulWidget {
  const RamadanHubScreen({super.key});

  @override
  State<RamadanHubScreen> createState() => _RamadanHubScreenState();
}

class _RamadanHubScreenState extends State<RamadanHubScreen> {
  RamadanDailyNote? _dailyNote;
  int? _selectedJuz;
  bool _isJuzCompleted = false;
  List<int> _completedJuzs = const [];
  SpiritualProgressState _spiritualProgress = const SpiritualProgressState(
    streakCount: 0,
    lastReadDate: null,
    currentJuz: 1,
    highestCompletedJuz: 0,
    completedJuzCount: 0,
    allJuzCompleted: false,
    dailyGoalDone: false,
    dailyGoalDate: null,
    reflectionStreakCount: 0,
    reflectionLastCompletedDate: null,
    morningReflectionCompletedDate: null,
    eveningReflectionCompletedDate: null,
  );
  String? _loadedLanguageCode;

  @override
  void initState() {
    super.initState();
    _refreshJuzState();
    _loadSpiritualProgress();
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

  Future<void> _loadSpiritualProgress() async {
    final state = await SpiritualProgressService.loadState();
    if (!mounted) return;
    setState(() => _spiritualProgress = state);
  }

  Future<void> _openHatimReading() async {
    const ctx = ReadingContext.hatim();
    final progress = ReadingProgressService.getContextProgress(ctx);
    final surah = progress?.surah ?? 1;
    final ayah = progress?.ayah ?? 1;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
    await _loadSpiritualProgress();
    await AdhanNotificationService.syncReadingReminder();
  }

  void _refreshJuzState() {
    _selectedJuz = CollectiveReadingService.getSelectedJuz();
    _completedJuzs = CollectiveReadingService.getCompletedJuzs();
    _isJuzCompleted = CollectiveReadingService.isCompleted(_selectedJuz);
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
                  final isCompleted = _completedJuzs.contains(juzNumber);
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
                                  ? AppColors.emphasisAccent
                                      .withValues(alpha: 0.26)
                                  : theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
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
                                        : secondaryTextColor,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.emphasisAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
    await AdhanNotificationService.syncReadingReminder();
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  Future<void> _markJuzCompleted() async {
    await CollectiveReadingService.markCompleted();
    await _loadSpiritualProgress();
    await AdhanNotificationService.syncReadingReminder();
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  Future<void> _undoCompletedJuz() async {
    if (_selectedJuz == null) return;
    await CollectiveReadingService.undoCompleted(_selectedJuz);
    await _loadSpiritualProgress();
    await AdhanNotificationService.syncReadingReminder();
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  Future<void> _resetHatimProgress() async {
    final confirmed = await _showResetProgressConfirmation();
    if (confirmed != true) return;
    await ReadingProgressService.resetHatimProgress();
    await _loadSpiritualProgress();
    await AdhanNotificationService.syncReadingReminder();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resetJuzProgress() async {
    if (_selectedJuz == null) return;
    final confirmed = await _showResetProgressConfirmation();
    if (confirmed != true) return;
    await ReadingProgressService.resetJuzProgress(_selectedJuz!);
    await CollectiveReadingService.resetSelectedJuzProgress(_selectedJuz);
    await _loadSpiritualProgress();
    await AdhanNotificationService.syncReadingReminder();
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  Future<bool?> _showResetProgressConfirmation() {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('reading_reset_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.get('reading_reset_subtitle'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              AppCtaButton(
                label: S.get('reading_reset_confirm'),
                fullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(S.get('cancel')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openJuzReading() async {
    if (_selectedJuz == null) return;

    final juzNumber = _selectedJuz!;
    final ctx = ReadingContext.juz(juzNumber);
    final progress = ReadingProgressService.getContextProgress(ctx);
    final range = CollectiveReadingService.getJuzRange(juzNumber);
    final surah = progress?.surah ?? range?.startSurah ?? 1;
    final ayah = progress?.ayah ?? range?.startAyah ?? 1;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
    await _loadSpiritualProgress();
    await AdhanNotificationService.syncReadingReminder();
  }

  void _openDuas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RamadanSuggestionsScreen()),
    );
  }

  IconData _iconForGuidedOption(_GuidedHelperOption option) {
    return switch (option) {
      _GuidedHelperOption.calmer => Icons.favorite_outline_rounded,
      _GuidedHelperOption.readQuran => Icons.menu_book_rounded,
      _GuidedHelperOption.shortDhikr => Icons.radio_button_checked_rounded,
      _GuidedHelperOption.dailyReminder => Icons.notifications_none_rounded,
      _GuidedHelperOption.beforeSleep => Icons.bedtime_rounded,
      _GuidedHelperOption.prepareForPrayer => Icons.schedule_rounded,
    };
  }

  String _messageForGuidedOption(_GuidedHelperOption option) {
    return switch (option) {
      _GuidedHelperOption.calmer => S.get('guided_helper_message_calmer'),
      _GuidedHelperOption.readQuran =>
        S.get('guided_helper_message_read_quran'),
      _GuidedHelperOption.shortDhikr =>
        S.get('guided_helper_message_short_dhikr'),
      _GuidedHelperOption.dailyReminder =>
        S.get('guided_helper_message_daily_reminder'),
      _GuidedHelperOption.beforeSleep =>
        S.get('guided_helper_message_before_sleep'),
      _GuidedHelperOption.prepareForPrayer =>
        S.get('guided_helper_message_prepare_prayer'),
    };
  }

  Future<void> _openGuidedHelper(_GuidedHelperOption option) async {
    if (option == _GuidedHelperOption.beforeSleep &&
        !PremiumService.isPremium.value) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumPage()),
      );
      await _loadSpiritualProgress();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _messageForGuidedOption(option),
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

    switch (option) {
      case _GuidedHelperOption.calmer:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TodayScreen(intent: TodayScreenIntent.calmer),
          ),
        );
        break;
      case _GuidedHelperOption.dailyReminder:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const TodayScreen(intent: TodayScreenIntent.reminder),
          ),
        );
        break;
      case _GuidedHelperOption.beforeSleep:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const TodayScreen(intent: TodayScreenIntent.beforeSleep),
          ),
        );
        break;
      case _GuidedHelperOption.readQuran:
        await _openHatimReading();
        break;
      case _GuidedHelperOption.shortDhikr:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TasbihScreen()),
        );
        break;
      case _GuidedHelperOption.prepareForPrayer:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdhanTimesScreen()),
        );
        break;
    }
    await _loadSpiritualProgress();
  }

  List<({String label, _GuidedHelperOption option, bool premiumOnly})>
      _guidedOptions() {
    return [
      (
        label: S.get('guided_helper_calmer'),
        option: _GuidedHelperOption.calmer,
        premiumOnly: false,
      ),
      (
        label: S.get('guided_helper_read_quran'),
        option: _GuidedHelperOption.readQuran,
        premiumOnly: false,
      ),
      (
        label: S.get('guided_helper_short_dhikr'),
        option: _GuidedHelperOption.shortDhikr,
        premiumOnly: false,
      ),
      (
        label: S.get('guided_helper_daily_reminder'),
        option: _GuidedHelperOption.dailyReminder,
        premiumOnly: false,
      ),
      (
        label: S.get('guided_helper_before_sleep'),
        option: _GuidedHelperOption.beforeSleep,
        premiumOnly: true,
      ),
      (
        label: S.get('guided_helper_prepare_prayer'),
        option: _GuidedHelperOption.prepareForPrayer,
        premiumOnly: false,
      ),
    ];
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
    final hasActiveHatimJourney = hatimProgress != null;

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
          _SectionHeader(S.get('guided_helper_title')),
          const SizedBox(height: 10),
          _GuidedHelperCard(
            subtitle: S.get('guided_helper_subtitle'),
            options: _guidedOptions(),
            iconForOption: _iconForGuidedOption,
            onSelect: _openGuidedHelper,
            isPremiumUser: PremiumService.isPremium.value,
          ),
          const SizedBox(height: 22),
          _SectionHeader(S.get('spiritual_progress_title')),
          const SizedBox(height: 10),
          _SpiritualProgressCard(progress: _spiritualProgress),
          const SizedBox(height: 22),
          _SectionHeader(S.get('ramadan_section_reading')),
          const SizedBox(height: 10),
          _ReadingCard(
            title: S.get('hatim_title'),
            subtitle: hatimSubtitle,
            cta: hatimCta,
            onTap: _openHatimReading,
            secondaryActions: hasActiveHatimJourney
                ? [
                    (
                      label: S.get('reading_reset_action'),
                      onTap: _resetHatimProgress,
                    ),
                  ]
                : const [],
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
        color: _isJuzCompleted
            ? const Color(0xFFEAF4EE)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isJuzCompleted
              ? AppColors.emphasisAccent.withValues(alpha: 0.42)
              : Theme.of(context).dividerColor,
          width: _isJuzCompleted ? 1.25 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isJuzCompleted
                ? AppColors.emphasisAccent.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: _isJuzCompleted ? 24 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${S.get('ramadan_selected_juz')}: $_selectedJuz',
                  style: TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (_isJuzCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.emphasisAccent.withValues(alpha: 0.34),
                      width: 1.15,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: AppColors.emphasisAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        S.get('ramadan_completed'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emphasisAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isJuzCompleted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                S.get('ramadan_completed_hint'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
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
            if (ReadingProgressService.hasContextProgress(
              ReadingContext.juz(_selectedJuz!),
            )) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _resetJuzProgress,
                child: Text(
                  S.get('reading_reset_action'),
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
          ] else ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                GestureDetector(
                  onTap: _undoCompletedJuz,
                  child: Text(
                    S.get('undo'),
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
                GestureDetector(
                  onTap: _resetJuzProgress,
                  child: Text(
                    S.get('reading_reset_action'),
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
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidedHelperCard extends StatelessWidget {
  const _GuidedHelperCard({
    required this.subtitle,
    required this.options,
    required this.iconForOption,
    required this.onSelect,
    required this.isPremiumUser,
  });

  final String subtitle;
  final List<({String label, _GuidedHelperOption option, bool premiumOnly})>
      options;
  final IconData Function(_GuidedHelperOption option) iconForOption;
  final ValueChanged<_GuidedHelperOption> onSelect;
  final bool isPremiumUser;

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
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final item = options[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(item.option),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.emphasisAccent.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconForOption(item.option),
                              size: 18,
                              color: AppColors.emphasisAccent,
                            ),
                          ),
                          const Spacer(),
                          if (item.premiumOnly)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isPremiumUser
                                    ? AppColors.turquoiseAccentStrong
                                        .withValues(alpha: 0.14)
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isPremiumUser
                                      ? AppColors.turquoiseAccentStrong
                                          .withValues(alpha: 0.22)
                                      : theme.dividerColor,
                                ),
                              ),
                              child: Text(
                                isPremiumUser
                                    ? S.get('premium_status_active')
                                    : S.get('premium_title'),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isPremiumUser
                                      ? AppColors.turquoiseAccentStrong
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.72),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
  final List<({String label, VoidCallback onTap})> secondaryActions;

  const _ReadingCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
    this.secondaryActions = const [],
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
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.emphasisAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.emphasisAccent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    cta,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emphasisAccent,
                    ),
                  ),
                ),
              ],
            ),
            if (secondaryActions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final action in secondaryActions)
                    GestureDetector(
                      onTap: action.onTap,
                      child: Text(
                        action.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: theme.textTheme.bodyMedium?.color ??
                              colorScheme.onSurface.withValues(alpha: 0.72),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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

class _SpiritualProgressCard extends StatelessWidget {
  const _SpiritualProgressCard({required this.progress});

  final SpiritualProgressState progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ??
        colorScheme.onSurface.withValues(alpha: 0.72);
    final progressValue = (progress.completedJuzCount / 30).clamp(0.0, 1.0);
    final connectionTitle = S.get('spiritual_streak_title');
    final connectionStatus = progress.dailyGoalDone
        ? S.get('spiritual_connection_status_today')
        : progress.streakCount > 0
            ? S.get('spiritual_connection_status_recent')
            : S.get('spiritual_connection_status_empty');
    final connectionDetail = progress.streakCount > 1
        ? S
            .get('spiritual_connection_detail_count')
            .replaceAll('{count}', '${progress.streakCount}')
        : S.get('spiritual_connection_detail_gentle');
    final juzText = S.get('spiritual_juz_label');
    final completedText = progress.allJuzCompleted
        ? S.get('spiritual_progress_all_completed')
        : S
            .get('spiritual_progress_completed_label')
            .replaceAll('{current}', '${progress.currentJuz}');
    final progressSummary = progress.completedJuzCount == 0
        ? S.get('spiritual_progress_summary_empty')
        : S
            .get('spiritual_progress_summary')
            .replaceAll('{completed}', '${progress.completedJuzCount}')
            .replaceAll('{highest}', '${progress.highestCompletedJuz}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.82,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  size: 15,
                  color: AppColors.emphasisAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectionTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      connectionStatus,
                      style: TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      connectionDetail,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 15,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                juzText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            progressSummary,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 4,
              backgroundColor: AppColors.emphasisAccent.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.emphasisAccent.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            completedText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                progress.dailyGoalDone
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: progress.dailyGoalDone
                    ? AppColors.emphasisAccent
                    : secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.dailyGoalDone
                      ? S.get('spiritual_daily_status_done')
                      : S.get('spiritual_daily_status_pending'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
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
    return AppCtaButton(
      label: label,
      level: primary ? AppCtaLevel.primary : AppCtaLevel.secondary,
      fullWidth: true,
      compact: true,
      onPressed: onTap,
      textStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: primary
            ? AppColors.ctaPrimaryText
            : theme.textTheme.bodyMedium?.color ??
                colorScheme.onSurface.withValues(alpha: 0.72),
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
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
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
