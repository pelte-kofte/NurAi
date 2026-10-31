import 'package:flutter/material.dart';

class AppColors {
  // --- Background ---
  static const Color scaffoldBg = Color(0xFFFBFAF5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBgMuted = Color(0xFFF5F1E8);
  static const Color cardBgSoft = Color(0xFFF7F4EC);
  static const Color cardBorder = Color(0xFFE7E1D6);

  // --- Accents ---
  static const Color turquoiseAccent = Color(0xFFC8D9DB); // Primary
  static const Color indigoAccent = Color(0xFF7D9194); // Secondary
  static const Color turquoiseAccentStrong = Color(0xFF6E878A); // Emphasis
  static const Color earthAccent = Color(0xFFB7A48A); // Muted warm accent
  static const Color ctaPrimaryStart = Color(0xFF7F9EA0);
  static const Color ctaPrimaryEnd = Color(0xFF6C858E);
  static const Color ctaPrimaryText = Color(0xFFFDFBF7);
  static const Color ctaSecondaryFill = Color(0xFFEAF0F0);
  static const Color ctaSecondaryBorder = Color(0xFFD4E0E1);
  static const Color ctaShadow = Color(0x245E7377);

  // Aliases for use in ColorScheme
  static const Color primaryAccent = turquoiseAccent;
  static const Color secondaryAccent = indigoAccent;
  static const Color emphasisAccent = turquoiseAccentStrong;

  // --- Text ---
  static const Color textPrimary = Color(0xFF2F2F2F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9A9A9A);

  // --- Icons ---
  static const Color iconMuted = Color(0xFF9FB2B4);

  // --- Splash ---
  static const Color splashOverlayTop = Color(0x5C171411);
  static const Color splashOverlayBottom = Color(0x91302A23);
}

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.turquoiseAccent,
      onPrimary: AppColors.textPrimary,
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
      shadow: Color(0x142F2F2F),
      scrim: Colors.black,
      inverseSurface: Color(0xFF2F2F2F),
      onInverseSurface: Color(0xFFF9F6F0),
      inversePrimary: Color(0xFFD7E6E7),
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
      canvasColor: AppColors.cardBg,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.textMuted,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardBg,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctaPrimaryEnd,
          foregroundColor: AppColors.ctaPrimaryText,
          elevation: 0,
          shadowColor: AppColors.ctaShadow,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.indigoAccent,
          side: const BorderSide(color: AppColors.ctaSecondaryBorder),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.indigoAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardBg,
        selectedColor: AppColors.emphasisAccent.withValues(alpha: 0.18),
        disabledColor: AppColors.cardBgSoft,
        secondarySelectedColor:
            AppColors.emphasisAccent.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.emphasisAccent,
        ),
        side: const BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
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
