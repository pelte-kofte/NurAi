import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local_preferences_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

enum CompanionFlowStep { ayah, pause, dua }

class CompanionFlowScreen extends StatefulWidget {
  const CompanionFlowScreen({super.key});

  @override
  State<CompanionFlowScreen> createState() => _CompanionFlowScreenState();
}

class _AyahContent {
  const _AyahContent(this.textKey, this.sourceKey);

  final String textKey;
  final String sourceKey;
}

class _CompanionFlowScreenState extends State<CompanionFlowScreen> {
  static const _ayahs = <_AyahContent>[
    _AyahContent('companion_flow_ayah_1', 'companion_flow_ayah_source_1'),
    _AyahContent('companion_flow_ayah_2', 'companion_flow_ayah_source_2'),
    _AyahContent('companion_flow_ayah_3', 'companion_flow_ayah_source_3'),
    _AyahContent('companion_flow_ayah_4', 'companion_flow_ayah_source_4'),
    _AyahContent('companion_flow_ayah_5', 'companion_flow_ayah_source_5'),
    _AyahContent('companion_flow_ayah_6', 'companion_flow_ayah_source_6'),
  ];

  CompanionFlowStep _step = CompanionFlowStep.ayah;
  int _ayahIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAyah();
  }

  Future<void> _loadAyah() async {
    final index = await LocalPreferencesService.nextCompanionFlowVerseIndex(
      totalCount: _ayahs.length,
    );
    if (!mounted) return;
    setState(() => _ayahIndex = index);
  }

  void _continue() {
    HapticFeedback.selectionClick();
    setState(() {
      _step = switch (_step) {
        CompanionFlowStep.ayah => CompanionFlowStep.pause,
        CompanionFlowStep.pause => CompanionFlowStep.dua,
        CompanionFlowStep.dua => CompanionFlowStep.dua,
      };
    });
  }

  Future<void> _finish() async {
    await LocalPreferencesService.markCompanionFlowCompletedToday();
    await SpiritualProgressService.completeReflection(ReflectionPeriod.evening);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ayah = _ayahs[_ayahIndex];
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: S.get('companion_flow_close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  Text(
                    S.get('companion_flow_title'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.76),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _StepIndicator(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 18),
                  child: switch (_step) {
                    CompanionFlowStep.ayah => _CompanionCard(
                        eyebrow: S.get('companion_flow_content_type_ayah'),
                        title: S.get(ayah.textKey),
                        source: S.get(ayah.sourceKey),
                        body: S.get('companion_flow_ayah_prompt'),
                        icon: Icons.menu_book_rounded,
                      ),
                    CompanionFlowStep.pause => _CompanionCard(
                        eyebrow: S.get('companion_flow_step_pause'),
                        title: S.get('companion_flow_pause_title'),
                        body: S.get('companion_flow_pause_body'),
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    CompanionFlowStep.dua => _CompanionCard(
                        eyebrow: S.get('companion_flow_content_type_dua'),
                        title: S.get('companion_flow_dua_title'),
                        body: S.get('companion_flow_dua_body'),
                        note: S.get('companion_flow_dua_note'),
                        icon: Icons.volunteer_activism_rounded,
                      ),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      _step == CompanionFlowStep.dua ? _finish : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emphasisAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _step == CompanionFlowStep.dua
                        ? S.get('companion_flow_finish_cta')
                        : S.get('continue'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final CompanionFlowStep step;

  @override
  Widget build(BuildContext context) {
    final labels = [
      S.get('companion_flow_step_verse'),
      S.get('companion_flow_step_pause'),
      S.get('companion_flow_step_dua'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= step.index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 3,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.indigoAccent
                          : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? AppColors.emphasisAccent
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    this.source,
    this.note,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final String? source;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppColors.indigoAccent),
              const SizedBox(height: 14),
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.indigoAccent,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 25,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: colors.onSurface,
                ),
              ),
              if (source != null) ...[
                const SizedBox(height: 14),
                Text(
                  source!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.indigoAccent,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 22),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  height: 1.65,
                  color: colors.onSurface.withValues(alpha: 0.78),
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 18),
                Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
