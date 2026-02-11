import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../data/collective_reading_service.dart';
import '../../data/daily_ayah_service.dart';
import '../../data/daily_wisdom_service.dart';
import '../../data/adhan_notification_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/notes_service.dart';
import '../../data/reading_progress_service.dart';
import '../../models/reading_context.dart';
import '../../main.dart';
import '../collective/collective_reading_screen.dart';
import '../notes/note_editor_screen.dart';
import '../qibla/qibla_screen.dart';
import '../reading/ayah_reading_screen.dart';
import '../settings/settings_screen.dart';
import '../surah/surah_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final GlobalKey _quickActionsKey = GlobalKey();
  OverlayEntry? _quickActionsEntry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _removeQuickActionsPopover();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refresh();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Hay\u0131rl\u0131 geceler';
    if (hour < 12) return 'Hay\u0131rl\u0131 sabahlar';
    if (hour < 17) return 'Hay\u0131rl\u0131 g\u00fcnler';
    if (hour < 21) return 'Hay\u0131rl\u0131 ak\u015famlar';
    return 'Hay\u0131rl\u0131 geceler';
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dailyAyah = DailyAyahService.getTodayAyahWithContext(
      QuranData.instance.ayahs,
      QuranData.instance.getSurahName,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 24),
              _buildNotesEntry(context),
              const SizedBox(height: 32),
              _buildDailyAyahCard(dailyAyah),
              if (DailyWisdomService.getTodayWisdom() != null) ...[
                const SizedBox(height: 20),
                _buildWisdomCard(DailyWisdomService.getTodayWisdom()!),
              ],
              const SizedBox(height: 24),
              _buildRamadanInfo(),
              const SizedBox(height: 24),
              _buildReadingEntry(context),
              const SizedBox(height: 16),
              _buildHatimEntry(context),
              const SizedBox(height: 16),
              _buildCollectiveReadingEntry(context),
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
          onTap: _showQuickActionsPopover,
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
          child: Text(
            _getGreeting(),
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Color(0xFF2B2725),
              height: 1.3,
            ),
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

  void _showQuickActionsPopover() {
    if (_quickActionsEntry != null) {
      _removeQuickActionsPopover();
      return;
    }

    final overlay = Overlay.of(context);
    final renderBox =
        _quickActionsKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final origin = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _quickActionsEntry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeQuickActionsPopover,
              ),
            ),
            Positioned(
              left: origin.dx,
              top: origin.dy + size.height + 8,
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (ctx, setPopoverState) {
                    return Container(
                      width: 220,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF9F6),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A2B2725),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _removeQuickActionsPopover();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const QiblaScreen(),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.explore_rounded,
                                    size: 18,
                                    color: Color(0xFF7A746F),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Kıble',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF2B2725),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Color(0xFFB5AEA8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: const Color(0xFFEDE6E1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Ezan alarmları',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF2B2725),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 26,
                                  child: Switch.adaptive(
                                    value: LocalPreferencesService
                                        .adhanEnabled.value,
                                    onChanged: (v) async {
                                      if (v) {
                                        final granted = await AdhanNotificationService.requestPermissions();
                                        if (granted) {
                                          await LocalPreferencesService.setAdhanEnabled(true);
                                          await AdhanNotificationService.schedulePrayerNotifications();
                                          setPopoverState(() {});
                                        } else {
                                          _removeQuickActionsPopover();
                                          _showNotificationPermissionDialog();
                                        }
                                      } else {
                                        await LocalPreferencesService.setAdhanEnabled(false);
                                        await AdhanNotificationService.cancelAll();
                                        setPopoverState(() {});
                                      }
                                    },
                                    activeTrackColor: const Color(0xFFB57A5A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_quickActionsEntry!);
  }

  void _removeQuickActionsPopover() {
    _quickActionsEntry?.remove();
    _quickActionsEntry = null;
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDF9F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Bildirim \u0130zni',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFF2B2725),
          ),
        ),
        content: const Text(
          'Ezan vakitlerini bildirebilmemiz i\u00e7in bildirim iznine ihtiyac\u0131m\u0131z var.\n\nCihaz ayarlar\u0131ndan bildirimleri etkinle\u015ftirebilirsiniz.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7A746F),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tamam',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB57A5A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.95,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0D7D0),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const Expanded(child: SettingsScreen()),
              ],
            ),
          ),
        );
      },
    ).then((_) => _refresh());
  }

  Widget _buildNotesEntry(BuildContext context) {
    final preview = NotesService.getFirstLinePreview();

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
            )
            .then((_) => _refresh());
      },
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
              child: Text(
                preview ?? 'Bug\u00fcn nas\u0131ls\u0131n\u0131z?',
                style: TextStyle(
                  fontFamily: preview != null ? 'Merriweather' : 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle:
                      preview != null ? FontStyle.italic : FontStyle.normal,
                  color: const Color(0xFF7A746F),
                  height: 1.4,
                ),
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Color(0xFFB5AEA8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWisdomCard(DailyWisdom wisdom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDE6E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wisdom.text,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2B2725),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\u2014 ${wisdom.source}',
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

  Widget _buildDailyAyahCard(DailyAyah dailyAyah) {
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
            'G\u00fcn\u00fcn Ayeti',
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
              dailyAyah.arabic,
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
            dailyAyah.turkishReadable,
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
              'Ramazan ay\u0131na haz\u0131rl\u0131k zaman\u0131',
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

  Widget _buildReadingEntry(BuildContext context) {
    const ctx = ReadingContext.explore();
    final progress = ReadingProgressService.getContextProgress(ctx);
    final globalSurah = ReadingProgressService.getGlobalLastSurah();
    final globalAyah = ReadingProgressService.getGlobalLastAyah();
    final hasGlobal = globalSurah != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (progress != null) {
              final surahName = QuranData.instance.getSurahName(progress.surah);
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => AyahReadingScreen(
                        surahNumber: progress.surah,
                        surahName: surahName,
                        readingContext: ctx,
                      ),
                    ),
                  )
                  .then((_) => _refresh());
            } else {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const SurahListScreen(),
                    ),
                  )
                  .then((_) => _refresh());
            }
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
                    'Okumaya ba\u015fla',
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
        ),
        if (hasGlobal)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              '${QuranData.instance.getSurahName(globalSurah)} Suresi \u00b7 $globalAyah. Ayet',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: Color(0xFF7A746F),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHatimEntry(BuildContext context) {
    const ctx = ReadingContext.hatim();
    final progress = ReadingProgressService.getContextProgress(ctx);

    String subtitle;
    if (progress != null) {
      final surahName = QuranData.instance.getSurahName(progress.surah);
      subtitle = '$surahName \u00b7 ${progress.ayah}. Ayet';
    } else {
      subtitle = 'Ba\u015ftan sona okuma niyeti';
    }

    return GestureDetector(
      onTap: () {
        if (progress != null) {
          final surahName = QuranData.instance.getSurahName(progress.surah);
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => AyahReadingScreen(
                    surahNumber: progress.surah,
                    surahName: surahName,
                    readingContext: ctx,
                  ),
                ),
              )
              .then((_) => _refresh());
        } else {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const SurahListScreen(
                    readingContext: ctx,
                  ),
                ),
              )
              .then((_) => _refresh());
        }
      },
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
                  const Text(
                    'Hatim Niyeti',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A746F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB5AEA8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFFB5AEA8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectiveReadingEntry(BuildContext context) {
    final selectedJuz = CollectiveReadingService.getSelectedJuz();
    final isCompleted = CollectiveReadingService.isCompleted();

    String subtitle;
    if (selectedJuz != null && !isCompleted) {
      final ctx = ReadingContext.juz(selectedJuz);
      final progress = ReadingProgressService.getContextProgress(ctx);
      if (progress != null) {
        final surahName = QuranData.instance.getSurahName(progress.surah);
        subtitle =
            '$selectedJuz. C\u00fcz \u00b7 $surahName ${progress.ayah}. Ayet';
      } else {
        subtitle = '$selectedJuz. C\u00fcz se\u00e7ildi';
      }
    } else {
      subtitle = 'Birlikte okuma i\u00e7in niyet et';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                  builder: (_) => const CollectiveReadingScreen()),
            )
            .then((_) => _refresh());
      },
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
                  const Text(
                    'C\u00fcz Niyeti',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A746F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB5AEA8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFFB5AEA8),
            ),
          ],
        ),
      ),
    );
  }
}
