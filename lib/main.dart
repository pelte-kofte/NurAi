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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        LocalPreferencesService.adhanEnabled.value) {
      AdhanNotificationService.rescheduleForToday();
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadAppData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (snapshot.hasError) {
          return const _ErrorScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

/// Minimal loading screen with warm background.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: Center(
        child: Text(
          S.get('loading'),
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 28,
            color: Color(0xFF7A746F),
          ),
        ),
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
