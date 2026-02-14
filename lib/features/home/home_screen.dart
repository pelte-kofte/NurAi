import 'package:flutter/material.dart';
import '../../data/quran_data.dart';
import '../../data/daily_ayah_service.dart';
import '../../data/daily_content_service.dart';
import '../../l10n/app_strings.dart';
import '../../data/notes_service.dart';
import '../../data/reading_progress_service.dart';
import '../../data/user_profile_service.dart';
import '../../models/reading_context.dart';
import '../../widgets/quick_actions_popover.dart';
import '../../main.dart';
<<<<<<< HEAD
import '../collective/collective_reading_screen.dart';
import '../adhan/adhan_times_screen.dart';
=======
>>>>>>> b0bb772ef4b891d4bdef00424329d243384adf2c
import '../qibla/qibla_screen.dart';
import '../ramadan/ramadan_hub_screen.dart';
import '../reading/ayah_reading_screen.dart';
import '../settings/settings_screen.dart';
import '../surah/surah_list_screen.dart';

enum _Mood { gratitude, calm, anxious, sad, tired, neutral }

enum _SuggestionType { ayah, hadith }

class _SuggestionItem {
  final _SuggestionType type;
  final String textKey;
  final String sourceKey;

  const _SuggestionItem({
    required this.type,
    required this.textKey,
    required this.sourceKey,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final GlobalKey _quickActionsKey = GlobalKey();
  bool _checkedNamePrompt = false;
  static const Map<_Mood, List<_SuggestionItem>> _suggestionPool = {
    _Mood.gratitude: [
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_gratitude_1_text',
        sourceKey: 'suggestion_gratitude_1_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.hadith,
        textKey: 'suggestion_gratitude_2_text',
        sourceKey: 'suggestion_gratitude_2_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_gratitude_3_text',
        sourceKey: 'suggestion_gratitude_3_source',
      ),
    ],
    _Mood.calm: [
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_calm_1_text',
        sourceKey: 'suggestion_calm_1_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.hadith,
        textKey: 'suggestion_calm_2_text',
        sourceKey: 'suggestion_calm_2_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_calm_3_text',
        sourceKey: 'suggestion_calm_3_source',
      ),
    ],
    _Mood.anxious: [
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_anxious_1_text',
        sourceKey: 'suggestion_anxious_1_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_anxious_2_text',
        sourceKey: 'suggestion_anxious_2_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.hadith,
        textKey: 'suggestion_anxious_3_text',
        sourceKey: 'suggestion_anxious_3_source',
      ),
    ],
    _Mood.sad: [
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_sad_1_text',
        sourceKey: 'suggestion_sad_1_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_sad_2_text',
        sourceKey: 'suggestion_sad_2_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.hadith,
        textKey: 'suggestion_sad_3_text',
        sourceKey: 'suggestion_sad_3_source',
      ),
    ],
    _Mood.tired: [
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_tired_1_text',
        sourceKey: 'suggestion_tired_1_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.hadith,
        textKey: 'suggestion_tired_2_text',
        sourceKey: 'suggestion_tired_2_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_tired_3_text',
        sourceKey: 'suggestion_tired_3_source',
      ),
    ],
    _Mood.neutral: [
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_neutral_1_text',
        sourceKey: 'suggestion_neutral_1_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.hadith,
        textKey: 'suggestion_neutral_2_text',
        sourceKey: 'suggestion_neutral_2_source',
      ),
      _SuggestionItem(
        type: _SuggestionType.ayah,
        textKey: 'suggestion_neutral_3_text',
        sourceKey: 'suggestion_neutral_3_source',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNamePrompt();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    QuickActionsPopover.hide();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refresh();
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

  Future<void> _openTodayNoteSheet() async {
    if (NotesService.isDailyMoodLockedToday()) return;
    final controller = TextEditingController();
    var submitted = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
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
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.get('today_title'),
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: S.get('today_hint'),
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB5AEA8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFBF6F2),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final reflectionId = _generateDailyReflectionId(text);
                    final saved = await NotesService.submitDailyMood(
                      text: text,
                      reflectionId: reflectionId,
                    );
                    if (!saved) return;
                    submitted = true;
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    S.get('save'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (submitted) {
      NotesService.refreshDailyMoodState();
    }
    controller.dispose();
  }

  _Mood _classifyMood(String note) {
    final text = note.toLowerCase();

    const gratitudeKeywords = [
      'şükür',
      'elhamdülillah',
      'hamdolsun',
      'minnettar',
    ];
    const calmKeywords = ['huzur', 'sakin', 'dingin', 'rahat', 'ferah'];
    const anxiousKeywords = ['kaygı', 'stres', 'korku', 'endişe', 'panik'];
    const sadKeywords = ['üzgün', 'ağladım', 'kırgın', 'yalnız', 'moralim bozuk'];
    const tiredKeywords = ['yorgun', 'bitkin', 'uykusuz', 'tükendim', 'halsiz'];

    bool containsAny(List<String> keywords) =>
        keywords.any((k) => text.contains(k));

    if (containsAny(gratitudeKeywords)) return _Mood.gratitude;
    if (containsAny(calmKeywords)) return _Mood.calm;
    if (containsAny(anxiousKeywords)) return _Mood.anxious;
    if (containsAny(sadKeywords)) return _Mood.sad;
    if (containsAny(tiredKeywords)) return _Mood.tired;
    return _Mood.neutral;
  }

  int _generateDailyReflectionId(String note) {
    final mood = _classifyMood(note);
    final items = _suggestionPool[mood] ?? const <_SuggestionItem>[];
    if (items.isEmpty) return mood.index * 100;
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day + mood.index;
    final index = seed % items.length;
    return mood.index * 100 + index;
  }

  _SuggestionItem? _suggestionFromId(int? id) {
    if (id == null) return null;
    final moodIndex = id ~/ 100;
    final index = id % 100;
    if (moodIndex < 0 || moodIndex >= _Mood.values.length) return null;
    final mood = _Mood.values[moodIndex];
    final items = _suggestionPool[mood];
    if (items == null || index < 0 || index >= items.length) return null;
    return items[index];
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
<<<<<<< HEAD
              const SizedBox(height: 20),
              ValueListenableBuilder<int>(
                valueListenable: DailyContentService.revision,
                builder: (context, _, __) => _buildHadithCard(),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: DailyContentService.revision,
                builder: (context, _, __) => _buildDailyWordCard(),
              ),
              const SizedBox(height: 24),
              _buildRamadanInfo(),
=======
              if (DailyWisdomService.getTodayWisdom() != null) ...[
                const SizedBox(height: 20),
                _buildWisdomCard(DailyWisdomService.getTodayWisdom()!),
              ],
              if (DailyAyahService.isRamadanActive) ...[
                const SizedBox(height: 24),
                _buildRamadanInfo(),
              ],
>>>>>>> b0bb772ef4b891d4bdef00424329d243384adf2c
              const SizedBox(height: 24),
              _buildReadingEntry(context),
              const SizedBox(height: 16),
              _buildHatimEntry(context),
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
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AdhanTimesScreen()))
            .then((_) => _refresh());
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
    ).then((_) => _refresh());
  }

  void _openRamadanHub() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RamadanHubScreen()),
    );
  }

  Widget _buildNotesEntry(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotesService.dailyMoodRevision,
      builder: (context, _, __) {
        final isLocked = NotesService.isDailyMoodLockedToday();
        final todayText = NotesService.getTodayMoodText();
        final suggestion = _suggestionFromId(NotesService.getTodayReflectionId());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: isLocked ? null : _openTodayNoteSheet,
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
                        isLocked ? todayText : S.get('notes_placeholder'),
                        style: TextStyle(
                          fontFamily: isLocked ? 'Merriweather' : 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontStyle:
                              isLocked ? FontStyle.italic : FontStyle.normal,
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
            ),
            if (isLocked) ...[
              const SizedBox(height: 8),
              Text(
                S.get('today_intention_saved'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB5AEA8),
                ),
              ),
            ],
            if (suggestion != null) ...[
              const SizedBox(height: 10),
              Text(
                S.get('today_for'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A746F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                S.get(suggestion.textKey),
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2B2725),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${suggestion.type == _SuggestionType.ayah ? S.get('ayah_type') : S.get('hadith_type')} · ${S.get(suggestion.sourceKey)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB5AEA8),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHadithCard() {
    final hadith = DailyContentService.todayHadith;
    final source = hadith?.source?.trim() ?? '';
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
            S.get('daily_hadith_title'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hadith?.text ?? S.get('daily_hadith_empty'),
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2B2725),
              height: 1.6,
            ),
          ),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '— $source',
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

  Widget _buildDailyWordCard() {
    final word = DailyContentService.todayWord;
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
            S.get('daily_word_title'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A746F),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            word?.text ?? S.get('daily_word_empty'),
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2B2725),
              height: 1.6,
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
          Text(
            S.get('daily_ayah'),
            style: const TextStyle(
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
    return GestureDetector(
      onTap: _openRamadanHub,
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
            const Icon(Icons.nights_stay_outlined, size: 18, color: Color(0xFF7A746F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.get('ramadan_prep'),
                style: const TextStyle(
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.get('start_reading'),
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2725),
                      height: 1.4,
                    ),
                  ),
                ),
                const Icon(
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
              '${QuranData.instance.getSurahName(globalSurah)} ${S.get('surah_label')} \u00b7 $globalAyah. ${S.get('ayah_label')}',
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
      subtitle = '$surahName \u00b7 ${progress.ayah}. ${S.get('ayah_label')}';
    } else {
      subtitle = S.get('hatim_subtitle');
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
                  Text(
                    S.get('hatim_title'),
                    style: const TextStyle(
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

<<<<<<< HEAD
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
            '$selectedJuz. ${S.get('juz_label')} \u00b7 $surahName ${progress.ayah}. ${S.get('ayah_label')}';
      } else {
        subtitle = '$selectedJuz. ${S.get('juz_selected')}';
      }
    } else {
      subtitle = S.get('juz_subtitle');
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
                  Text(
                    S.get('juz_title'),
                    style: const TextStyle(
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
=======
>>>>>>> b0bb772ef4b891d4bdef00424329d243384adf2c
}



