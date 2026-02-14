import 'package:flutter/material.dart';
import '../../data/collective_reading_service.dart';
import '../../data/quran_data.dart';
import '../../data/ramadan_daily_note_service.dart';
import '../../data/reading_progress_service.dart';
import '../../l10n/app_strings.dart';
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
  String? _loadedLanguageCode;

  @override
  void initState() {
    super.initState();
    _refreshJuzState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedLanguageCode != languageCode) {
      _loadedLanguageCode = languageCode;
      _loadDailyNote(languageCode);
    }
  }

  Future<void> _loadDailyNote(String languageCode) async {
    final assetPath = switch (languageCode) {
      'tr' => 'assets/ramadan/daily_notes_tr.json',
      'en' => 'assets/ramadan/daily_notes_en.json',
      'ar' => 'assets/ramadan/daily_notes_ar.json',
      'de' => 'assets/ramadan/daily_notes_de.json',
      'fr' => 'assets/ramadan/daily_notes_fr.json',
      _ => 'assets/ramadan/daily_notes_en.json',
    };
    await RamadanDailyNoteService.load(assetPath: assetPath);
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
              Text(
                S.get('ramadan_juz_select'),
                style: const TextStyle(
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
            title: Text(
              S.get('settings'),
              style: const TextStyle(
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
    final activeLang = Localizations.localeOf(context).languageCode;
    final hatimProgress = ReadingProgressService.getContextProgress(hatimCtx);
    final hatimSubtitle = hatimProgress != null
        ? '${QuranData.instance.getSurahName(hatimProgress.surah)} \u00b7 ${hatimProgress.ayah}. ${S.get('ayah_label')}'
        : S.get('ramadan_hatim_subtitle');
    final hatimCta = hatimProgress != null ? S.get('continue') : S.get('ramadan_start');

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
        title: Text(
          S.get('ramadan_hub_title'),
          style: const TextStyle(
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
          Text(
            'Ramadan • $activeLang',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFFB5AEA8),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.get('ramadan_intro'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A746F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(S.get('ramadan_section_reading')),
          const SizedBox(height: 10),
          _ReadingCard(
            title: S.get('hatim_title'),
            subtitle: hatimSubtitle,
            cta: hatimCta,
            accent: true,
            onTap: _openHatimReading,
          ),
          const SizedBox(height: 22),
          _SectionHeader(S.get('juz_title')),
          const SizedBox(height: 10),
          _buildJuzIntentionCard(),
          const SizedBox(height: 22),
          _SectionHeader(S.get('ramadan_section_daily_note')),
          const SizedBox(height: 10),
          _DailyNoteCard(text: _dailyNote?.text ?? S.get('prayer_times_loading')),
          const SizedBox(height: 22),
          _SectionHeader(S.get('ramadan_section_duas')),
          const SizedBox(height: 10),
          _SimpleNavCard(
            title: S.get('ramadan_short_duas'),
            onTap: _openDuas,
          ),
          const SizedBox(height: 22),
          _SectionHeader(S.get('ramadan_section_iftar_adhan')),
          const SizedBox(height: 10),
          _SimpleNavCard(
            title: S.get('ramadan_adhan_notifications'),
            subtitle: S.get('ramadan_adhan_notifications_subtitle'),
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildJuzIntentionCard() {
    if (_selectedJuz == null) {
      return _SimpleNavCard(
        title: S.get('ramadan_juz_select'),
        subtitle: S.get('ramadan_juz_select_subtitle'),
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
            '${S.get('ramadan_selected_juz')}: $_selectedJuz',
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
            ),
          ),
          if (_isJuzCompleted) ...[
            const SizedBox(height: 4),
            Text(
              S.get('ramadan_completed'),
              style: const TextStyle(
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
                  label: S.get('ramadan_continue_juz'),
                  onTap: _openJuzReading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _JuzActionButton(
                  label: S.get('ramadan_change_juz'),
                  onTap: _showJuzPicker,
                ),
              ),
            ],
          ),
          if (!_isJuzCompleted) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _markJuzCompleted,
              child: Text(
                S.get('ramadan_mark_completed'),
                style: const TextStyle(
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
          Text(
            S.get('ramadan_note_title'),
            style: const TextStyle(
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
