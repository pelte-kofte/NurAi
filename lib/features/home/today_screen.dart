import 'package:flutter/material.dart';

import '../../data/daily_ayah_service.dart';
import '../../theme/app_theme.dart';
import '../../data/daily_content_service.dart';
import '../../data/quran_data.dart';
import '../../l10n/app_strings.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dailyAyah = DailyAyahService.getTodayAyahWithContext(
      QuranData.instance.ayahs,
      QuranData.instance.getSurahName,
    );
    final quote = DailyContentService.getQuoteForDate(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          S.get('today_screen_title'),
          style: const TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerseCard(dailyAyah),
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: DailyContentService.revision,
              builder: (context, _, __) => _buildContentCard(
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
                title: S.get('daily_word_title'),
                body: DailyContentService.todayWord?.text ??
                    S.get('daily_word_empty'),
              ),
            ),
            const SizedBox(height: 14),
            _buildContentCard(
              title: S.get('daily_quote_title'),
              body: quote.text,
              source: quote.source,
              showQuoteOrnaments: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseCard(DailyAyah dailyAyah) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('daily_ayah'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.indigoAccent,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            dailyAyah.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            dailyAyah.turkishReadable,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dailyAyah.reference,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String body,
    String? source,
    bool showQuoteOrnaments = false,
  }) {
    final cleanSource = source?.trim() ?? '';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1)),
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
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.indigoAccent,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                      height: 1.6,
                    ),
                  ),
                  if (cleanSource.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '- $cleanSource',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7A746F),
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
