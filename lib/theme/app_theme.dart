import 'package:flutter/material.dart';

class AppColors {
  static const Color scaffoldBg = Color(0xFFF6F1EA);
  static const Color cardBg = Color(0xFFFEFAF6);
  static const Color cardBgMuted = Color(0xFFF9F4EE);
  static const Color cardBorder = Color(0xFFE4DDD4);

  static const Color primaryAccent = Color(0xFF5FA8A4); // Turquoise
  static const Color secondaryAccent = Color(0xFF5E609E); // Indigo

  static const Color textPrimary = Color(0xFF2F2A26);
  static const Color textSecondary = Color(0xFF736B64);
  static const Color textMuted = Color(0xFFA79F97);
  static const Color iconMuted = Color(0xFF8EA8A6);

  static const Color splashOverlayTop = Color(0x5C171411);
  static const Color splashOverlayBottom = Color(0x91302A23);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.light,
    );

    final textTheme = base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: AppColors.cardBg,
        height: 1.2,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryAccent,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryAccent,
      onSecondary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: AppColors.cardBg,
      onSurface: AppColors.textPrimary,
      tertiary: AppColors.iconMuted,
      onTertiary: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.cardBgMuted,
      outline: AppColors.cardBorder,
      shadow: Color(0x162A2420),
      scrim: Colors.black,
      inverseSurface: Color(0xFF2F2A26),
      onInverseSurface: Color(0xFFF7F2EC),
      inversePrimary: Color(0xFF92CCC8),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      cardColor: AppColors.cardBg,
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
      primary: AppColors.primaryAccent,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryAccent,
      onSecondary: Colors.white,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: darkCard,
      onSurface: darkTextPrimary,
      tertiary: AppColors.iconMuted,
      onTertiary: darkTextPrimary,
      surfaceContainerHighest: darkCardMuted,
      outline: darkOutline,
      shadow: Color(0x66000000),
      scrim: Colors.black,
      inverseSurface: Color(0xFFF3EEE7),
      onInverseSurface: Color(0xFF1B1B1B),
      inversePrimary: Color(0xFF3A8E89),
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
