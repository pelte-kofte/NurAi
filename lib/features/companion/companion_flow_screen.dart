import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local_preferences_service.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

enum CompanionFlowStep { ayah, pause, dua }

enum CompanionIntent { overwhelmed, decision, gratitude, beforeSleep }

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
    _AyahContent('companion_flow_ayah_7', 'companion_flow_ayah_source_7'),
    _AyahContent('companion_flow_ayah_8', 'companion_flow_ayah_source_8'),
  ];

  CompanionFlowStep _step = CompanionFlowStep.ayah;
  int _ayahIndex = 0;
  CompanionIntent? _intent;

  void _selectIntent(CompanionIntent intent) {
    HapticFeedback.selectionClick();
    setState(() {
      _intent = intent;
      _step = CompanionFlowStep.ayah;
      _ayahIndex = switch (intent) {
        CompanionIntent.overwhelmed => 0,
        CompanionIntent.decision => 6,
        CompanionIntent.gratitude => 7,
        CompanionIntent.beforeSleep => 3,
      };
    });
  }

  String get _duaTitleKey => switch (_intent) {
        CompanionIntent.decision => 'companion_flow_dua_decision',
        CompanionIntent.gratitude => 'companion_flow_dua_gratitude',
        CompanionIntent.beforeSleep => 'companion_flow_dua_sleep',
        _ => 'companion_flow_dua_title',
      };

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
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ayah = _ayahs[_ayahIndex];
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(S.get('companion_flow_close')),
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
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin:
                          reduceMotion ? Offset.zero : const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _intent == null
                    ? _CompanionIntentPicker(
                        key: const ValueKey('intent-picker'),
                        onSelected: _selectIntent,
                      )
                    : SingleChildScrollView(
                        key: ValueKey(_step),
                        padding: const EdgeInsets.fromLTRB(24, 34, 24, 18),
                        child: switch (_step) {
                          CompanionFlowStep.ayah => _CompanionCard(
                              step: CompanionFlowStep.ayah,
                              eyebrow:
                                  S.get('companion_flow_content_type_ayah'),
                              title: S.get(ayah.textKey),
                              source: S.get(ayah.sourceKey),
                              body: S.get('companion_flow_ayah_prompt'),
                            ),
                          CompanionFlowStep.pause => _CompanionCard(
                              step: CompanionFlowStep.pause,
                              eyebrow: '',
                              title: S.get('companion_flow_pause_title'),
                              body: S.get('companion_flow_pause_body'),
                            ),
                          CompanionFlowStep.dua => _CompanionCard(
                              step: CompanionFlowStep.dua,
                              eyebrow: S.get('companion_flow_content_type_dua'),
                              title: S.get(_duaTitleKey),
                              body: S.get('companion_flow_dua_body'),
                              note: S.get('companion_flow_dua_note'),
                            ),
                        },
                      ),
              ),
            ),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              child: _intent == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('companion-cta'),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _step == CompanionFlowStep.dua
                              ? _finish
                              : _continue,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.medium,
                              ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionIntentPicker extends StatefulWidget {
  const _CompanionIntentPicker({super.key, required this.onSelected});

  final ValueChanged<CompanionIntent> onSelected;

  @override
  State<_CompanionIntentPicker> createState() => _CompanionIntentPickerState();
}

class _CompanionIntentPickerState extends State<_CompanionIntentPicker> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = <(CompanionIntent, String)>[
      (
        CompanionIntent.overwhelmed,
        'companion_intent_overwhelmed',
      ),
      (
        CompanionIntent.decision,
        'companion_intent_decision',
      ),
      (
        CompanionIntent.gratitude,
        'companion_intent_gratitude',
      ),
      (
        CompanionIntent.beforeSleep,
        'companion_intent_sleep',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('companion_intent_title'),
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 28,
              height: 1.25,
              color: colors.onSurface,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 250,
            child: Semantics(
              label: S.get('companion_intent_title'),
              child: CupertinoPicker(
                itemExtent: 64,
                diameterRatio: 1.35,
                squeeze: 1,
                useMagnifier: true,
                magnification: 1.04,
                selectionOverlay: Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: colors.onSurface.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
                onSelectedItemChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedIndex = index);
                },
                children: List.generate(options.length, (index) {
                  final selected = index == _selectedIndex;
                  return Center(
                    child: Text(
                      S.get(options[index].$2),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: selected ? 20 : 17,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: colors.onSurface.withValues(
                          alpha: selected ? 1 : 0.42,
                        ),
                        height: 1.2,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => widget.onSelected(options[_selectedIndex].$1),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
              ),
              child: Text(
                S.get('continue'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({
    required this.step,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.source,
    this.note,
  });

  final CompanionFlowStep step;
  final String eyebrow;
  final String title;
  final String body;
  final String? source;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPause = step == CompanionFlowStep.pause;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isPause ? 12 : 24,
            isPause ? 54 : 30,
            isPause ? 12 : 24,
            isPause ? 54 : 28,
          ),
          child: Column(
            children: [
              if (eyebrow.isNotEmpty) ...[
                Text(
                  eyebrow,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface.withValues(alpha: 0.56),
                  ),
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isPause ? 28 : 25,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: colors.onSurface,
                ),
              ),
              if (source != null) ...[
                const SizedBox(height: 14),
                Text(
                  source!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
              SizedBox(height: isPause ? 32 : 24),
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
