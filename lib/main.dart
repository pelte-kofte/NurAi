import 'package:flutter/material.dart';
import 'data/quran_data.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const NurAIApp());
}

/// Root widget for NurAI app.
/// Loads Quran data once at startup, then displays HomeScreen.
class NurAIApp extends StatelessWidget {
  const NurAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NurAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFFBF6F2),
      ),
      home: const _AppLoader(),
    );
  }
}

/// Loads Quran data before showing the main app.
/// Shows a calm loading state while data loads.
class _AppLoader extends StatelessWidget {
  const _AppLoader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: QuranData.instance.load(),
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
