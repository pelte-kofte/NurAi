import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../models/ayah.dart';
import '../surah/surah_list_screen.dart';

/// Home screen displaying a time-based greeting and daily ayah.
/// Data is loaded from QuranData singleton.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Hayırlı geceler';
    if (hour < 12) return 'Hayırlı sabahlar';
    if (hour < 17) return 'Hayırlı günler';
    if (hour < 21) return 'Hayırlı akşamlar';
    return 'Hayırlı geceler';
  }

  @override
  Widget build(BuildContext context) {
    final dailyAyah = QuranData.instance.getDailyAyah();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 32),
              if (dailyAyah != null) _buildDailyAyahCard(dailyAyah),
              const SizedBox(height: 24),
              _buildRamadanInfo(),
              const SizedBox(height: 24),
              _buildReadingEntry(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Text(
      _getGreeting(),
      style: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: Color(0xFF2B2725),
        height: 1.3,
      ),
    );
  }

  Widget _buildDailyAyahCard(Ayah ayah) {
    final surahName = QuranData.instance.getSurahName(ayah.surah);
    final reference = '$surahName Suresi, ${ayah.ayahNumber}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B2721),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Günün Ayeti',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B2725),
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFEDE6E1)),
          const SizedBox(height: 16),
          Text(
            ayah.turkishReadable,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reference,
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

  Widget _buildRamadanInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.nights_stay_outlined, size: 18, color: Color(0xFF7A746F)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ramazan ayına hazırlık zamanı',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle entry point to the surah list — an invitation, not a demand.
  Widget _buildReadingEntry(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SurahListScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Okumaya başla',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                  height: 1.4,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF7A746F),
            ),
          ],
        ),
      ),
    );
  }
}
