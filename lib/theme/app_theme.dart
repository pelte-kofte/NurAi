import 'package:flutter/material.dart';

class AppColors {
  // --- Background ---
  static const Color scaffoldBg = Color(0xFFF7F4EE);
  static const Color cardBg = Color(0xFFFFFDF9);
  static const Color cardBgMuted = Color(0xFFF0ECE4);
  static const Color cardBgSoft = Color(0xFFF4F0E8);
  static const Color cardBorder = Color(0xFFE1D9CE);

  // --- Accents ---
  static const Color turquoiseAccent = Color(0xFF355E52); // Primary
  static const Color indigoAccent = Color(0xFF5D756D); // Secondary
  static const Color turquoiseAccentStrong = Color(0xFF294C42); // Emphasis
  static const Color earthAccent = Color(0xFFA17D58); // Muted warm accent
  static const Color ctaPrimaryStart = Color(0xFF355E52);
  static const Color ctaPrimaryEnd = Color(0xFF355E52);
  static const Color ctaPrimaryText = Color(0xFFFDFBF7);
  static const Color ctaSecondaryFill = Color(0xFFE9EFEC);
  static const Color ctaSecondaryBorder = Color(0xFFCFDCD6);
  static const Color ctaShadow = Colors.transparent;

  // Aliases for use in ColorScheme
  static const Color primaryAccent = turquoiseAccent;
  static const Color secondaryAccent = indigoAccent;
  static const Color emphasisAccent = turquoiseAccentStrong;

  // --- Text ---
  static const Color textPrimary = Color(0xFF252A27);
  static const Color textSecondary = Color(0xFF5E655F);
  static const Color textMuted = Color(0xFF858B86);

  // --- Icons ---
  static const Color iconMuted = Color(0xFF71857D);

  // --- Splash ---
  static const Color splashOverlayTop = Color(0x5C171411);
  static const Color splashOverlayBottom = Color(0x91302A23);
}

class AppRadii {
  AppRadii._();

  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
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
      shadow: Color(0x142F2F2F),
      scrim: Colors.black,
      inverseSurface: Color(0xFF2F2F2F),
      onInverseSurface: Color(0xFFF9F6F0),
      inversePrimary: Color(0xFFD7E6E7),
    );

    const textTheme = TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.24,
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
        fontSize: 15,
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
      cardTheme: const CardThemeData(
        color: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.medium)),
          side: BorderSide(color: AppColors.cardBorder),
        ),
      ),
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
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
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
            borderRadius: BorderRadius.circular(AppRadii.medium),
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
            borderRadius: BorderRadius.circular(AppRadii.medium),
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
