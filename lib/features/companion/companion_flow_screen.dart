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
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              child: _intent == null
                  ? const SizedBox(height: 32, key: ValueKey('intent-space'))
                  : _StepIndicator(
                      key: const ValueKey('step-indicator'),
                      step: _step,
                    ),
            ),
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
                              icon: Icons.menu_book_rounded,
                            ),
                          CompanionFlowStep.pause => _CompanionCard(
                              step: CompanionFlowStep.pause,
                              eyebrow: S.get('companion_flow_step_pause'),
                              title: S.get('companion_flow_pause_title'),
                              body: S.get('companion_flow_pause_body'),
                              icon: Icons.hourglass_bottom_rounded,
                            ),
                          CompanionFlowStep.dua => _CompanionCard(
                              step: CompanionFlowStep.dua,
                              eyebrow: S.get('companion_flow_content_type_dua'),
                              title: S.get(_duaTitleKey),
                              body: S.get('companion_flow_dua_body'),
                              note: S.get('companion_flow_dua_note'),
                              icon: Icons.volunteer_activism_rounded,
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

class _CompanionIntentPicker extends StatelessWidget {
  const _CompanionIntentPicker({super.key, required this.onSelected});

  final ValueChanged<CompanionIntent> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final options = <(CompanionIntent, IconData, String, String)>[
      (
        CompanionIntent.overwhelmed,
        Icons.blur_on_rounded,
        'companion_intent_overwhelmed',
        'companion_intent_overwhelmed_subtitle',
      ),
      (
        CompanionIntent.decision,
        Icons.alt_route_rounded,
        'companion_intent_decision',
        'companion_intent_decision_subtitle',
      ),
      (
        CompanionIntent.gratitude,
        Icons.favorite_outline_rounded,
        'companion_intent_gratitude',
        'companion_intent_gratitude_subtitle',
      ),
      (
        CompanionIntent.beforeSleep,
        Icons.bedtime_outlined,
        'companion_intent_sleep',
        'companion_intent_sleep_subtitle',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
          const SizedBox(height: 10),
          Text(
            S.get('companion_intent_subtitle'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.5,
              color: colors.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(options.length, (index) {
            final option = options[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : Duration(milliseconds: 260 + index * 45),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset:
                      reduceMotion ? Offset.zero : Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IntentTile(
                  icon: option.$2,
                  title: S.get(option.$3),
                  subtitle: S.get(option.$4),
                  dividerColor: colors.outline.withValues(alpha: 0.42),
                  onTap: () => onSelected(option.$1),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _IntentTile extends StatefulWidget {
  const _IntentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dividerColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color dividerColor;
  final VoidCallback onTap;

  @override
  State<_IntentTile> createState() => _IntentTileState();
}

class _IntentTileState extends State<_IntentTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: widget.title,
      hint: widget.subtitle,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: widget.dividerColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryContainer,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            height: 1.4,
                            color: colors.onSurface.withValues(alpha: 0.66),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurface.withValues(alpha: 0.38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({super.key, required this.step});

  final CompanionFlowStep step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    height: 3,
                    decoration: BoxDecoration(
                      color: active
                          ? colors.primary
                          : colors.outline.withValues(alpha: 0.45),
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
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.46),
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
    required this.step,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    this.source,
    this.note,
  });

  final CompanionFlowStep step;
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final String? source;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPause = step == CompanionFlowStep.pause;
    final isDua = step == CompanionFlowStep.dua;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isPause ? 12 : 24,
            isPause ? 54 : 30,
            isPause ? 12 : 24,
            isPause ? 54 : 28,
          ),
          decoration: BoxDecoration(
            color: isPause
                ? Colors.transparent
                : isDua
                    ? colors.primaryContainer.withValues(alpha: 0.42)
                    : colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: isPause || !isDua
                ? null
                : Border.all(color: colors.primary.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              if (!isPause) ...[
                Icon(icon, size: 22, color: colors.primary),
                const SizedBox(height: 14),
              ],
              Text(
                eyebrow.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: isPause ? 34 : 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: isPause ? 30 : 25,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
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
              if (!isPause) ...[
                Divider(
                  height: 1,
                  color: colors.outline.withValues(alpha: 0.42),
                ),
                const SizedBox(height: 22),
              ],
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
