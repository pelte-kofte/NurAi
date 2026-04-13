import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/seasonal_config.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../data/adhan_times_service.dart';
import '../../data/asmaul_husna_service.dart';
import '../../data/daily_ayah_service.dart';
import '../../data/daily_content_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/premium_service.dart';
import '../../data/premium_upsell_service.dart';
import '../../data/quran_data.dart';
import '../../data/quran_turkish_meal_service.dart';
import '../../data/reading_progress_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../services/feedback_prompt_service.dart';
import '../../services/feedback_service.dart';
import '../../services/share_card_service.dart';
import '../../data/user_profile_service.dart';
import '../../l10n/app_strings.dart';
import '../../main.dart';
import '../../models/prayer_location.dart';
import '../../models/reading_context.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_cta_button.dart';
import '../../widgets/next_prayer_pill.dart';
import '../../widgets/premium_experience_widgets.dart';
import '../adhan/adhan_times_screen.dart';
import '../asma/asmaul_husna_screen.dart';
import '../companion/companion_flow_screen.dart';
import '../qibla/qibla_screen.dart';
import '../ramadan/ramadan_hub_screen.dart';
import '../reading/ayah_reading_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/premium_page.dart';
import '../surah/surah_list_screen.dart';
import '../tasbih/tasbih_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTodayIntent,
    this.openCompanionFlowOnLaunch = false,
    this.launchedFromNotification = false,
  });

  final TodayScreenIntent? initialTodayIntent;
  final bool openCompanionFlowOnLaunch;
  final bool launchedFromNotification;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  static const _feedbackPromptDelay = Duration(seconds: 8);
  bool _checkedNamePrompt = false;
  Timer? _clockTicker;
  Timer? _premiumUpsellTimer;
  Timer? _feedbackPromptTimer;
  bool _clockTickerIsPerSecond = false;
  DateTime _now = DateTime.now();
  bool _didOpenInitialTodayIntent = false;
  bool _didOpenInitialCompanionFlow = false;
  bool _isPresentingUpsell = false;
  bool _isPresentingFeedbackPrompt = false;
  String? _dismissedNightRitualPromptDateKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNamePrompt();
      _maybeOpenInitialTodayIntent();
      _maybeOpenInitialCompanionFlow();
      _scheduleTimedUpsellCheck();
      _scheduleFeedbackPromptCheck();
    });
    _startClockTicker(perSecond: false);
    PremiumService.activationSuccessRevision
        .addListener(_handlePremiumActivationSuccess);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTodayIntent != oldWidget.initialTodayIntent &&
        widget.initialTodayIntent != null) {
      _didOpenInitialTodayIntent = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeOpenInitialTodayIntent();
      });
    }
    if (widget.openCompanionFlowOnLaunch !=
            oldWidget.openCompanionFlowOnLaunch &&
        widget.openCompanionFlowOnLaunch) {
      _didOpenInitialCompanionFlow = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeOpenInitialCompanionFlow();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _premiumUpsellTimer?.cancel();
    _feedbackPromptTimer?.cancel();
    PremiumService.activationSuccessRevision
        .removeListener(_handlePremiumActivationSuccess);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
    _maybeOpenInitialCompanionFlow();
    _scheduleTimedUpsellCheck();
    _scheduleFeedbackPromptCheck();
    _handlePremiumActivationSuccess();
  }

  @override
  void didPushNext() {
    _premiumUpsellTimer?.cancel();
    _feedbackPromptTimer?.cancel();
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

  void _maybeOpenInitialTodayIntent() {
    if (!mounted || _didOpenInitialTodayIntent) return;
    final intent = widget.initialTodayIntent;
    if (intent == null) return;
    _didOpenInitialTodayIntent = true;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TodayScreen(intent: intent)),
    );
  }

  void _maybeOpenInitialCompanionFlow() {
    if (!mounted || _didOpenInitialCompanionFlow) return;
    if (!widget.openCompanionFlowOnLaunch) return;
    if (_hasBlockingModalRoute()) return;
    _didOpenInitialCompanionFlow = true;
    _openCompanionFlow();
  }

  void _openCompanionFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompanionFlowScreen()),
    );
  }

  void _scheduleTimedUpsellCheck() {
    _premiumUpsellTimer?.cancel();
    _premiumUpsellTimer = Timer(
      PremiumUpsellService.minimumTimeOnHome,
      () => _tryShowPremiumUpsell(triggeredByInteraction: false),
    );
  }

  void _scheduleFeedbackPromptCheck({
    Duration delay = _feedbackPromptDelay,
  }) {
    _feedbackPromptTimer?.cancel();
    _feedbackPromptTimer = Timer(delay, () {
      _maybeShowFeedbackPrompt();
    });
  }

  void _handlePremiumActivationSuccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hasBlockingModalRoute()) return;
      final revision = PremiumService.activationSuccessRevision.value;
      if (!PremiumService.markActivationSuccessPresented(revision)) return;
      await _showPremiumSuccessSheet();
    });
  }

  Future<void> _showPremiumSuccessSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => PremiumSuccessSheet(
        onManageNotifications: () {
          Navigator.of(sheetContext).pop();
          _openSettingsModal();
        },
        onOpenNightGuidance: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TodayScreen(
                intent: TodayScreenIntent.beforeSleep,
              ),
            ),
          );
        },
        onViewProgress: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RamadanHubScreen()),
          );
        },
      ),
    );
  }

  bool _hasBlockingModalRoute() {
    final route = ModalRoute.of(context);
    return route == null || !route.isCurrent;
  }

  Future<void> _maybeShowFeedbackPrompt() async {
    if (!mounted || _isPresentingFeedbackPrompt || _isPresentingUpsell) return;
    if (widget.initialTodayIntent != null && !_didOpenInitialTodayIntent) {
      return;
    }
    if (widget.openCompanionFlowOnLaunch && !_didOpenInitialCompanionFlow) {
      return;
    }
    if (!FeedbackPromptService.canShowPrompt()) return;
    if (_hasBlockingModalRoute()) {
      _scheduleFeedbackPromptCheck(delay: const Duration(seconds: 6));
      return;
    }

    final navigator = Navigator.of(context);
    final sheetBackgroundColor = Theme.of(context).colorScheme.surface;
    _isPresentingFeedbackPrompt = true;
    await LocalPreferencesService.markFeedbackPromptShown();
    if (!mounted) {
      _isPresentingFeedbackPrompt = false;
      return;
    }

    final action = await showModalBottomSheet<_FeedbackPromptAction>(
      context: navigator.context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: sheetBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _FeedbackPromptSheet(
        onRate: () =>
            Navigator.of(sheetContext).pop(_FeedbackPromptAction.rate),
        onSendFeedback: () =>
            Navigator.of(sheetContext).pop(_FeedbackPromptAction.feedback),
        onLater: () =>
            Navigator.of(sheetContext).pop(_FeedbackPromptAction.later),
      ),
    );
    _isPresentingFeedbackPrompt = false;
    if (!mounted) return;

    switch (action) {
      case _FeedbackPromptAction.rate:
        final result = await FeedbackService.requestRating();
        if (!mounted) return;
        if (result == FeedbackLaunchResult.launched) {
          await LocalPreferencesService.markFeedbackPromptRated();
          return;
        }
        _showFeedbackPromptFailure(S.get('feedback_review_failed'));
        return;
      case _FeedbackPromptAction.feedback:
        final result = await FeedbackService.composeFeedbackEmail();
        if (!mounted) return;
        if (result == FeedbackLaunchResult.launched) {
          await LocalPreferencesService.markFeedbackPromptCompleted();
          return;
        }
        _showFeedbackPromptFailure(S.get('feedback_email_failed'));
        return;
      case _FeedbackPromptAction.later:
      case null:
        return;
    }
  }

  void _showFeedbackPromptFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _tryShowPremiumUpsell({
    required bool triggeredByInteraction,
  }) async {
    if (!mounted || _isPresentingUpsell) return;
    if (!triggeredByInteraction && widget.initialTodayIntent != null) return;
    if (!PremiumUpsellService.canShowUpsell(
      launchedFromNotification: widget.launchedFromNotification,
      hasActiveModalRoute: _hasBlockingModalRoute(),
    )) {
      return;
    }

    final navigator = Navigator.of(context);
    final sheetBackgroundColor = Theme.of(context).colorScheme.surface;
    _isPresentingUpsell = true;
    await PremiumUpsellService.markShown();
    if (!mounted) {
      _isPresentingUpsell = false;
      return;
    }
    final action = await showModalBottomSheet<_PremiumUpsellAction>(
      context: navigator.context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: sheetBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PremiumUpsellSheet(
        onViewPremium: () => Navigator.of(sheetContext).pop(
          _PremiumUpsellAction.viewPremium,
        ),
        onDismiss: () => Navigator.of(sheetContext).pop(
          _PremiumUpsellAction.dismiss,
        ),
      ),
    );
    _isPresentingUpsell = false;
    if (!mounted) return;

    if (action == _PremiumUpsellAction.viewPremium) {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const PremiumPage()),
      );
      return;
    }

    await PremiumUpsellService.markDismissed();
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
              AppCtaButton(
                label: S.get('continue'),
                fullWidth: true,
                onPressed: () async {
                  completed = true;
                  await UserProfileService.setDisplayName(controller.text);
                  await UserProfileService.markNamePromptShown();
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
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

  bool _shouldShowNightCompanionPrompt() {
    if (!LocalPreferencesService.nightCompanionReminderEnabled.value) {
      return false;
    }
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    if (_dismissedNightRitualPromptDateKey == todayKey) return false;
    final time = LocalPreferencesService.nightCompanionReminderTime.value;
    final scheduledAt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final differenceMinutes = now.difference(scheduledAt).inMinutes.abs();
    return differenceMinutes <= 45;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Image.asset(
                      'assets/images/mosque_bg_2.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
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
                        colorScheme.surface.withValues(alpha: 0),
                        colorScheme.surface.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                child: ValueListenableBuilder<bool>(
                  valueListenable: LocalPreferencesService.minimalModeEnabled,
                  builder: (context, minimalModeEnabled, _) {
                    return _buildHomeContent(
                      minimalModeEnabled: minimalModeEnabled,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent({required bool minimalModeEnabled}) {
    final List<Widget> sections = <Widget>[];
    sections.add(_buildGreeting());

    if (minimalModeEnabled) {
      sections.addAll(<Widget>[
        const SizedBox(height: 32),
        _buildHeroSection(),
        const SizedBox(height: 28),
        _buildDailyContentSection(),
        const SizedBox(height: 28),
        _buildExploreQuranEntry(context),
        const SizedBox(height: 28),
        _buildCompanionEntry(),
        const SizedBox(height: 8),
        _buildCompanionConnectionLine(),
        const SizedBox(height: 10),
        _buildGuidedHelperLink(),
        const SizedBox(height: 8),
      ]);
    } else {
      sections.addAll(<Widget>[
        const SizedBox(height: 24),
        _buildHeroSection(),
        const SizedBox(height: 20),
        _buildCoreActionsRow(),
        const SizedBox(height: 20),
        _buildSectionHeader(
          title: S.get('home_section_for_today'),
          icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 10),
        _buildDailyContentSection(),
        if (_shouldShowNightCompanionPrompt()) ...[
          const SizedBox(height: 18),
          _buildNightRitualPromptCard(),
        ],
        const SizedBox(height: 10),
        _buildTodayLink(),
        const SizedBox(height: 20),
        _buildSectionHeader(
          title: S.get('home_section_explore'),
          icon: Icons.explore_outlined,
        ),
        const SizedBox(height: 12),
        _buildExploreQuranEntry(context),
        const SizedBox(height: 14),
        _buildCompanionEntry(),
        const SizedBox(height: 8),
        _buildCompanionConnectionLine(),
        const SizedBox(height: 14),
        _buildAsmaEntry(),
        const SizedBox(height: 14),
        _buildExploreEntry(
          title: S.get('ramadan_hub_title'),
          showMosqueBackground: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RamadanHubScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _buildPremiumSection(),
        const BannerAdWidget(
          margin: EdgeInsets.only(top: 28, bottom: 8),
        ),
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildHeroSection() {
    return ValueListenableBuilder<PrayerLocation>(
      valueListenable: LocalPreferencesService.prayerLocation,
      builder: (context, location, _) {
        final countdown = _iftarCountdown(location);
        final showIftarCountdown = countdown != null;
        _ensureClockTicker(perSecond: showIftarCountdown);

        return _buildNextPrayerHero(
          countdown: countdown,
          showCountdown: showIftarCountdown,
        );
      },
    );
  }

  Widget _buildDailyContentSection() {
    return ValueListenableBuilder<int>(
      valueListenable: DailyContentService.revision,
      builder: (context, _, __) => _buildPrimaryDailyCard(),
    );
  }

  Widget _buildTodayLink() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TodayScreen()),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.turquoiseAccentStrong,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        S.get('home_see_more_for_today'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPremiumSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.isPremium,
      builder: (context, isPremium, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            _buildPremiumStatusRow(isPremium: isPremium),
          ],
        );
      },
    );
  }

  Widget _buildGreeting() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  color: colorScheme.onSurface.withValues(alpha: 0.96),
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
              color: colorScheme.onSurface.withValues(alpha: 0.7),
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
        Icon(
          icon,
          size: 16,
          color: AppColors.indigoAccent.withValues(alpha: 0.88),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.64),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCoreActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeShortcutCard(
                icon: Icons.schedule_rounded,
                label: S.get('adhan_times'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdhanTimesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeShortcutCard(
                icon: Icons.navigation_rounded,
                label: S.get('qibla'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QiblaScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeShortcutCard(
                icon: Icons.radio_button_checked_rounded,
                label: S.get('tasbih'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TasbihScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextPrayerHero({
    required String? countdown,
    required bool showCountdown,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.turquoiseAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.indigoAccent.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigoAccent.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.16,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 2.1, sigmaY: 2.1),
                    child: Image.asset(
                      'assets/images/mosque_bg.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
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
                        colorScheme.surface.withValues(alpha: 0.006),
                        colorScheme.surface.withValues(alpha: 0.035),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: S.get('home_section_now_upcoming'),
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: 14),
                  NextPrayerPill(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdhanTimesScreen(),
                        ),
                      );
                    },
                  ),
                  if (showCountdown && countdown != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.timelapse_rounded,
                          size: 18,
                          color: AppColors.emphasisAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            S.get('home_time_to_maghrib'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.82,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          countdown,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emphasisAccent,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      S.get('prayer_times'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatusRow({required bool isPremium}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumPage()),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.emphasisAccent.withValues(alpha: 0.14),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.emphasisAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 18,
                    color: AppColors.emphasisAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium
                            ? S.get('premium_active_card_title')
                            : S.get('premium_app_title'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPremium
                            ? S.get('premium_home_status_subtitle')
                            : S.get('premium_cta_context'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withValues(alpha: 0.68),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryDailyCard() {
    try {
      final date = DateTime.now();
      final contentType = DailyContentService.homeContentTypeForDate(date);
      final locale = Locale(LocalPreferencesService.language.value);

      switch (contentType) {
        case HomeDailyContentType.verse:
          if (QuranData.instance.ayahs.isEmpty) {
            return _buildHadithFallbackCard();
          }
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
              final hasReadableText = resolvedReadableText != null &&
                  resolvedReadableText.isNotEmpty;
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
    } catch (_) {
      return _buildHadithFallbackCard();
    }
  }

  Widget _buildHadithFallbackCard() {
    final hadith = DailyContentService.todayHadith;
    return _buildPrimaryCard(
      title: S.get('daily_hadith_title'),
      body: hadith?.text ?? S.get('daily_hadith_empty'),
      source: hadith?.source,
    );
  }

  Widget _buildQuranFramedCard({
    required Widget child,
    bool showMosqueBackground = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _PrimaryDailyCardStyle.fromTheme(
      colorScheme: colorScheme,
      isDark: isDark,
    );
    const borderRadius = BorderRadius.all(Radius.circular(22));
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: borderRadius,
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
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (showMosqueBackground) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.15,
                    child: Transform.scale(
                      scale: 1.12,
                      child: ImageFiltered(
                        imageFilter:
                            ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                        child: Image.asset(
                          'assets/images/mosque_bg_2.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
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
                          colorScheme.surface.withValues(alpha: 0.018),
                          colorScheme.surface.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              top: -34,
              right: -18,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      style.accentWash,
                      style.accentWash.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
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
          ],
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
                    color: AppColors.indigoAccent.withValues(alpha: 0.92),
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
              color: colorScheme.onSurface.withValues(alpha: 0.95),
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
                color: colorScheme.onSurface.withValues(alpha: 0.66),
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
      showMosqueBackground: true,
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
                    color: AppColors.indigoAccent.withValues(alpha: 0.92),
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
              color: colorScheme.onSurface.withValues(alpha: 0.66),
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
                    color: AppColors.indigoAccent.withValues(alpha: 0.92),
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
              color: colorScheme.onSurface.withValues(alpha: 0.88),
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
                color: colorScheme.onSurface.withValues(alpha: 0.66),
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
    return IconButton(
      onPressed: onTap,
      tooltip: S.get('today_card_more_actions'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: AppColors.indigoAccent.withValues(alpha: 0.82),
      ),
    );
  }

  Widget _buildShareButton(VoidCallback onShare) {
    return IconButton(
      onPressed: onShare,
      tooltip: S.get('ramadan_suggestions_share'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.ios_share_rounded,
        size: 18,
        color: AppColors.indigoAccent.withValues(alpha: 0.82),
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
        color: colorScheme.onSurface.withValues(alpha: 0.95),
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
      showMosqueBackground: true,
      onTap: () {
        if (progress != null) {
          final surahName = QuranData.instance.getSurahName(
            progress.surah,
            languageCode: Localizations.localeOf(context).languageCode,
          );
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => AyahReadingScreen(
                    surahNumber: progress.surah,
                    surahName: surahName,
                    readingContext: readingContext,
                  ),
                ),
              )
              .then((_) => _tryShowPremiumUpsell(triggeredByInteraction: true));
        } else {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (_) => const SurahListScreen()),
              )
              .then((_) => _tryShowPremiumUpsell(triggeredByInteraction: true));
        }
      },
    );
  }

  Widget _buildCompanionEntry() {
    return _buildExploreEntry(
      title: S.get('companion_flow_title'),
      subtitle: S.get('companion_flow_home_subtitle'),
      showMosqueBackground: true,
      onTap: _openCompanionFlow,
    );
  }

  Widget _buildAsmaEntry() {
    return _buildExploreEntry(
      title: S.get('asma_screen_title'),
      subtitle: S.get('asma_explore_subtitle'),
      showMosqueBackground: true,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AsmaulHusnaScreen(),
          ),
        );
      },
    );
  }

  Widget _buildGuidedHelperLink() {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const TodayScreen(intent: TodayScreenIntent.reminder),
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          S.get('home_guided_helper_cta'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanionConnectionLine() {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: LocalPreferencesService.companionFlowCompletedToday,
      builder: (context, completedToday, _) {
        if (!completedToday) return const SizedBox.shrink();
        return FutureBuilder<SpiritualProgressState>(
          future: SpiritualProgressService.loadState(),
          builder: (context, snapshot) {
            final reflectionDays =
                (snapshot.data?.reflectionStreakCount ?? 1).clamp(1, 999);
            final filledDots = reflectionDays.clamp(1, 5);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.get('spiritual_connection_status_today'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.58),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S
                        .get('spiritual_connection_continuity')
                        .replaceAll('{count}', '$reflectionDays'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final isFilled = index < filledDots;
                      return Padding(
                        padding: EdgeInsets.only(right: index == 4 ? 0 : 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onSurface.withValues(
                              alpha: isFilled ? 0.34 : 0.12,
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
      },
    );
  }

  Widget _buildNightRitualPromptCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.indigoAccent.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.get('night_ritual_prompt_title'),
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.94),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _dismissedNightRitualPromptDateKey =
                            '${now.year}-${now.month}-${now.day}';
                      });
                    },
                    child: Text(S.get('night_ritual_prompt_dismiss')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppCtaButton(
                    label: S.get('night_ritual_prompt_cta'),
                    fullWidth: true,
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _dismissedNightRitualPromptDateKey =
                            '${now.year}-${now.month}-${now.day}';
                      });
                      _openCompanionFlow();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreEntry({
    required String title,
    String? subtitle,
    bool showMosqueBackground = false,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.98),
            borderRadius: borderRadius,
            border: Border.all(
              color: AppColors.earthAccent.withValues(alpha: 0.16),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.earthAccent.withValues(alpha: 0.055),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              children: [
                if (showMosqueBackground) ...[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.15,
                        child: Transform.scale(
                          scale: 1.06,
                          child: ImageFiltered(
                            imageFilter:
                                ui.ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
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
                              colorScheme.surface.withValues(alpha: 0.035),
                              colorScheme.surface.withValues(alpha: 0.085),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Merriweather',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withValues(
                                  alpha: showMosqueBackground ? 0.97 : 0.94,
                                ),
                                height: 1.4,
                                shadows: showMosqueBackground
                                    ? const [
                                        Shadow(
                                          color: Color(0x24000000),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
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
                                  color: colorScheme.onSurface.withValues(
                                    alpha: showMosqueBackground ? 0.76 : 0.66,
                                  ),
                                  shadows: showMosqueBackground
                                      ? const [
                                          Shadow(
                                            color: Color(0x18000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.indigoAccent.withValues(
                          alpha: showMosqueBackground ? 0.74 : 0.58,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeShortcutCard extends StatelessWidget {
  const _HomeShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.earthAccent.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.earthAccent.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.indigoAccent.withValues(alpha: 0.82),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.84),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FeedbackPromptAction { rate, feedback, later }

class _FeedbackPromptSheet extends StatelessWidget {
  const _FeedbackPromptSheet({
    required this.onRate,
    required this.onSendFeedback,
    required this.onLater,
  });

  final VoidCallback onRate;
  final VoidCallback onSendFeedback;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('feedback_prompt_title'),
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.get('feedback_prompt_subtitle'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: mutedTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          AppCtaButton(
            label: S.get('feedback_prompt_positive'),
            fullWidth: true,
            onPressed: onRate,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSendFeedback,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.84),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                S.get('feedback_prompt_feedback'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: onLater,
              child: Text(
                S.get('feedback_prompt_later'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: mutedTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PremiumUpsellAction { viewPremium, dismiss }

class _PremiumUpsellSheet extends StatelessWidget {
  const _PremiumUpsellSheet({
    required this.onViewPremium,
    required this.onDismiss,
  });

  final VoidCallback onViewPremium;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.emphasisAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.emphasisAccent,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.get('premium_upsell_sheet_title'),
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.get('premium_upsell_sheet_subtitle'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: mutedTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _PremiumUpsellBullet(
            text: S.get('premium_upsell_benefit_remove_ads'),
          ),
          const SizedBox(height: 10),
          _PremiumUpsellBullet(
            text: S.get('premium_upsell_benefit_upcoming_features'),
          ),
          const SizedBox(height: 10),
          _PremiumUpsellBullet(
            text: S.get('premium_upsell_benefit_support'),
          ),
          const SizedBox(height: 24),
          AppCtaButton(
            label: S.get('premium_upsell_primary_cta'),
            fullWidth: true,
            onPressed: onViewPremium,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                S.get('premium_upsell_secondary_cta'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: mutedTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumUpsellBullet extends StatelessWidget {
  const _PremiumUpsellBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.emphasisAccent.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.78),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryDailyCardStyle {
  const _PrimaryDailyCardStyle({
    required this.background,
    required this.backgroundGradient,
    required this.accentWash,
    required this.borderColor,
    required this.innerGlow,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final Color background;
  final List<Color> backgroundGradient;
  final Color accentWash;
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
        accentWash: AppColors.indigoAccent.withValues(alpha: 0.08),
        borderColor: const Color(0xFF73695E).withValues(alpha: 0.26),
        innerGlow: const Color(0xFFD7C2A3).withValues(alpha: 0.08),
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shadowBlur: 18,
        shadowOffset: const Offset(0, 4),
      );
    }
    return _PrimaryDailyCardStyle(
      background: const Color(0xFFF9F5ED),
      backgroundGradient: const [
        Color(0xFFFEFBF5),
        Color(0xFFF6EFE4),
      ],
      accentWash: AppColors.turquoiseAccentStrong.withValues(alpha: 0.055),
      borderColor: AppColors.indigoAccent.withValues(alpha: 0.16),
      innerGlow: const Color(0xFFFFFCF6),
      shadowColor: const Color(0x248C7B63),
      shadowBlur: 28,
      shadowOffset: const Offset(0, 14),
    );
  }
}

enum _HomeAsmaCardMenuAction {
  share,
}

enum _PrayerType { fajr, dhuhr, asr, maghrib, isha, none }
