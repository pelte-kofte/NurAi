import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ShareCardType {
  ayah,
  hadith,
  quote,
  reminder,
}

class ShareCardPayload {
  const ShareCardPayload({
    required this.title,
    required this.content,
    required this.type,
    this.reference,
    this.arabicText,
    this.localeCode,
  });

  final String title;
  final String content;
  final ShareCardType type;
  final String? reference;
  final String? arabicText;
  final String? localeCode;
}

class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({
    super.key,
    required this.payload,
    required this.isDark,
  });

  final ShareCardPayload payload;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final palette = _ShareCardPalette.fromBrightness(isDark);
    final hasArabic = payload.arabicText?.trim().isNotEmpty ?? false;
    final hasReference = payload.reference?.trim().isNotEmpty ?? false;
    final contentFontSize = _contentFontSize(
      payload.content,
      hasArabic: hasArabic,
    );

    return Material(
      color: palette.background,
      child: SizedBox(
        width: 1080,
        height: 1350,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.background,
                ),
              ),
            ),
            Positioned(
              top: -130,
              right: -110,
              child: _AccentHalo(
                size: 360,
                color:
                    palette.turquoise.withValues(alpha: isDark ? 0.10 : 0.12),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -130,
              child: _AccentHalo(
                size: 420,
                color: palette.indigo.withValues(alpha: isDark ? 0.10 : 0.08),
              ),
            ),
            Positioned(
              top: 118,
              left: 82,
              right: 82,
              bottom: 88,
              child: Container(
                padding: const EdgeInsets.fromLTRB(66, 54, 66, 46),
                decoration: BoxDecoration(
                  color: palette.panel,
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForType(payload.type),
                          size: 26,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            payload.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: palette.label,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: 92,
                      height: 3,
                      decoration: BoxDecoration(
                        color: palette.clay.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 38),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasArabic) ...[
                            Text(
                              payload.arabicText!,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 58,
                                height: 1.55,
                                color: palette.primaryText,
                              ),
                            ),
                            const SizedBox(height: 34),
                          ],
                          Text(
                            payload.content,
                            textAlign: TextAlign.center,
                            maxLines: hasArabic ? 9 : 12,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: contentFontSize,
                              height: 1.58,
                              color: palette.primaryText,
                            ),
                          ),
                          if (hasReference) ...[
                            const SizedBox(height: 28),
                            Text(
                              payload.reference!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 23,
                                fontWeight: FontWeight.w500,
                                color: palette.secondaryText,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.border.withValues(alpha: 0),
                                  palette.border,
                                  palette.border.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Duaya',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: palette.branding,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _contentFontSize(String text, {required bool hasArabic}) {
    final length = text.trim().length;
    if (hasArabic) {
      if (length > 260) return 30;
      if (length > 180) return 32;
      return 34;
    }
    if (length > 420) return 28;
    if (length > 320) return 31;
    if (length > 220) return 34;
    return 38;
  }

  static IconData _iconForType(ShareCardType type) {
    switch (type) {
      case ShareCardType.ayah:
        return Icons.auto_stories_rounded;
      case ShareCardType.hadith:
        return Icons.menu_book_rounded;
      case ShareCardType.quote:
        return Icons.format_quote_rounded;
      case ShareCardType.reminder:
        return Icons.lightbulb_outline_rounded;
    }
  }
}

class _AccentHalo extends StatelessWidget {
  const _AccentHalo({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _ShareCardPalette {
  const _ShareCardPalette({
    required this.background,
    required this.panel,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.label,
    required this.branding,
    required this.accent,
    required this.turquoise,
    required this.indigo,
    required this.clay,
  });

  final Color background;
  final Color panel;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color label;
  final Color branding;
  final Color accent;
  final Color turquoise;
  final Color indigo;
  final Color clay;

  factory _ShareCardPalette.fromBrightness(bool isDark) {
    if (isDark) {
      return const _ShareCardPalette(
        background: Color(0xFF141A22),
        panel: Color(0xFF1A222C),
        border: Color(0xFF2E3946),
        primaryText: Color(0xFFF3EEE6),
        secondaryText: Color(0xFFC7C1B8),
        label: Color(0xFF9ECFCE),
        branding: Color(0xFFD9C2B3),
        accent: AppColors.turquoiseAccent,
        turquoise: AppColors.turquoiseAccent,
        indigo: AppColors.indigoAccent,
        clay: AppColors.earthAccent,
      );
    }
    return const _ShareCardPalette(
      background: Color(0xFFF7F4EE),
      panel: Color(0xFFFCF8F1),
      border: Color(0xFFE4DCD1),
      primaryText: Color(0xFF2E2A28),
      secondaryText: Color(0xFF756E68),
      label: Color(0xFF486F82),
      branding: Color(0xFFB57A5A),
      accent: AppColors.indigoAccent,
      turquoise: AppColors.turquoiseAccent,
      indigo: AppColors.indigoAccent,
      clay: AppColors.earthAccent,
    );
  }
}
