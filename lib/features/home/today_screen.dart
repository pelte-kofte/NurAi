import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/daily_ayah_service.dart';
import '../../data/daily_content_service.dart';
import '../../data/quran_data.dart';
import '../../data/quran_turkish_meal_service.dart';
import '../../l10n/app_strings.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dailyAyah = DailyAyahService.getTodayAyahWithContext(
      QuranData.instance.ayahs,
      QuranData.instance.getSurahName,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          S.get('today_screen_title'),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: DailyAyahService.getAyahReadableText(
                surah: dailyAyah.surahNumber,
                ayah: dailyAyah.ayahNumber,
                locale: Localizations.localeOf(context),
              ),
              builder: (context, snapshot) {
                return _buildVerseCard(
                  context,
                  dailyAyah,
                  readableText: snapshot.data ?? dailyAyah.turkishReadable,
                );
              },
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: DailyContentService.revision,
              builder: (context, _, __) => _buildContentCard(
                context: context,
                title: S.get('daily_hadith_title'),
                body: DailyContentService.todayHadith?.text ??
                    S.get('daily_hadith_empty'),
                source: DailyContentService.todayHadith?.source,
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: DailyContentService.revision,
              builder: (context, _, __) => _buildContentCard(
                context: context,
                title: S.get('daily_word_title'),
                body: DailyContentService.todayWord?.text ??
                    S.get('daily_word_empty'),
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<DailyQuoteItem>(
              future: DailyContentService.getQuoteForDate(
                DateTime.now(),
                Localizations.localeOf(context),
              ),
              builder: (context, snapshot) {
                final quote = snapshot.data;
                return _buildContentCard(
                  context: context,
                  title: S.get('daily_quote_title'),
                  body: quote?.text ?? '',
                  source: quote?.source,
                  showQuoteOrnaments: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseCard(
    BuildContext context,
    DailyAyah dailyAyah, {
    required String readableText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('daily_ayah'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.secondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            dailyAyah.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildReadableLine(
            context: context,
            dailyAyah: dailyAyah,
            readableText: readableText,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          Text(
            dailyAyah.reference,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadableLine({
    required BuildContext context,
    required DailyAyah dailyAyah,
    required String readableText,
    required ColorScheme colorScheme,
  }) {
    final text = Text(
      readableText,
      style: TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.6,
      ),
    );

    final isTurkishLine = readableText.trim().isNotEmpty &&
        readableText.trim() == dailyAyah.turkishReadable.trim();
    if (!isTurkishLine) return text;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showMealBottomSheet(context, dailyAyah),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: text,
      ),
    );
  }

  Future<void> _showMealBottomSheet(
      BuildContext context, DailyAyah dailyAyah) async {
    final meal = await QuranTurkishMealService.getTurkishMeal(
      dailyAyah.surahNumber,
      dailyAyah.ayahNumber,
    );
    if (!context.mounted) return;

    final fallback = S
        .get('meal_sheet_title_fallback')
        .replaceAll('{surah}', dailyAyah.surahNumber.toString())
        .replaceAll('{ayah}', dailyAyah.ayahNumber.toString());
    final surahName =
        QuranData.instance.getSurahName(dailyAyah.surahNumber).trim();
    final title = surahName.isEmpty
        ? fallback
        : '$surahName · ${dailyAyah.ayahNumber}. ${S.get('ayah_label')}';
    final body = (meal?.trim().isNotEmpty ?? false)
        ? meal!.trim()
        : S.get('meal_not_available');

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('meal_label'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.secondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                body,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: body));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(S.get('meal_copied'))),
                      );
                    },
                    child: Text(S.get('meal_copy')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(S.get('meal_close')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentCard({
    required BuildContext context,
    required String title,
    required String body,
    String? source,
    bool showQuoteOrnaments = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final cleanSource = source?.trim() ?? '';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showQuoteOrnaments) ...[
              Positioned(
                left: -24,
                bottom: -28,
                child: Opacity(
                  opacity: 0.1,
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Image.asset(
                      'assets/splash/splash.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -24,
                bottom: -28,
                child: Opacity(
                  opacity: 0.1,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scaleByDouble(-1.0, 1.0, 1.0, 1.0)
                      ..rotateZ(0.12),
                    child: Image.asset(
                      'assets/splash/splash.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.secondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                  if (cleanSource.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '- $cleanSource',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
