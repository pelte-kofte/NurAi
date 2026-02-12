import 'package:flutter/material.dart';
import '../../data/collective_reading_service.dart';
import '../../data/quran_data.dart';
import '../../data/ramadan_daily_note_service.dart';
import '../../data/reading_progress_service.dart';
import '../../models/reading_context.dart';
import '../reading/ayah_reading_screen.dart';
import '../ramadan/duas_screen.dart';
import '../settings/settings_screen.dart';

class RamadanHubScreen extends StatefulWidget {
  const RamadanHubScreen({super.key});

  @override
  State<RamadanHubScreen> createState() => _RamadanHubScreenState();
}

class _RamadanHubScreenState extends State<RamadanHubScreen> {
  RamadanDailyNote? _dailyNote;
  int? _selectedJuz;
  bool _isJuzCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadDailyNote();
    _refreshJuzState();
  }

  Future<void> _loadDailyNote() async {
    await RamadanDailyNoteService.load();
    if (!mounted) return;
    setState(() {
      _dailyNote = RamadanDailyNoteService.getTodayNote();
    });
  }

  void _openHatimReading() {
    const ctx = ReadingContext.hatim();
    final progress = ReadingProgressService.getContextProgress(ctx);
    final surah = progress?.surah ?? 1;
    final ayah = progress?.ayah ?? 1;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
  }

  void _refreshJuzState() {
    _selectedJuz = CollectiveReadingService.getSelectedJuz();
    _isJuzCompleted = CollectiveReadingService.isCompleted();
  }

  Future<void> _showJuzPicker() async {
    final chosenJuz = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFFFBF6F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cüz Seç',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(30, (index) {
                  final juzNumber = index + 1;
                  final isSelected = _selectedJuz == juzNumber;
                  return GestureDetector(
                    onTap: () => Navigator.of(bottomSheetContext).pop(juzNumber),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8E2DC)
                            : const Color(0xFFFDF9F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEDE6E1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$juzNumber',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: const Color(0xFF7A746F),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );

    if (chosenJuz == null) return;
    await CollectiveReadingService.selectJuz(chosenJuz);
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  Future<void> _markJuzCompleted() async {
    await CollectiveReadingService.markCompleted();
    if (!mounted) return;
    setState(_refreshJuzState);
  }

  void _openJuzReading() {
    if (_selectedJuz == null) return;

    final juzNumber = _selectedJuz!;
    final ctx = ReadingContext.juz(juzNumber);
    final progress = ReadingProgressService.getContextProgress(ctx);
    final range = CollectiveReadingService.getJuzRange(juzNumber);
    final surah = progress?.surah ?? range?.startSurah ?? 1;
    final ayah = progress?.ayah ?? range?.startAyah ?? 1;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surahNumber: surah,
          surahName: QuranData.instance.getSurahName(surah),
          initialAyah: ayah,
          readingContext: ctx,
        ),
      ),
    );
  }

  void _openDuas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DuasScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFFBF6F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF6F2),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: Color(0xFF7A746F),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Ayarlar',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B2725),
              ),
            ),
          ),
          body: const SettingsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hatimCtx = ReadingContext.hatim();
    final hatimProgress = ReadingProgressService.getContextProgress(hatimCtx);
    final hatimSubtitle = hatimProgress != null
        ? '${QuranData.instance.getSurahName(hatimProgress.surah)} \u00b7 ${hatimProgress.ayah}. Ayet'
        : 'Hatim niyetiyle sakin bir ba\u015flang\u0131\u00e7 yap\u0131n';
    final hatimCta = hatimProgress != null ? 'Devam Et' : 'Ba\u015fla';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: Color(0xFF7A746F),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ramazan Rehberi',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        children: [
          const Text(
            'Ramazan, kalbi sadele\u015ftirip niyeti tazeleyen bir yolculuktur.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeader('Okuma'),
          const SizedBox(height: 10),
          _ReadingCard(
            title: 'Hatim Niyeti',
            subtitle: hatimSubtitle,
            cta: hatimCta,
            accent: true,
            onTap: _openHatimReading,
          ),
          const SizedBox(height: 22),
          const _SectionHeader('Cüz Niyeti'),
          const SizedBox(height: 10),
          _buildJuzIntentionCard(),
          const SizedBox(height: 22),
          const _SectionHeader('Bug\u00fcn i\u00e7in k\u00fc\u00e7\u00fck not'),
          const SizedBox(height: 10),
          _DailyNoteCard(text: _dailyNote?.text ?? 'Y\u00fckleniyor...'),
          const SizedBox(height: 22),
          const _SectionHeader('Dualar'),
          const SizedBox(height: 10),
          _SimpleNavCard(
            title: 'K\u0131sa Dualar',
            onTap: _openDuas,
          ),
          const SizedBox(height: 22),
          const _SectionHeader('\u0130ftar & Ezan'),
          const SizedBox(height: 10),
          _SimpleNavCard(
            title: 'Ezan & Bildirimler',
            subtitle: 'Ezan alarmlar\u0131 ayarlardan y\u00f6netilir',
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildJuzIntentionCard() {
    if (_selectedJuz == null) {
      return _SimpleNavCard(
        title: 'Cüz Seç',
        subtitle: 'Bir cüz seçerek niyetinizi belirleyin',
        onTap: _showJuzPicker,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seçili Cüz: $_selectedJuz',
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
            ),
          ),
          if (_isJuzCompleted) ...[
            const SizedBox(height: 4),
            const Text(
              'Tamamlandı',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A746F),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _JuzActionButton(
                  label: 'Cüze Devam Et',
                  onTap: _openJuzReading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _JuzActionButton(
                  label: 'Cüzü Değiştir',
                  onTap: _showJuzPicker,
                ),
              ),
            ],
          ),
          if (!_isJuzCompleted) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _markJuzCompleted,
              child: const Text(
                'Tamamladım',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A746F),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF7A746F),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final bool accent;
  final VoidCallback onTap;

  const _ReadingCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    this.accent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
        ),
        child: Row(
          children: [
            if (accent)
              Container(
                width: 3,
                height: 44,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7BAEAC),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A746F),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cta,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7A746F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyNoteCard extends StatelessWidget {
  final String text;
  const _DailyNoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ramazan Notu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _JuzActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _JuzActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0EA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7A746F),
          ),
        ),
      ),
    );
  }
}

class _SimpleNavCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SimpleNavCard({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7A746F),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF7A746F),
            ),
          ],
        ),
      ),
    );
  }
}
