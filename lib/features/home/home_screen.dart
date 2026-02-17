import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/adhan_times_service.dart';
import '../../data/daily_ayah_service.dart';
import '../../data/daily_content_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/quran_data.dart';
import '../../data/reading_progress_service.dart';
import '../../data/user_profile_service.dart';
import '../../l10n/app_strings.dart';
import '../../main.dart';
import '../../models/prayer_location.dart';
import '../../models/reading_context.dart';
import '../../widgets/next_prayer_pill.dart';
import '../../widgets/quick_actions_popover.dart';
import '../adhan/adhan_times_screen.dart';
import '../qibla/qibla_screen.dart';
import '../ramadan/ramadan_hub_screen.dart';
import '../reading/ayah_reading_screen.dart';
import '../settings/settings_screen.dart';
import '../surah/surah_list_screen.dart';
import '../tasbih/tasbih_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final GlobalKey _quickActionsKey = GlobalKey();
  bool _checkedNamePrompt = false;
  Timer? _clockTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNamePrompt();
    });
    _clockTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    QuickActionsPopover.hide();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  void didPushNext() {
    QuickActionsPopover.hide();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return S.get('greeting_night');
    if (hour < 12) return S.get('greeting_morning');
    if (hour < 17) return S.get('greeting_day');
    if (hour < 21) return S.get('greeting_evening');
    return S.get('greeting_night');
  }

  String _buildGreetingText(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return _getGreeting();
    return '${_getGreeting()}, $name';
  }

  Future<void> _maybeShowNamePrompt() async {
    if (_checkedNamePrompt || !mounted) return;
    _checkedNamePrompt = true;

    if (!UserProfileService.shouldShowNamePrompt) return;

    final controller = TextEditingController(
      text: UserProfileService.displayName ?? '',
    );
    var completed = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFDF9F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('name_prompt_title'),
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
                decoration: InputDecoration(
                  hintText: S.get('name_hint'),
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB5AEA8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFBF6F2),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB57A5A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    completed = true;
                    await UserProfileService.setDisplayName(controller.text);
                    await UserProfileService.markNamePromptShown();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    S.get('continue'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () async {
                    completed = true;
                    await UserProfileService.markNamePromptShown();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    S.get('skip'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A746F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() async {
      if (!completed) {
        await UserProfileService.markNamePromptShown();
      }
    });

    controller.dispose();
  }

  void _toggleQuickActions() {
    QuickActionsPopover.toggle(
      context: context,
      anchorKey: _quickActionsKey,
      onQibla: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        );
      },
      onAdhanTimes: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdhanTimesScreen()),
        );
      },
      onTasbih: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TasbihScreen()),
        );
      },
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFDF9F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SettingsScreen(scrollController: scrollController),
            );
          },
        );
      },
    );
  }

  String? _maghribCountdown(PrayerLocation location) {
    if (!location.hasCoordinates) return null;
    final times = AdhanTimesService.computeTimes(
      _now,
      location,
      countryHint: _countryFromPrayerLocation(location),
    );
    final diff = times.maghrib.difference(_now);
    if (diff.isNegative || diff > const Duration(minutes: 60)) return null;

    final totalMinutes = (diff.inSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String? _countryFromPrayerLocation(PrayerLocation location) {
    if (location.mode == PrayerLocationMode.current) return null;
    final raw = location.cityName ?? '';
    final parts = raw.split(',');
    if (parts.length < 2) return null;
    return parts.last.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 26),
              _buildSectionHeader(
                title: S.get('home_section_now_upcoming'),
                icon: Icons.schedule_rounded,
              ),
              const SizedBox(height: 10),
              NextPrayerPill(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdhanTimesScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<PrayerLocation>(
                valueListenable: LocalPreferencesService.prayerLocation,
                builder: (context, location, _) {
                  final countdown = _maghribCountdown(location);
                  if (countdown == null) return const SizedBox.shrink();
                  return _buildCountdownCard(countdown);
                },
              ),
              const SizedBox(height: 30),
              _buildSectionHeader(
                title: S.get('home_section_for_today'),
                icon: Icons.auto_awesome_outlined,
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: DailyContentService.revision,
                builder: (context, _, __) => _buildPrimaryDailyCard(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TodayScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7A746F),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  S.get('home_see_more_for_today'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: S.get('home_section_explore'),
                icon: Icons.explore_outlined,
              ),
              const SizedBox(height: 10),
              _buildExploreQuranEntry(context),
              const SizedBox(height: 12),
              _buildExploreEntry(
                title: S.get('ramadan_hub_title'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RamadanHubScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: _quickActionsKey,
          onTap: _toggleQuickActions,
          child: const Padding(
            padding: EdgeInsets.only(top: 6, right: 12),
            child: Icon(
              Icons.menu_rounded,
              size: 24,
              color: Color(0xFF7A746F),
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<String?>(
            valueListenable: UserProfileService.displayNameNotifier,
            builder: (context, displayName, _) {
              return Text(
                _buildGreetingText(displayName),
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                  height: 1.3,
                ),
              );
            },
          ),
        ),
        GestureDetector(
          onTap: _openSettingsModal,
          child: const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.settings_rounded,
              size: 24,
              color: Color(0xFF7A746F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8FA9A7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7A746F),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(String countdown) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7BAEAC), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timelapse_rounded,
            size: 16,
            color: Color(0xFF7BAEAC),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.get('home_time_to_maghrib'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5F5954),
              ),
            ),
          ),
          Text(
            countdown,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7BAEAC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryDailyCard() {
    final date = DateTime.now();
    final contentType = DailyContentService.homeContentTypeForDate(date);

    switch (contentType) {
      case HomeDailyContentType.verse:
        final ayah = DailyAyahService.getTodayAyahWithContext(
          QuranData.instance.ayahs,
          QuranData.instance.getSurahName,
        );
        return _buildPrimaryCard(
          title: S.get('daily_ayah'),
          body: ayah.turkishReadable,
          source: ayah.reference,
        );
      case HomeDailyContentType.hadith:
        final hadith = DailyContentService.todayHadith;
        return _buildPrimaryCard(
          title: S.get('daily_hadith_title'),
          body: hadith?.text ?? S.get('daily_hadith_empty'),
          source: hadith?.source,
        );
      case HomeDailyContentType.gentleReminder:
        final reminder = DailyContentService.todayWord;
        return _buildPrimaryCard(
          title: S.get('daily_word_title'),
          body: reminder?.text ?? S.get('daily_word_empty'),
        );
      case HomeDailyContentType.quote:
        final quote = DailyContentService.getQuoteForDate(date);
        return _buildPrimaryCard(
          title: S.get('daily_quote_title'),
          body: quote.text,
          source: quote.source,
        );
    }
  }

  Widget _buildPrimaryCard({
    required String title,
    required String body,
    String? source,
  }) {
    final cleanSource = source?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7BAEAC), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x182B2721),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7BAEAC),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.6,
            ),
          ),
          if (cleanSource.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              cleanSource,
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
    );
  }

  Widget _buildExploreQuranEntry(BuildContext context) {
    const readingContext = ReadingContext.explore();
    final progress = ReadingProgressService.getContextProgress(readingContext);

    return _buildExploreEntry(
      title: S.get('start_reading'),
      subtitle: progress == null
          ? null
          : '${QuranData.instance.getSurahName(progress.surah)} · ${progress.ayah}. ${S.get('ayah_label')}',
      onTap: () {
        if (progress != null) {
          final surahName = QuranData.instance.getSurahName(progress.surah);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AyahReadingScreen(
                surahNumber: progress.surah,
                surahName: surahName,
                readingContext: readingContext,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SurahListScreen()),
          );
        }
      },
    );
  }

  Widget _buildExploreEntry({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(10),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                      height: 1.4,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFB5AEA8),
            ),
          ],
        ),
      ),
    );
  }
}
