import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/ads/ad_service.dart';
import 'core/config/seasonal_config.dart';
import 'data/quran_data.dart';
import 'data/reading_progress_service.dart';
import 'data/bookmark_service.dart';
import 'data/collective_reading_service.dart';
import 'data/adhan_notification_service.dart';
import 'data/local_preferences_service.dart';
import 'data/local_data_recovery.dart';
import 'data/user_profile_service.dart';
import 'data/notes_service.dart';
import 'data/daily_content_service.dart';
import 'data/iftar_live_activity_service.dart';
import 'data/prayer_location_service.dart';
import 'data/premium_service.dart';
import 'data/ayah_notes_service.dart';
import 'data/widget_payload_service.dart';
import 'l10n/app_strings.dart';
import 'features/home/home_screen.dart';
import 'features/home/today_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_cta_button.dart';

/// Global route observer for lifecycle-aware screens.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void _startupLog(String message) {
  assert(() {
    debugPrint('[Startup] $message');
    return true;
  }());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _startupLog('main started');
  await _runRecoverableStartupStep(
    'LocalPreferencesService.init',
    LocalPreferencesService.init,
  );
  await _runRecoverableStartupStep(
    'LocalPreferencesService.incrementAppOpenCount',
    LocalPreferencesService.incrementAppOpenCount,
  );
  _startupLog('local preferences initialized');
  runApp(const NurAIApp());
  _startupLog('runApp called');
}

Future<void> _runRecoverableStartupStep(
  String label,
  Future<Object?> Function() action,
) async {
  try {
    await action();
  } catch (error, stackTrace) {
    LocalDataRecovery.log(label, error, stackTrace);
    _startupLog('$label recovered after local-data failure');
  }
}

/// Root widget for NurAI app.
/// Loads Quran data once at startup, then displays HomeScreen.
class NurAIApp extends StatelessWidget {
  const NurAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: LocalPreferencesService.themeMode,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: LocalPreferencesService.language,
          builder: (context, langCode, _) {
            return MaterialApp(
              title: 'Duada',
              debugShowCheckedModeBanner: false,
              navigatorObservers: [routeObserver],
              locale: Locale(langCode),
              builder: (context, child) {
                final isArabic = langCode == 'ar';
                return Directionality(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              supportedLocales: const [
                Locale('tr'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: currentMode,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              home: const _AppLoader(),
            );
          },
        );
      },
    );
  }
}

/// Loads Quran data before showing the main app.
/// Shows a calm loading state while data loads.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> with WidgetsBindingObserver {
  late final Future<void> _appLoadFuture;
  bool _isAppReady = false;
  bool _isStarting = false;
  bool _showHome = false;
  bool _showHomeWhenReady = false;
  bool _launchedFromNotification = false;
  TodayScreenIntent? _pendingTodayIntent;
  bool _pendingOpenCompanionFlow = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdhanNotificationService.lastNotificationTapPayload.addListener(
      _handleNotificationTapLaunch,
    );
    _handleNotificationTapLaunch();
    _appLoadFuture = _loadAppData();
    _appLoadFuture.then((_) {
      if (!mounted) return;
      setState(() {
        _isAppReady = true;
        if (_showHomeWhenReady) {
          _showHome = true;
        }
      });
    }).catchError((Object error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    });
  }

  @override
  void dispose() {
    AdhanNotificationService.lastNotificationTapPayload.removeListener(
      _handleNotificationTapLaunch,
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleNotificationTapLaunch() {
    final payload = AdhanNotificationService.lastNotificationTapPayload.value;
    final type = AdhanNotificationService.notificationPayloadType(payload);
    final todayIntent = switch (type) {
      AdhanNotificationService.morningReminderType =>
        TodayScreenIntent.morningReflection,
      AdhanNotificationService.eveningReminderType =>
        TodayScreenIntent.eveningReflection,
      AdhanNotificationService.spiritualMorningType =>
        TodayScreenIntent.morningReflection,
      AdhanNotificationService.spiritualMiddayType =>
        TodayScreenIntent.reminder,
      AdhanNotificationService.spiritualNightType =>
        TodayScreenIntent.beforeSleep,
      _ => null,
    };
    final shouldOpenCompanion =
        type == AdhanNotificationService.nightCompanionReminderType;
    if (todayIntent != null) {
      if (!mounted) return;
      setState(() {
        _launchedFromNotification = true;
        _pendingTodayIntent = todayIntent;
        if (_isAppReady) {
          _showHome = true;
        } else {
          _showHomeWhenReady = true;
        }
      });
      return;
    }
    if (shouldOpenCompanion) {
      if (!mounted) return;
      setState(() {
        _launchedFromNotification = true;
        _pendingOpenCompanionFlow = true;
        if (_isAppReady) {
          _showHome = true;
        } else {
          _showHomeWhenReady = true;
        }
      });
      return;
    }
    if (!SeasonalConfig.isRamadanSeason) {
      return;
    }
    if (type != AdhanNotificationService.iftarWarmupStartLiveActivityType &&
        type != 'iftar_live_activity_warmup' &&
        type != 'iftar_alarm_fired') {
      return;
    }
    if (!mounted) return;
    setState(() {
      _launchedFromNotification = true;
      if (_isAppReady) {
        _showHome = true;
      } else {
        _showHomeWhenReady = true;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isAppReady &&
        LocalPreferencesService.adhanEnabled.value) {
      AdhanNotificationService.rescheduleForToday();
    }
    if (state == AppLifecycleState.resumed && _isAppReady) {
      AdhanNotificationService.syncSpiritualNotifications();
    }
    if (SeasonalConfig.isRamadanSeason &&
        state == AppLifecycleState.resumed &&
        _isAppReady) {
      IftarLiveActivityService.scheduleIftarNotifications();
      IftarLiveActivityService.maybeStartOrUpdate();
    }
    if (state == AppLifecycleState.resumed && _isAppReady) {
      unawaited(LocalPreferencesService.refreshCompanionFlowCompletedToday());
      WidgetPayloadService.writeNextPrayerPayload();
    }
  }

  Future<void> _loadAppData() async {
    _startupLog('app loader start');
    await Future.wait([
      QuranData.instance.load(),
      _runRecoverableStartupStep(
        'ReadingProgressService.init',
        ReadingProgressService.init,
      ),
      _runRecoverableStartupStep('BookmarkService.init', BookmarkService.init),
      _runRecoverableStartupStep(
        'CollectiveReadingService.init',
        CollectiveReadingService.init,
      ),
      _runRecoverableStartupStep('NotesService.init', NotesService.init),
      DailyContentService.init(),
      _runRecoverableStartupStep(
        'AyahNotesService.init',
        AyahNotesService.init,
      ),
      _runRecoverableStartupStep(
        'LocalPreferencesService.init',
        LocalPreferencesService.init,
      ),
      _runRecoverableStartupStep('AdService.initialize', AdService.initialize),
      _runRecoverableStartupStep('PremiumService.init', PremiumService.init),
      _runRecoverableStartupStep(
        'UserProfileService.init',
        UserProfileService.init,
      ),
      _runRecoverableStartupStep(
        'AdhanNotificationService.init',
        AdhanNotificationService.init,
      ),
      _runRecoverableStartupStep(
        'IftarLiveActivityService.init',
        IftarLiveActivityService.init,
      ),
    ]);
    _startupLog('core services initialized');
    await _runRecoverableStartupStep(
      'AdhanNotificationService.syncSpiritualNotifications',
      AdhanNotificationService.syncSpiritualNotifications,
    );
    await _runRecoverableStartupStep(
      'AdhanNotificationService.cancelNightCompanionReminder',
      AdhanNotificationService.cancelNightCompanionReminder,
    );
    await _runRecoverableStartupStep(
      'AdhanNotificationService.syncReadingReminder',
      AdhanNotificationService.syncReadingReminder,
    );
    await _runRecoverableStartupStep(
      'PrayerLocationService.hydrateCurrentLocationIfPermitted',
      PrayerLocationService.hydrateCurrentLocationIfPermitted,
    );
    _startupLog('prayer location hydration completed');
    // Re-schedule prayer notifications on every app launch.
    if (LocalPreferencesService.adhanEnabled.value) {
      await _runRecoverableStartupStep(
        'AdhanNotificationService.rescheduleForToday',
        AdhanNotificationService.rescheduleForToday,
      );
    }
    if (SeasonalConfig.isRamadanSeason) {
      await _runRecoverableStartupStep(
        'IftarLiveActivityService.scheduleIftarNotifications',
        IftarLiveActivityService.scheduleIftarNotifications,
      );
      await _runRecoverableStartupStep(
        'IftarLiveActivityService.maybeStartOrUpdate',
        IftarLiveActivityService.maybeStartOrUpdate,
      );
    }
    await _runRecoverableStartupStep(
      'WidgetPayloadService.writeNextPrayerPayload',
      WidgetPayloadService.writeNextPrayerPayload,
    );
    _startupLog('app loader completed');
  }

  Future<void> _handleStartTap() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    try {
      await _appLoadFuture;
      if (!mounted) return;
      setState(() => _showHome = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return const _ErrorScreen();
    }
    if (_showHome) {
      return HomeScreen(
        initialTodayIntent: _pendingTodayIntent,
        openCompanionFlowOnLaunch: _pendingOpenCompanionFlow,
        launchedFromNotification: _launchedFromNotification,
      );
    }
    return _FirstScreen(
      isStarting: _isStarting,
      onTapStart: _handleStartTap,
    );
  }
}

class _FirstScreen extends StatelessWidget {
  const _FirstScreen({
    required this.isStarting,
    required this.onTapStart,
  });

  final bool isStarting;
  final VoidCallback onTapStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash/splash.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.splashOverlayTop,
                  AppColors.splashOverlayBottom,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, 0.2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          S.get('splash_headline'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          S.get('splash_subtitle'),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.cardBg,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            shadows: const [
                              Shadow(
                                color: Color(0x6E000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AppCtaButton(
                      label: S.get('continue'),
                      fullWidth: true,
                      onPressed: isStarting ? null : onTapStart,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple error screen if data fails to load.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            S.get('load_error'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
