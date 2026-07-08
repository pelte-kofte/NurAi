import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../data/local_preferences_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../l10n/app_strings.dart';

enum CompanionFlowStep {
  verse,
  breathe,
  dhikr,
}

class CompanionFlowScreen extends StatefulWidget {
  const CompanionFlowScreen({super.key});

  @override
  State<CompanionFlowScreen> createState() => _CompanionFlowScreenState();
}

class _CompanionFlowScreenState extends State<CompanionFlowScreen> {
  static const _dhikrTarget = 33;
  static const _breathingCalligraphyAsset =
      'assets/images/calligraphy/allahu_akbar.svg';
  static const _verseTextKeys = <String>[
    'companion_flow_verse_text_1',
    'companion_flow_verse_text_2',
    'companion_flow_verse_text_3',
    'companion_flow_verse_text_4',
    'companion_flow_verse_text_5',
    'companion_flow_verse_text_6',
    'companion_flow_verse_text_7',
    'companion_flow_verse_text_8',
    'companion_flow_verse_text_9',
    'companion_flow_verse_text_10',
  ];
  static const _dhikrPhraseKeys = <String>[
    'companion_flow_dhikr_phrase_1',
    'companion_flow_dhikr_phrase_2',
    'companion_flow_dhikr_phrase_3',
    'companion_flow_dhikr_phrase_4',
    'companion_flow_dhikr_phrase_5',
    'companion_flow_dhikr_phrase_6',
  ];

  CompanionFlowStep _step = CompanionFlowStep.verse;
  int _dhikrCount = 0;
  int _verseIndex = 0;
  int _dhikrPhraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNextVerse();
    _loadNextDhikrPhrase();
  }

  Future<void> _loadNextDhikrPhrase() async {
    final nextIndex = await LocalPreferencesService.nextCompanionFlowDhikrIndex(
      totalCount: _dhikrPhraseKeys.length,
    );
    if (!mounted) return;
    setState(() => _dhikrPhraseIndex = nextIndex);
  }

  Future<void> _loadNextVerse() async {
    final nextIndex = await LocalPreferencesService.nextCompanionFlowVerseIndex(
      totalCount: _verseTextKeys.length,
    );
    if (!mounted) return;
    setState(() => _verseIndex = nextIndex);
  }

  void _goToStep(CompanionFlowStep nextStep) {
    setState(() => _step = nextStep);
  }

  Future<void> _finishFlow() async {
    await LocalPreferencesService.markCompanionFlowCompletedToday();
    await SpiritualProgressService.completeReflection(ReflectionPeriod.evening);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _handleTap() {
    switch (_step) {
      case CompanionFlowStep.verse:
        HapticFeedback.selectionClick();
        _goToStep(CompanionFlowStep.breathe);
        return;
      case CompanionFlowStep.breathe:
        HapticFeedback.selectionClick();
        _goToStep(CompanionFlowStep.dhikr);
        return;
      case CompanionFlowStep.dhikr:
        if (_dhikrCount >= _dhikrTarget) return;
        HapticFeedback.lightImpact();
        final nextCount = _dhikrCount + 1;
        setState(() => _dhikrCount = nextCount);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final verseText = S.get(_verseTextKeys[_verseIndex]);
    final currentDhikr = S.get(_dhikrPhraseKeys[_dhikrPhraseIndex]);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.88,
                    child: Image.asset(
                      'assets/images/companion/companion_bg.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.02),
                    radius: 0.82,
                    colors: [
                      Colors.white.withValues(alpha: 0.035),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _CompanionStepContent(
                      key: ValueKey(_step),
                      step: _step,
                      verseText: verseText,
                      dhikrCount: _dhikrCount,
                      targetCount: _dhikrTarget,
                      dhikrLabel: currentDhikr,
                      onFinish: _finishFlow,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionStepContent extends StatelessWidget {
  const _CompanionStepContent({
    super.key,
    required this.step,
    required this.verseText,
    required this.dhikrCount,
    required this.targetCount,
    required this.dhikrLabel,
    required this.onFinish,
  });

  final CompanionFlowStep step;
  final String verseText;
  final int dhikrCount;
  final int targetCount;
  final String dhikrLabel;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (step) {
      case CompanionFlowStep.verse:
        return _CompanionStepFrame(
          title: verseText,
          body: S.get('companion_flow_verse_hint'),
          colorScheme: colorScheme,
        );
      case CompanionFlowStep.breathe:
        return _CompanionBreatheStep(
          title: S.get('companion_flow_breathe_text'),
          body: S.get('companion_flow_breathe_hint'),
          colorScheme: colorScheme,
          calligraphyAsset:
              _CompanionFlowScreenState._breathingCalligraphyAsset,
        );
      case CompanionFlowStep.dhikr:
        return _CompanionDhikrStep(
          title: dhikrLabel,
          body: S.get('companion_flow_dhikr_subtitle'),
          colorScheme: colorScheme,
          dhikrCount: dhikrCount,
          targetCount: targetCount,
          onFinish: onFinish,
        );
    }
  }
}

class _CompanionBreatheStep extends StatefulWidget {
  const _CompanionBreatheStep({
    required this.title,
    required this.body,
    required this.colorScheme,
    required this.calligraphyAsset,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;
  final String calligraphyAsset;

  @override
  State<_CompanionBreatheStep> createState() => _CompanionBreatheStepState();
}

class _CompanionBreatheStepState extends State<_CompanionBreatheStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;
  bool _showCalligraphy = true;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _showCalligraphy = false);
      _breatheController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    );
    final scale = Tween<double>(
      begin: 0.9,
      end: 1.08,
    ).animate(curve);
    final calligraphyOpacity = Tween<double>(
      begin: 0.72,
      end: 0.96,
    ).animate(curve);

    return _CompanionStepFrame(
      title: widget.title,
      body: widget.body,
      colorScheme: widget.colorScheme,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F2E8).withValues(alpha: 0.74),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.92),
                  width: 2.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.22),
                    blurRadius: 22,
                    spreadRadius: 1.5,
                  ),
                  BoxShadow(
                    color: const Color(0xFFDCCDBE).withValues(alpha: 0.26),
                    blurRadius: 26,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: FadeTransition(
                  opacity: calligraphyOpacity,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    opacity: _showCalligraphy ? 0.94 : 1,
                    child: SvgPicture.asset(
                      widget.calligraphyAsset,
                      width: 84,
                      height: 84,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _breatheController,
            builder: (context, child) {
              final inhale = _breatheController.value < 0.5;
              return Text(
                inhale
                    ? S.get('companion_flow_breathe_inhale')
                    : S.get('companion_flow_breathe_exhale'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: widget.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompanionDhikrStep extends StatelessWidget {
  const _CompanionDhikrStep({
    required this.title,
    required this.body,
    required this.colorScheme,
    required this.dhikrCount,
    required this.targetCount,
    required this.onFinish,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;
  final int dhikrCount;
  final int targetCount;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final countLabel = '$dhikrCount/$targetCount';
    return _CompanionStepFrame(
      title: title,
      body: body,
      colorScheme: colorScheme,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            '$dhikrCount',
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 72,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.94),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 22),
          TextButton(
            onPressed: onFinish,
            child: Text(S.get('companion_flow_finish_cta')),
          ),
        ],
      ),
    );
  }
}

class _CompanionStepFrame extends StatelessWidget {
  const _CompanionStepFrame({
    required this.title,
    required this.body,
    required this.colorScheme,
    this.footer,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.97),
              height: 1.42,
              shadows: const [
                Shadow(
                  color: Color(0x1F000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.7,
              shadows: const [
                Shadow(
                  color: Color(0x17000000),
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 42),
            footer!,
          ],
        ],
      ),
    );
  }
}
