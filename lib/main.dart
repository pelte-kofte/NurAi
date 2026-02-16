import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/quran_data.dart';
import 'data/reading_progress_service.dart';
import 'data/bookmark_service.dart';
import 'data/collective_reading_service.dart';
import 'data/adhan_notification_service.dart';
import 'data/local_preferences_service.dart';
import 'data/user_profile_service.dart';
import 'data/notes_service.dart';
import 'data/daily_content_service.dart';
import 'data/prayer_location_service.dart';
import 'data/premium_service.dart';
import 'data/ayah_notes_service.dart';
import 'data/widget_payload_service.dart';
import 'l10n/app_strings.dart';
import 'features/home/home_screen.dart';

/// Global route observer for lifecycle-aware screens.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalPreferencesService.init();
  runApp(const NurAIApp());
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
              title: 'NurAI',
              debugShowCheckedModeBanner: false,
              navigatorObservers: [routeObserver],
              locale: Locale(langCode),
              builder: (context, child) {
                final isArabic = langCode == 'ar';
                return Directionality(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              supportedLocales: const [
                Locale('tr'),
                Locale('en'),
                Locale('ar'),
                Locale('de'),
                Locale('fr'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: currentMode,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Inter',
                scaffoldBackgroundColor: const Color(0xFFFBF6F2),
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Inter',
                scaffoldBackgroundColor: const Color(0xFF1C1A19),
                brightness: Brightness.dark,
              ),
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
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLoadFuture = _loadAppData();
    _appLoadFuture.then((_) {
      if (!mounted) return;
      setState(() => _isAppReady = true);
    }).catchError((Object error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isAppReady &&
        LocalPreferencesService.adhanEnabled.value) {
      AdhanNotificationService.rescheduleForToday();
    }
    if (state == AppLifecycleState.resumed && _isAppReady) {
      WidgetPayloadService.writeNextPrayerPayload();
    }
  }

  Future<void> _loadAppData() async {
    await Future.wait([
      QuranData.instance.load(),
      ReadingProgressService.init(),
      BookmarkService.init(),
      CollectiveReadingService.init(),
      NotesService.init(),
      DailyContentService.init(),
      AyahNotesService.init(),
      LocalPreferencesService.init(),
      PremiumService.init(),
      UserProfileService.init(),
      AdhanNotificationService.init(),
    ]);
    await PrayerLocationService.hydrateCurrentLocationIfPermitted();
    // Re-schedule prayer notifications on every app launch.
    if (LocalPreferencesService.adhanEnabled.value) {
      AdhanNotificationService.rescheduleForToday();
    }
    await WidgetPayloadService.writeNextPrayerPayload();
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
      return const HomeScreen();
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isStarting ? null : onTapStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB57A5A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Tap to start',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
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
      backgroundColor: const Color(0xFFFBF6F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            S.get('load_error'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF7A746F),
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
