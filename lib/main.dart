import 'package:flutter/material.dart';
import 'data/quran_data.dart';
import 'data/reading_progress_service.dart';
import 'data/bookmark_service.dart';
import 'data/collective_reading_service.dart';
import 'data/adhan_notification_service.dart';
import 'data/local_preferences_service.dart';
import 'data/notes_service.dart';
import 'features/home/home_screen.dart';

/// Global route observer for lifecycle-aware screens.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
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
        return MaterialApp(
          title: 'NurAI',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],
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
  }
}

/// Loads Quran data before showing the main app.
/// Shows a calm loading state while data loads.
class _AppLoader extends StatelessWidget {
  const _AppLoader();

  Future<void> _loadAppData() async {
    await Future.wait([
      QuranData.instance.load(),
      ReadingProgressService.init(),
      BookmarkService.init(),
      CollectiveReadingService.init(),
      NotesService.init(),
      LocalPreferencesService.init(),
      AdhanNotificationService.init(),
    ]);
    // Re-schedule prayer notifications on every app launch (rolling 7-day window).
    if (LocalPreferencesService.adhanEnabled.value) {
      AdhanNotificationService.schedulePrayerNotifications();
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
    return const Scaffold(
      backgroundColor: Color(0xFFFBF6F2),
      body: Center(
        child: Text(
          'Bismillah',
          style: TextStyle(
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
    return const Scaffold(
      backgroundColor: Color(0xFFFBF6F2),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Veriler yüklenemedi.\nLütfen uygulamayı yeniden başlatın.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
