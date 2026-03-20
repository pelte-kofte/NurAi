import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../services/share_card_service.dart';
import '../theme/app_theme.dart';

class ShareCardWidget extends StatelessWidget {
  static const double _canvasWidth = 1080;
  static const double _canvasHeight = 1350;
  static const double _cardWidth = 964;
  static const double _cardHeight = 1180;
  static const double _textWidth = 756;
  static const double _referenceWidth = 700;

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
    assert(() {
      _ShareCardFitter.debugVerifyRepresentativeCases(palette);
      return true;
    }());

    return Material(
      color: palette.background,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
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
              top: -140,
              right: -100,
              child: _AccentHalo(
                size: 380,
                color:
                    palette.turquoise.withValues(alpha: isDark ? 0.10 : 0.12),
              ),
            ),
            Positioned(
              bottom: -170,
              left: -120,
              child: _AccentHalo(
                size: 400,
                color: palette.indigo.withValues(alpha: isDark ? 0.10 : 0.08),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: _cardWidth,
                  height: _cardHeight,
                  padding: const EdgeInsets.fromLTRB(72, 58, 72, 40),
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(44),
                    border: Border.all(
                      color: palette.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.22 : 0.07),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: palette.accentSoft,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: palette.border,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _iconForType(payload.type),
                              size: 28,
                              color: palette.accent,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              payload.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 33,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                                letterSpacing: 0.1,
                                color: palette.label,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.border.withValues(alpha: 0),
                              palette.clay.withValues(alpha: 0.72),
                              palette.border.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Expanded(
                        child: SizedBox(
                          width: _textWidth,
                          child: _ShareCardBody(
                            payload: payload,
                            palette: palette,
                            textWidth: _textWidth,
                            referenceWidth: _referenceWidth,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
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
                      const SizedBox(height: 18),
                      Text(
                        'Duada',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: palette.branding,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duada',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: palette.secondaryText.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      case ShareCardType.asma:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _ShareCardBody extends StatelessWidget {
  const _ShareCardBody({
    required this.payload,
    required this.palette,
    required this.textWidth,
    required this.referenceWidth,
  });

  final ShareCardPayload payload;
  final _ShareCardPalette palette;
  final double textWidth;
  final double referenceWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _ShareCardFitter.fit(
          payload: payload,
          palette: palette,
          textWidth: textWidth,
          referenceWidth: referenceWidth,
          availableHeight: constraints.maxHeight,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (layout.showArabic) ...[
              Text(
                payload.arabicText!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: layout.arabicMaxLines,
                overflow: layout.arabicTruncated
                    ? TextOverflow.ellipsis
                    : TextOverflow.visible,
                style: layout.arabicStyle,
              ),
              SizedBox(height: layout.arabicGap),
            ],
            Text(
              payload.content,
              textAlign: TextAlign.center,
              maxLines: layout.contentMaxLines,
              overflow: layout.contentTruncated
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              softWrap: true,
              style: layout.contentStyle,
            ),
            if (layout.showReference) ...[
              SizedBox(height: layout.referenceGap),
              SizedBox(
                width: referenceWidth,
                child: Text(
                  payload.reference!,
                  textAlign: TextAlign.center,
                  maxLines: layout.referenceMaxLines,
                  overflow: layout.referenceTruncated
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                  style: layout.referenceStyle,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShareCardFitter {
  static const List<_ShareCardSampleCase> _debugCases = [
    _ShareCardSampleCase(
      label: 'very_short_reminder',
      payload: ShareCardPayload(
        title: 'Daily Reminder',
        content: 'Begin gently. Return your heart to Allah.',
        type: ShareCardType.reminder,
      ),
    ),
    _ShareCardSampleCase(
      label: 'medium_quote',
      payload: ShareCardPayload(
        title: 'Daily Quote',
        content:
            'A calm heart is not an empty heart; it is a heart that knows where to turn when life becomes heavy.',
        type: ShareCardType.quote,
      ),
    ),
    _ShareCardSampleCase(
      label: 'long_hadith',
      payload: ShareCardPayload(
        title: 'Daily Hadith',
        content:
            'The Messenger of Allah said that deeds are judged by intentions, and every person will have only what they intended. So whoever migrates for Allah and His Messenger, the migration is for Allah and His Messenger, and whoever migrates for worldly gain or to marry a woman, the migration is for that for which he migrated.',
        reference: 'Bukhari & Muslim',
        type: ShareCardType.hadith,
      ),
    ),
    _ShareCardSampleCase(
      label: 'long_ayah_translation',
      payload: ShareCardPayload(
        title: 'Daily Ayah',
        content:
            'Allah does not burden a soul beyond what it can bear. It will have the consequence of what good it has gained, and it will bear the consequence of what evil it has earned. Our Lord, do not impose blame upon us if we forget or make a mistake.',
        reference: 'Al-Baqarah 2:286',
        type: ShareCardType.ayah,
      ),
    ),
    _ShareCardSampleCase(
      label: 'arabic_translation_reference',
      payload: ShareCardPayload(
        title: 'Daily Ayah',
        arabicText: 'لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
        content: 'Allah does not burden a soul beyond what it can bear.',
        reference: 'Al-Baqarah 2:286',
        type: ShareCardType.ayah,
      ),
    ),
    _ShareCardSampleCase(
      label: 'asma_card',
      payload: ShareCardPayload(
        title: 'Asmaul Husna',
        arabicText: 'ٱلرَّحْمَٰنُ',
        content: 'Ar-Rahman\nThe Most Compassionate',
        type: ShareCardType.asma,
      ),
    ),
  ];

  static void debugVerifyRepresentativeCases(_ShareCardPalette palette) {
    for (final sample in _debugCases) {
      fit(
        payload: sample.payload,
        palette: palette,
        textWidth: ShareCardWidget._textWidth,
        referenceWidth: ShareCardWidget._referenceWidth,
        availableHeight: 760,
      );
    }
  }

  static _ShareCardLayout fit({
    required ShareCardPayload payload,
    required _ShareCardPalette palette,
    required double textWidth,
    required double referenceWidth,
    required double availableHeight,
  }) {
    final spec = _ShareCardFitSpec.forPayload(payload);
    final textDirection = _textDirectionForLocale(payload.localeCode);

    for (var step = 0; step <= spec.scaleSteps; step++) {
      final t = step / spec.scaleSteps;
      final scale = lerpDouble(1, spec.minScale, t)!;
      final candidate = _buildCandidate(
        payload: payload,
        palette: palette,
        spec: spec,
        textWidth: textWidth,
        referenceWidth: referenceWidth,
        availableHeight: availableHeight,
        textDirection: textDirection,
        scale: scale,
        useEllipsisFallback: false,
      );
      if (candidate.totalHeight <= availableHeight) return candidate;
    }

    return _buildCandidate(
      payload: payload,
      palette: palette,
      spec: spec,
      textWidth: textWidth,
      referenceWidth: referenceWidth,
      availableHeight: availableHeight,
      textDirection: textDirection,
      scale: spec.minScale,
      useEllipsisFallback: true,
    );
  }

  static _ShareCardLayout _buildCandidate({
    required ShareCardPayload payload,
    required _ShareCardPalette palette,
    required _ShareCardFitSpec spec,
    required double textWidth,
    required double referenceWidth,
    required double availableHeight,
    required TextDirection textDirection,
    required double scale,
    required bool useEllipsisFallback,
  }) {
    final hasArabic = payload.arabicText?.trim().isNotEmpty ?? false;
    final hasReference = payload.reference?.trim().isNotEmpty ?? false;

    final arabicStyle = TextStyle(
      fontFamily: 'Amiri',
      fontSize:
          lerpDouble(spec.arabicFontSize, spec.minArabicFontSize, 1 - scale)!,
      height: lerpDouble(
          spec.arabicLineHeight, spec.minArabicLineHeight, 1 - scale)!,
      color: palette.primaryText,
    );
    final contentStyle = TextStyle(
      fontFamily: 'Merriweather',
      fontSize:
          lerpDouble(spec.contentFontSize, spec.minContentFontSize, 1 - scale)!,
      height: lerpDouble(
          spec.contentLineHeight, spec.minContentLineHeight, 1 - scale)!,
      color: palette.primaryText,
    );
    final referenceStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: lerpDouble(
          spec.referenceFontSize, spec.minReferenceFontSize, 1 - scale)!,
      fontWeight: FontWeight.w500,
      height: lerpDouble(
          spec.referenceLineHeight, spec.minReferenceLineHeight, 1 - scale)!,
      letterSpacing: 0.2,
      color: palette.secondaryText,
    );

    final arabicGap = hasArabic
        ? lerpDouble(spec.arabicGap, spec.minArabicGap, 1 - scale)!
        : 0.0;
    final referenceGap = hasReference
        ? lerpDouble(spec.referenceGap, spec.minReferenceGap, 1 - scale)!
        : 0.0;

    final referenceMeasure = hasReference
        ? _measureText(
            text: payload.reference!,
            style: referenceStyle,
            width: referenceWidth,
            textDirection: TextDirection.ltr,
            maxLines: useEllipsisFallback ? spec.referenceMaxLines : null,
            ellipsis: useEllipsisFallback,
          )
        : _MeasuredText.empty;

    var reservedHeight = referenceMeasure.height + referenceGap;

    var arabicMeasure = hasArabic
        ? _measureText(
            text: payload.arabicText!,
            style: arabicStyle,
            width: textWidth,
            textDirection: TextDirection.rtl,
            maxLines: useEllipsisFallback ? spec.maxArabicLines : null,
            ellipsis: useEllipsisFallback,
          )
        : _MeasuredText.empty;

    if (hasArabic) reservedHeight += arabicMeasure.height + arabicGap;

    var contentAvailable =
        (availableHeight - reservedHeight).clamp(0.0, availableHeight);

    var contentMeasure = _measureContent(
      payload: payload,
      spec: spec,
      style: contentStyle,
      width: textWidth,
      textDirection: textDirection,
      availableHeight: contentAvailable,
      useEllipsisFallback: useEllipsisFallback,
    );

    var totalHeight = reservedHeight + contentMeasure.height;

    if (useEllipsisFallback && hasArabic && totalHeight > availableHeight) {
      final overflow = totalHeight - availableHeight;
      final arabicLineHeight = arabicStyle.fontSize! * arabicStyle.height!;
      final reducibleLines =
          (arabicMeasure.lineCount - spec.minArabicLinesWhenShared)
              .clamp(0, spec.maxArabicLines);
      if (reducibleLines > 0 && arabicLineHeight > 0) {
        final linesToTrim =
            (overflow / arabicLineHeight).ceil().clamp(0, reducibleLines);
        final targetArabicLines = (arabicMeasure.lineCount - linesToTrim)
            .clamp(spec.minArabicLinesWhenShared, spec.maxArabicLines);
        arabicMeasure = _measureText(
          text: payload.arabicText!,
          style: arabicStyle,
          width: textWidth,
          textDirection: TextDirection.rtl,
          maxLines: targetArabicLines,
          ellipsis: true,
        );
        reservedHeight = referenceMeasure.height +
            referenceGap +
            arabicMeasure.height +
            arabicGap;
        contentAvailable =
            (availableHeight - reservedHeight).clamp(0.0, availableHeight);
        contentMeasure = _measureContent(
          payload: payload,
          spec: spec,
          style: contentStyle,
          width: textWidth,
          textDirection: textDirection,
          availableHeight: contentAvailable,
          useEllipsisFallback: true,
        );
        totalHeight = reservedHeight + contentMeasure.height;
      }
    }

    return _ShareCardLayout(
      totalHeight: totalHeight,
      showArabic: hasArabic,
      arabicStyle: arabicStyle,
      arabicGap: arabicGap,
      arabicMaxLines: arabicMeasure.maxLines,
      arabicTruncated: arabicMeasure.truncated,
      contentStyle: contentStyle,
      contentMaxLines: contentMeasure.maxLines,
      contentTruncated: contentMeasure.truncated,
      showReference: hasReference,
      referenceStyle: referenceStyle,
      referenceGap: referenceGap,
      referenceMaxLines: referenceMeasure.maxLines,
      referenceTruncated: referenceMeasure.truncated,
    );
  }

  static _MeasuredText _measureContent({
    required ShareCardPayload payload,
    required _ShareCardFitSpec spec,
    required TextStyle style,
    required double width,
    required TextDirection textDirection,
    required double availableHeight,
    required bool useEllipsisFallback,
  }) {
    if (!useEllipsisFallback) {
      return _measureText(
        text: payload.content,
        style: style,
        width: width,
        textDirection: textDirection,
      );
    }

    final unconstrained = _measureText(
      text: payload.content,
      style: style,
      width: width,
      textDirection: textDirection,
    );
    if (unconstrained.height <= availableHeight) return unconstrained;

    final lineHeight = style.fontSize! * style.height!;
    final allowedLines = (availableHeight / lineHeight)
        .floor()
        .clamp(spec.minContentLines, spec.maxContentLines);
    return _measureText(
      text: payload.content,
      style: style,
      width: width,
      textDirection: textDirection,
      maxLines: allowedLines,
      ellipsis: true,
    );
  }

  static _MeasuredText _measureText({
    required String text,
    required TextStyle style,
    required double width,
    required TextDirection textDirection,
    int? maxLines,
    bool ellipsis = false,
  }) {
    if (text.trim().isEmpty) return _MeasuredText.empty;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: ellipsis ? '…' : null,
    )..layout(maxWidth: width);
    return _MeasuredText(
      height: painter.size.height,
      lineCount: painter.computeLineMetrics().length,
      maxLines: maxLines,
      truncated: painter.didExceedMaxLines,
    );
  }

  static TextDirection _textDirectionForLocale(String? localeCode) {
    final code = (localeCode ?? '').toLowerCase();
    return code == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }
}

class _ShareCardSampleCase {
  const _ShareCardSampleCase({
    required this.label,
    required this.payload,
  });

  final String label;
  final ShareCardPayload payload;
}

class _ShareCardLayout {
  const _ShareCardLayout({
    required this.totalHeight,
    required this.showArabic,
    required this.arabicStyle,
    required this.arabicGap,
    required this.arabicMaxLines,
    required this.arabicTruncated,
    required this.contentStyle,
    required this.contentMaxLines,
    required this.contentTruncated,
    required this.showReference,
    required this.referenceStyle,
    required this.referenceGap,
    required this.referenceMaxLines,
    required this.referenceTruncated,
  });

  final double totalHeight;
  final bool showArabic;
  final TextStyle arabicStyle;
  final double arabicGap;
  final int? arabicMaxLines;
  final bool arabicTruncated;
  final TextStyle contentStyle;
  final int? contentMaxLines;
  final bool contentTruncated;
  final bool showReference;
  final TextStyle referenceStyle;
  final double referenceGap;
  final int? referenceMaxLines;
  final bool referenceTruncated;
}

class _MeasuredText {
  const _MeasuredText({
    required this.height,
    required this.lineCount,
    required this.maxLines,
    required this.truncated,
  });

  static const empty = _MeasuredText(
    height: 0,
    lineCount: 0,
    maxLines: null,
    truncated: false,
  );

  final double height;
  final int lineCount;
  final int? maxLines;
  final bool truncated;
}

class _ShareCardFitSpec {
  const _ShareCardFitSpec({
    required this.contentFontSize,
    required this.minContentFontSize,
    required this.contentLineHeight,
    required this.minContentLineHeight,
    required this.contentGapBias,
    required this.arabicFontSize,
    required this.minArabicFontSize,
    required this.arabicLineHeight,
    required this.minArabicLineHeight,
    required this.referenceFontSize,
    required this.minReferenceFontSize,
    required this.referenceLineHeight,
    required this.minReferenceLineHeight,
    required this.arabicGap,
    required this.minArabicGap,
    required this.referenceGap,
    required this.minReferenceGap,
    required this.maxContentLines,
    required this.minContentLines,
    required this.maxArabicLines,
    required this.minArabicLinesWhenShared,
    required this.referenceMaxLines,
    required this.minScale,
    required this.scaleSteps,
  });

  final double contentFontSize;
  final double minContentFontSize;
  final double contentLineHeight;
  final double minContentLineHeight;
  final double contentGapBias;
  final double arabicFontSize;
  final double minArabicFontSize;
  final double arabicLineHeight;
  final double minArabicLineHeight;
  final double referenceFontSize;
  final double minReferenceFontSize;
  final double referenceLineHeight;
  final double minReferenceLineHeight;
  final double arabicGap;
  final double minArabicGap;
  final double referenceGap;
  final double minReferenceGap;
  final int maxContentLines;
  final int minContentLines;
  final int maxArabicLines;
  final int minArabicLinesWhenShared;
  final int referenceMaxLines;
  final double minScale;
  final int scaleSteps;

  factory _ShareCardFitSpec.forPayload(ShareCardPayload payload) {
    final hasArabic = payload.arabicText?.trim().isNotEmpty ?? false;
    switch (payload.type) {
      case ShareCardType.ayah:
        return _ShareCardFitSpec(
          contentFontSize: hasArabic ? 34 : 36,
          minContentFontSize: hasArabic ? 24 : 26,
          contentLineHeight: hasArabic ? 1.62 : 1.66,
          minContentLineHeight: 1.44,
          contentGapBias: 1,
          arabicFontSize: 60,
          minArabicFontSize: 42,
          arabicLineHeight: 1.60,
          minArabicLineHeight: 1.42,
          referenceFontSize: 22,
          minReferenceFontSize: 18,
          referenceLineHeight: 1.45,
          minReferenceLineHeight: 1.32,
          arabicGap: 34,
          minArabicGap: 20,
          referenceGap: 28,
          minReferenceGap: 18,
          maxContentLines: 16,
          minContentLines: 4,
          maxArabicLines: 6,
          minArabicLinesWhenShared: 2,
          referenceMaxLines: 2,
          minScale: 0.68,
          scaleSteps: 12,
        );
      case ShareCardType.hadith:
        return const _ShareCardFitSpec(
          contentFontSize: 35,
          minContentFontSize: 24,
          contentLineHeight: 1.66,
          minContentLineHeight: 1.46,
          contentGapBias: 1.15,
          arabicFontSize: 58,
          minArabicFontSize: 44,
          arabicLineHeight: 1.56,
          minArabicLineHeight: 1.40,
          referenceFontSize: 22,
          minReferenceFontSize: 18,
          referenceLineHeight: 1.45,
          minReferenceLineHeight: 1.32,
          arabicGap: 32,
          minArabicGap: 18,
          referenceGap: 28,
          minReferenceGap: 18,
          maxContentLines: 18,
          minContentLines: 5,
          maxArabicLines: 5,
          minArabicLinesWhenShared: 2,
          referenceMaxLines: 2,
          minScale: 0.66,
          scaleSteps: 14,
        );
      case ShareCardType.quote:
      case ShareCardType.reminder:
        return const _ShareCardFitSpec(
          contentFontSize: 38,
          minContentFontSize: 26,
          contentLineHeight: 1.64,
          minContentLineHeight: 1.44,
          contentGapBias: 0.9,
          arabicFontSize: 58,
          minArabicFontSize: 44,
          arabicLineHeight: 1.56,
          minArabicLineHeight: 1.40,
          referenceFontSize: 22,
          minReferenceFontSize: 18,
          referenceLineHeight: 1.45,
          minReferenceLineHeight: 1.32,
          arabicGap: 32,
          minArabicGap: 18,
          referenceGap: 28,
          minReferenceGap: 18,
          maxContentLines: 14,
          minContentLines: 3,
          maxArabicLines: 5,
          minArabicLinesWhenShared: 2,
          referenceMaxLines: 2,
          minScale: 0.70,
          scaleSteps: 11,
        );
      case ShareCardType.asma:
        return const _ShareCardFitSpec(
          contentFontSize: 40,
          minContentFontSize: 30,
          contentLineHeight: 1.60,
          minContentLineHeight: 1.42,
          contentGapBias: 0.75,
          arabicFontSize: 72,
          minArabicFontSize: 56,
          arabicLineHeight: 1.60,
          minArabicLineHeight: 1.48,
          referenceFontSize: 22,
          minReferenceFontSize: 18,
          referenceLineHeight: 1.45,
          minReferenceLineHeight: 1.32,
          arabicGap: 34,
          minArabicGap: 22,
          referenceGap: 24,
          minReferenceGap: 16,
          maxContentLines: 10,
          minContentLines: 2,
          maxArabicLines: 5,
          minArabicLinesWhenShared: 2,
          referenceMaxLines: 2,
          minScale: 0.76,
          scaleSteps: 8,
        );
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
    required this.accentSoft,
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
  final Color accentSoft;
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
        panel: Color(0xFF1A232D),
        border: Color(0xFF34414E),
        accentSoft: Color(0x1F9ECFCE),
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
      panel: Color(0xFFFCF8F2),
      border: Color(0xFFE0D7CB),
      accentSoft: Color(0x14486F82),
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
