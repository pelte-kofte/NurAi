import 'package:flutter/material.dart';

class AppColors {
  // --- Background ---
  static const Color scaffoldBg = Color(0xFFFBF6F2);
  static const Color cardBg = Color(0xFFFDF9F6);
  static const Color cardBgMuted = Color(0xFFF9F4EF);
  static const Color cardBorder = Color(0xFFEDE6E1);

  // --- Accents ---
  static const Color turquoiseAccent = Color(0xFF7BAEAC); // Primary
  static const Color indigoAccent = Color(0xFF5E609E);    // Secondary
  static const Color earthAccent = Color(0xFFB57A5A);     // Muted earth

  // Aliases for use in ColorScheme
  static const Color primaryAccent = turquoiseAccent;
  static const Color secondaryAccent = indigoAccent;

  // --- Text ---
  static const Color textPrimary = Color(0xFF2B2725);
  static const Color textSecondary = Color(0xFF7A746F);
  static const Color textMuted = Color(0xFFA79F97);

  // --- Icons ---
  static const Color iconMuted = Color(0xFF8EA8A6);

  // --- Splash ---
  static const Color splashOverlayTop = Color(0x5C171411);
  static const Color splashOverlayBottom = Color(0x91302A23);
}

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.turquoiseAccent,
      onPrimary: Colors.white,
      secondary: AppColors.indigoAccent,
      onSecondary: Colors.white,
      tertiary: AppColors.earthAccent,
      onTertiary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: AppColors.cardBg,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.cardBgMuted,
      outline: AppColors.cardBorder,
      shadow: Color(0x162A2420),
      scrim: Colors.black,
      inverseSurface: Color(0xFF2B2725),
      onInverseSurface: Color(0xFFF7F2EC),
      inversePrimary: Color(0xFFADD4D2),
    );

    const textTheme = TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: AppColors.cardBg,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      cardColor: AppColors.cardBg,
      dividerColor: AppColors.cardBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    const darkScaffold = Color(0xFF141414);
    const darkCard = Color(0xFF1D1E20);
    const darkCardMuted = Color(0xFF242629);
    const darkTextPrimary = Color(0xFFF1ECE4);
    const darkTextSecondary = Color(0xFFC8C2BA);
    const darkOutline = Color(0xFF36393D);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.turquoiseAccent,
      onPrimary: Colors.white,
      secondary: AppColors.indigoAccent,
      onSecondary: Colors.white,
      tertiary: AppColors.earthAccent,
      onTertiary: Colors.white,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: darkCard,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkCardMuted,
      outline: darkOutline,
      shadow: Color(0x66000000),
      scrim: Colors.black,
      inverseSurface: Color(0xFFF3EEE7),
      onInverseSurface: Color(0xFF1B1B1B),
      inversePrimary: Color(0xFFADD4D2),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkScaffold,
      cardColor: darkCard,
      dividerColor: darkOutline,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkScaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontFamily: 'Merriweather',
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          color: darkTextSecondary,
        ),
      ),
    );
  }
}
