import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/seasonal_config.dart';
import '../../data/adhan_times_service.dart';
import '../../data/asmaul_husna_service.dart';
import '../../data/daily_ayah_service.dart';
import '../../data/daily_content_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/quran_data.dart';
import '../../data/quran_turkish_meal_service.dart';
import '../../data/reading_progress_service.dart';
import '../../services/share_card_service.dart';
import '../../data/user_profile_service.dart';
import '../../l10n/app_strings.dart';
import '../../main.dart';
import '../../models/prayer_location.dart';
import '../../models/reading_context.dart';
import '../../theme/app_theme.dart';
import '../../widgets/next_prayer_pill.dart';
import '../../widgets/quick_actions_popover.dart';
import '../adhan/adhan_times_screen.dart';
import '../asma/asmaul_husna_screen.dart';
import '../qibla/qibla_screen.dart';
import '../ramadan/ramadan_hub_screen.dart';
import '../reading/ayah_reading_screen.dart';
import '../settings/settings_screen.dart';
import '../surah/surah_list_screen.dart';
import '../tasbih/tasbih_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final GlobalKey _quickActionsKey = GlobalKey();
  bool _checkedNamePrompt = false;
  Timer? _clockTicker;
  bool _clockTickerIsPerSecond = false;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNamePrompt();
    });
    _startClockTicker(perSecond: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    QuickActionsPopover.hide();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  void didPushNext() {
    QuickActionsPopover.hide();
  }

  void _startClockTicker({required bool perSecond}) {
    _clockTicker?.cancel();
    _clockTickerIsPerSecond = perSecond;
    final interval =
        perSecond ? const Duration(seconds: 1) : const Duration(seconds: 30);
    _clockTicker = Timer.periodic(interval, (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  void _ensureClockTicker({required bool perSecond}) {
    if (_clockTicker != null && _clockTickerIsPerSecond == perSecond) return;
    _startClockTicker(perSecond: perSecond);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return S.get('greeting_night');
    if (hour < 12) return S.get('greeting_morning');
    if (hour < 17) return S.get('greeting_day');
    if (hour < 21) return S.get('greeting_evening');
    return S.get('greeting_night');
  }

  String _buildGreetingText(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return _getGreeting();
    return '${_getGreeting()}, $name';
  }

  Future<void> _maybeShowNamePrompt() async {
    if (_checkedNamePrompt || !mounted) return;
    _checkedNamePrompt = true;

    if (!UserProfileService.shouldShowNamePrompt) return;

    final controller = TextEditingController(
      text: UserProfileService.displayName ?? '',
    );
    var completed = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
                S.get('name_prompt_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: S.get('name_hint'),
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB57A5A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    completed = true;
                    await UserProfileService.setDisplayName(controller.text);
                    await UserProfileService.markNamePromptShown();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    S.get('continue'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () async {
                    completed = true;
                    await UserProfileService.markNamePromptShown();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    S.get('skip'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() async {
      if (!completed) {
        await UserProfileService.markNamePromptShown();
      }
    });

    controller.dispose();
  }

  void _toggleQuickActions() {
    QuickActionsPopover.toggle(
      context: context,
      anchorKey: _quickActionsKey,
      onQibla: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        );
      },
      onAdhanTimes: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdhanTimesScreen()),
        );
      },
      onTasbih: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TasbihScreen()),
        );
      },
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SettingsScreen(scrollController: scrollController),
            );
          },
        );
      },
    );
  }

  String? _iftarCountdown(PrayerLocation location) {
    if (!SeasonalConfig.isRamadanSeason) return null;
    if (!location.hasCoordinates) return null;
    final times = AdhanTimesService.computeTimes(
      _now,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final nextPrayer = _nextPrayerType(times);
    if (nextPrayer != _PrayerType.maghrib) return null;

    final diff = times.maghrib.difference(_now);
    if (diff.isNegative || diff >= const Duration(minutes: 60)) return null;

    final totalSeconds = diff.inSeconds.clamp(0, 3599);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  _PrayerType _nextPrayerType(AdhanDayTimes times) {
    if (times.fajr.isAfter(_now)) return _PrayerType.fajr;
    if (times.dhuhr.isAfter(_now)) return _PrayerType.dhuhr;
    if (times.asr.isAfter(_now)) return _PrayerType.asr;
    if (times.maghrib.isAfter(_now)) return _PrayerType.maghrib;
    if (times.isha.isAfter(_now)) return _PrayerType.isha;
    return _PrayerType.none;
  }

  String? _countryFromPrayerLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final raw = location.cityName ?? '';
    final parts = raw.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 26),
              ValueListenableBuilder<PrayerLocation>(
                valueListenable: LocalPreferencesService.prayerLocation,
                builder: (context, location, _) {
                  final countdown = _iftarCountdown(location);
                  final showIftarCountdown = countdown != null;
                  _ensureClockTicker(perSecond: showIftarCountdown);

                  if (showIftarCountdown) {
                    return _buildCountdownCard(countdown);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        title: S.get('home_section_now_upcoming'),
                        icon: Icons.schedule_rounded,
                      ),
                      const SizedBox(height: 10),
                      NextPrayerPill(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdhanTimesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildSectionHeader(
                title: S.get('home_section_for_today'),
                icon: Icons.auto_awesome_outlined,
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: DailyContentService.revision,
                builder: (context, _, __) => _buildPrimaryDailyCard(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TodayScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.turquoiseAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  S.get('home_see_more_for_today'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: S.get('home_section_explore'),
                icon: Icons.explore_outlined,
              ),
              const SizedBox(height: 10),
              _buildExploreQuranEntry(context),
              const SizedBox(height: 12),
              _buildExploreEntry(
                title: S.get('asma_screen_title'),
                subtitle: S.get('asma_explore_subtitle'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AsmaulHusnaScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildExploreEntry(
                title: S.get('ramadan_hub_title'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RamadanHubScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: _quickActionsKey,
          onTap: _toggleQuickActions,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Icon(
              Icons.menu_rounded,
              size: 24,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<String?>(
            valueListenable: UserProfileService.displayNameNotifier,
            builder: (context, displayName, _) {
              return Text(
                _buildGreetingText(displayName),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
              );
            },
          ),
        ),
        GestureDetector(
          onTap: _openSettingsModal,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.settings_rounded,
              size: 24,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(String countdown) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timelapse_rounded,
            size: 16,
            color: colorScheme.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.get('home_time_to_maghrib'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ),
          Text(
            countdown,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.4,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryDailyCard() {
    final date = DateTime.now();
    final contentType = DailyContentService.homeContentTypeForDate(date);
    final locale = Locale(LocalPreferencesService.language.value);

    switch (contentType) {
      case HomeDailyContentType.verse:
        final ayah = DailyAyahService.getTodayAyahWithContext(
          QuranData.instance.ayahs,
          QuranData.instance.getSurahName,
        );
        return FutureBuilder<String>(
          future: DailyAyahService.getAyahReadableText(
            surah: ayah.surahNumber,
            ayah: ayah.ayahNumber,
            locale: locale,
          ),
          builder: (context, snapshot) {
            final localeCode = locale.languageCode.toLowerCase();
            final resolvedReadableText = snapshot.data?.trim();
            final hasReadableText =
                resolvedReadableText != null && resolvedReadableText.isNotEmpty;
            final readableText = hasReadableText
                ? resolvedReadableText
                : (localeCode == 'tr'
                    ? ayah.turkishReadable
                    : (snapshot.connectionState == ConnectionState.done
                        ? S.get('meal_not_available')
                        : S.get('prayer_times_loading')));
            return _buildPrimaryAyahCard(
              ayah: ayah,
              readableText: readableText,
              onShare: hasReadableText || localeCode == 'tr'
                  ? () => _shareAyahCard(
                        ayah: ayah,
                        readableText: readableText,
                      )
                  : null,
            );
          },
        );
      case HomeDailyContentType.hadith:
        final hadith = DailyContentService.todayHadith;
        final hasHadith = hadith?.text.trim().isNotEmpty ?? false;
        return _buildPrimaryCard(
          title: S.get('daily_hadith_title'),
          body: hadith?.text ?? S.get('daily_hadith_empty'),
          source: hadith?.source,
          onShare: hasHadith
              ? () => _shareDailyTextCard(
                    title: S.get('daily_hadith_title'),
                    body: hadith!.text,
                    source: hadith.source,
                  )
              : null,
        );
      case HomeDailyContentType.gentleReminder:
        final reminder = DailyContentService.todayWord;
        final hasReminder = reminder?.text.trim().isNotEmpty ?? false;
        return _buildPrimaryCard(
          title: S.get('daily_word_title'),
          body: reminder?.text ?? S.get('daily_word_empty'),
          onShare: hasReminder
              ? () => _shareDailyTextCard(
                    title: S.get('daily_word_title'),
                    body: reminder!.text,
                  )
              : null,
        );
      case HomeDailyContentType.quote:
        return FutureBuilder<DailyQuoteItem>(
          future: DailyContentService.getQuoteForDate(
            date,
            locale,
          ),
          builder: (context, snapshot) {
            final quote = snapshot.data;
            final hasQuote = quote?.text.trim().isNotEmpty ?? false;
            return _buildPrimaryCard(
              title: S.get('daily_quote_title'),
              body: quote?.text ?? '',
              source: quote?.source,
              onShare: hasQuote
                  ? () => _shareDailyTextCard(
                        title: S.get('daily_quote_title'),
                        body: quote!.text,
                        source: quote.source,
                      )
                  : null,
            );
          },
        );
      case HomeDailyContentType.asma:
        return FutureBuilder<AsmaulHusnaName>(
          future: AsmaulHusnaService.getDailyNameForDate(date, locale),
          builder: (context, snapshot) {
            final asma = snapshot.data;
            if (asma == null) {
              return _buildPrimaryCard(
                title: S.get('daily_asma_title'),
                body: '',
              );
            }
            return _buildPrimaryAsmaCard(
              asma: asma,
              languageCode: locale.languageCode,
              onShare: () => _shareAsmaCard(
                asma: asma,
                languageCode: locale.languageCode,
              ),
            );
          },
        );
    }
  }

  Widget _buildQuranFramedCard({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _PrimaryDailyCardStyle.fromTheme(
      colorScheme: colorScheme,
      isDark: isDark,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: style.borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: style.backgroundGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor,
            blurRadius: style.shadowBlur,
            offset: style.shadowOffset,
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: RadialGradient(
            center: const Alignment(-0.85, -1.0),
            radius: 1.2,
            colors: [
              style.innerGlow,
              style.innerGlow.withValues(alpha: 0),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPrimaryCard({
    required String title,
    required String body,
    String? source,
    VoidCallback? onShare,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final cleanSource = source?.trim() ?? '';
    final card = _buildQuranFramedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (onShare != null) _buildShareButton(onShare),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
          if (cleanSource.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              cleanSource,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
    if (onShare == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onShare,
      child: card,
    );
  }

  Widget _buildPrimaryAyahCard({
    required DailyAyah ayah,
    required String readableText,
    VoidCallback? onShare,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = _buildQuranFramedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  S.get('daily_ayah'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (onShare != null) _buildShareButton(onShare),
            ],
          ),
          const SizedBox(height: 16),
          _buildPrimaryAyahReadableLine(
            ayah: ayah,
            readableText: readableText,
          ),
          const SizedBox(height: 16),
          Text(
            ayah.reference,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
    if (onShare == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onShare,
      child: card,
    );
  }

  Widget _buildPrimaryAsmaCard({
    required AsmaulHusnaName asma,
    required String languageCode,
    VoidCallback? onShare,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final meaning = asma.localizedMeaning(languageCode);
    final reflection = asma.localizedReflection(languageCode);
    final card = _buildQuranFramedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  S.get('daily_asma_title'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (onShare != null)
                _buildOverflowButton(
                  onTap: () => _showAsmaCardMenu(
                    asma: asma,
                    languageCode: languageCode,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            asma.nameArabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            asma.localizedName(languageCode),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.84),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            meaning,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 19,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.55,
            ),
          ),
          if (reflection.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reflection,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
    if (onShare == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openAsmaDetail(asma),
      onLongPress: onShare,
      child: card,
    );
  }

  Widget _buildOverflowButton({required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: S.get('today_card_more_actions'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: colorScheme.onSurface.withValues(alpha: 0.72),
      ),
    );
  }

  Widget _buildShareButton(VoidCallback onShare) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onShare,
      tooltip: S.get('ramadan_suggestions_share'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.ios_share_rounded,
        size: 18,
        color: colorScheme.onSurface.withValues(alpha: 0.72),
      ),
    );
  }

  Future<void> _shareDailyTextCard({
    required String title,
    required String body,
    String? source,
  }) async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: title,
          content: source?.trim().isNotEmpty == true ? body : body,
          reference: source,
          type: title == S.get('daily_hadith_title')
              ? ShareCardType.hadith
              : title == S.get('daily_quote_title')
                  ? ShareCardType.quote
                  : ShareCardType.reminder,
          localeCode: LocalPreferencesService.language.value,
        ),
      );
    } catch (_) {
      _showShareError();
    }
  }

  Future<void> _shareAyahCard({
    required DailyAyah ayah,
    required String readableText,
  }) async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: S.get('daily_ayah'),
          arabicText: ayah.arabic,
          content: readableText,
          reference: ayah.reference,
          type: ShareCardType.ayah,
          localeCode: LocalPreferencesService.language.value,
        ),
      );
    } catch (_) {
      _showShareError();
    }
  }

  Future<void> _shareAsmaCard({
    required AsmaulHusnaName asma,
    required String languageCode,
    String? title,
  }) async {
    try {
      await ShareCardService.shareDailyCard(
        context: context,
        payload: ShareCardPayload(
          title: title ?? S.get('daily_asma_title'),
          arabicText: asma.nameArabic,
          content: _buildAsmaShareContent(
            asma: asma,
            languageCode: languageCode,
            includeDhikr: false,
          ),
          type: ShareCardType.asma,
          localeCode: languageCode,
        ),
      );
    } catch (_) {
      _showShareError();
    }
  }

  String _buildAsmaShareContent({
    required AsmaulHusnaName asma,
    required String languageCode,
    required bool includeDhikr,
  }) {
    final parts = <String>[
      asma.localizedName(languageCode),
      asma.localizedMeaning(languageCode),
    ];
    final reflection = asma.localizedReflection(languageCode).trim();
    if (reflection.isNotEmpty) {
      parts.add('${S.get('asma_reflection_label')}: $reflection');
    }
    if (includeDhikr) {
      final dhikr = asma.localizedDhikr(languageCode).trim();
      if (dhikr.isNotEmpty) {
        parts.add('${S.get('asma_dhikr_label')}: $dhikr');
      }
    }
    return parts.join('\n');
  }

  Future<void> _openAsmaDetail(AsmaulHusnaName asma) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AsmaulHusnaDetailScreen(
          item: asma,
        ),
      ),
    );
  }

  Future<void> _showAsmaCardMenu({
    required AsmaulHusnaName asma,
    required String languageCode,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<_HomeAsmaCardMenuAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetColorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionTile(
                  context: sheetContext,
                  icon: Icons.ios_share_rounded,
                  label: S.get('ramadan_suggestions_share'),
                  onTap: () => Navigator.of(sheetContext).pop(
                    _HomeAsmaCardMenuAction.share,
                  ),
                ),
                const SizedBox(height: 4),
                Divider(
                  height: 1,
                  color: sheetColorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                _buildActionTile(
                  context: sheetContext,
                  icon: Icons.close_rounded,
                  label: S.get('cancel'),
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _HomeAsmaCardMenuAction.share:
        await _shareAsmaCard(
          asma: asma,
          languageCode: languageCode,
        );
        break;
    }
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.get('daily_card_share_failed'))),
    );
  }

  Widget _buildPrimaryAyahReadableLine({
    required DailyAyah ayah,
    required String readableText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = Text(
      readableText,
      style: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.6,
      ),
    );

    final isTurkishLine = readableText.trim().isNotEmpty &&
        readableText.trim() == ayah.turkishReadable.trim();
    if (!isTurkishLine) return text;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showTurkishMealSheet(ayah),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: text,
      ),
    );
  }

  Future<void> _showTurkishMealSheet(DailyAyah ayah) async {
    final meal = await QuranTurkishMealService.getTurkishMeal(
      ayah.surahNumber,
      ayah.ayahNumber,
    );
    if (!mounted) return;

    final fallback = S
        .get('meal_sheet_title_fallback')
        .replaceAll('{surah}', ayah.surahNumber.toString())
        .replaceAll('{ayah}', ayah.ayahNumber.toString());
    final surahName = QuranData.instance
        .getSurahName(
          ayah.surahNumber,
          languageCode: Localizations.localeOf(context).languageCode,
        )
        .trim();
    final title = surahName.isEmpty
        ? fallback
        : '$surahName · ${ayah.ayahNumber}. ${S.get('ayah_label')}';
    final body = (meal?.trim().isNotEmpty ?? false)
        ? meal!.trim()
        : S.get('meal_not_available');

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('meal_label'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.secondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                body,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: body));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(S.get('meal_copied'))),
                      );
                    },
                    child: Text(S.get('meal_copy')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(S.get('meal_close')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreQuranEntry(BuildContext context) {
    const readingContext = ReadingContext.explore();
    final progress = ReadingProgressService.getContextProgress(readingContext);

    return _buildExploreEntry(
      title: S.get('start_reading'),
      subtitle: progress == null
          ? null
          : '${QuranData.instance.getSurahName(progress.surah, languageCode: Localizations.localeOf(context).languageCode)} · ${progress.ayah}. ${S.get('ayah_label')}',
      onTap: () {
        if (progress != null) {
          final surahName = QuranData.instance.getSurahName(
            progress.surah,
            languageCode: Localizations.localeOf(context).languageCode,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AyahReadingScreen(
                surahNumber: progress.surah,
                surahName: surahName,
                readingContext: readingContext,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SurahListScreen()),
          );
        }
      },
    );
  }

  Widget _buildExploreEntry({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline, width: 1),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryDailyCardStyle {
  const _PrimaryDailyCardStyle({
    required this.background,
    required this.backgroundGradient,
    required this.borderColor,
    required this.innerGlow,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final Color background;
  final List<Color> backgroundGradient;
  final Color borderColor;
  final Color innerGlow;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  factory _PrimaryDailyCardStyle.fromTheme({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    if (isDark) {
      return _PrimaryDailyCardStyle(
        background: const Color(0xFF1A1D20),
        backgroundGradient: const [
          Color(0xFF20252A),
          Color(0xFF181C21),
        ],
        borderColor: const Color(0xFF73695E).withValues(alpha: 0.26),
        innerGlow: const Color(0xFFD7C2A3).withValues(alpha: 0.08),
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shadowBlur: 18,
        shadowOffset: const Offset(0, 4),
      );
    }
    return _PrimaryDailyCardStyle(
      background: const Color(0xFFF8F3EA),
      backgroundGradient: const [
        Color(0xFFFDF9F2),
        Color(0xFFF5EEE3),
      ],
      borderColor: const Color(0xFFD9CCBA).withValues(alpha: 0.72),
      innerGlow: const Color(0xFFFFFCF6),
      shadowColor: const Color(0x1E8F7857),
      shadowBlur: 22,
      shadowOffset: const Offset(0, 10),
    );
  }
}

enum _HomeAsmaCardMenuAction {
  share,
}

enum _PrayerType { fajr, dhuhr, asr, maghrib, isha, none }
