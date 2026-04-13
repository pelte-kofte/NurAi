import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local_preferences_service.dart';
import '../../l10n/app_strings.dart';

enum CompanionFlowStep {
  verse,
  breathe,
  dhikr,
  finish,
}

class CompanionFlowScreen extends StatefulWidget {
  const CompanionFlowScreen({super.key});

  @override
  State<CompanionFlowScreen> createState() => _CompanionFlowScreenState();
}

class _CompanionFlowScreenState extends State<CompanionFlowScreen> {
  static const _verseDelay = Duration(seconds: 5);
  static const _dhikrTarget = 33;
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
  static const _dhikrPhrases = <String>[
    'Subhanallah',
    'Elhamdülillah',
    'Allahu Ekber',
  ];

  CompanionFlowStep _step = CompanionFlowStep.verse;
  Timer? _verseTimer;
  int _dhikrCount = 0;
  bool _verseStepCompleted = false;
  int _verseIndex = 0;
  int _dhikrPhraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _startVerseTimer();
    _loadNextVerse();
    _loadNextDhikrPhrase();
  }

  @override
  void dispose() {
    _verseTimer?.cancel();
    super.dispose();
  }

  void _startVerseTimer() {
    _verseTimer?.cancel();
    _verseStepCompleted = false;
    _verseTimer = Timer(_verseDelay, () {
      if (!mounted) return;
      _completeVerseStep();
    });
  }

  Future<void> _loadNextDhikrPhrase() async {
    final nextIndex = await LocalPreferencesService.nextCompanionFlowDhikrIndex(
      totalCount: _dhikrPhrases.length,
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
    _verseTimer?.cancel();
    if (nextStep == CompanionFlowStep.finish && _step != CompanionFlowStep.finish) {
      LocalPreferencesService.markCompanionFlowCompletedToday();
    }
    setState(() => _step = nextStep);
  }

  void _completeVerseStep() {
    if (_step != CompanionFlowStep.verse || _verseStepCompleted) return;
    _verseStepCompleted = true;
    _verseTimer?.cancel();
    _goToStep(CompanionFlowStep.breathe);
  }

  void _handleTap() {
    switch (_step) {
      case CompanionFlowStep.verse:
        _completeVerseStep();
        return;
      case CompanionFlowStep.breathe:
        _goToStep(CompanionFlowStep.dhikr);
        return;
      case CompanionFlowStep.dhikr:
        if (_dhikrCount >= _dhikrTarget) return;
        HapticFeedback.lightImpact();
        final nextCount = _dhikrCount + 1;
        setState(() => _dhikrCount = nextCount);
        if (nextCount >= _dhikrTarget) {
          Future<void>.delayed(const Duration(milliseconds: 260), () {
            if (!mounted || _step != CompanionFlowStep.dhikr) return;
            _goToStep(CompanionFlowStep.finish);
          });
        }
        return;
      case CompanionFlowStep.finish:
        Navigator.of(context).pop();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final verseTextKey = _CompanionFlowScreenState._verseTextKeys[_verseIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1.08,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                  child: Image.asset(
                    'assets/images/mosque_bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 650),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      final scale = Tween<double>(
                        begin: 0.97,
                        end: 1,
                      ).animate(fade);
                      return FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: _CompanionStepContent(
                      key: ValueKey(_step),
                      step: _step,
                      verseText: S.get(verseTextKey),
                      dhikrPhraseIndex: _dhikrPhraseIndex,
                      dhikrCount: _dhikrCount,
                      onFinishDhikr: () => _goToStep(CompanionFlowStep.finish),
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
    required this.dhikrPhraseIndex,
    required this.dhikrCount,
    required this.onFinishDhikr,
  });

  final CompanionFlowStep step;
  final String verseText;
  final int dhikrPhraseIndex;
  final int dhikrCount;
  final VoidCallback onFinishDhikr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentDhikr =
        _CompanionFlowScreenState._dhikrPhrases[dhikrPhraseIndex];

    switch (step) {
      case CompanionFlowStep.verse:
        return _CompanionVerseStep(
          title: verseText,
          body: S.get('companion_flow_verse_hint'),
          colorScheme: colorScheme,
        );
      case CompanionFlowStep.breathe:
        return _CompanionBreatheStep(
          title: S.get('companion_flow_breathe_text'),
          body: S.get('companion_flow_breathe_hint'),
          colorScheme: colorScheme,
        );
      case CompanionFlowStep.dhikr:
        return _CompanionDhikrStep(
          title: S.get('companion_flow_dhikr_text'),
          body: S
              .get('companion_flow_dhikr_hint_dynamic')
              .replaceAll('{dhikr}', currentDhikr),
          colorScheme: colorScheme,
          dhikrCount: dhikrCount,
          targetCount: _CompanionFlowScreenState._dhikrTarget,
          dhikrLabel: currentDhikr,
          onFinishDhikr: onFinishDhikr,
        );
      case CompanionFlowStep.finish:
        return _CompanionStepFrame(
          title: S.get('companion_flow_finish_title'),
          body: S.get('companion_flow_finish_body'),
          colorScheme: colorScheme,
          footer: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.get('companion_flow_close')),
            ),
          ),
        );
    }
  }
}

class _CompanionVerseStep extends StatefulWidget {
  const _CompanionVerseStep({
    required this.title,
    required this.body,
    required this.colorScheme,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;

  @override
  State<_CompanionVerseStep> createState() => _CompanionVerseStepState();
}

class _CompanionVerseStepState extends State<_CompanionVerseStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: fade,
      child: _CompanionStepFrame(
        title: widget.title,
        body: widget.body,
        colorScheme: widget.colorScheme,
      ),
    );
  }
}

class _CompanionBreatheStep extends StatefulWidget {
  const _CompanionBreatheStep({
    required this.title,
    required this.body,
    required this.colorScheme,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;

  @override
  State<_CompanionBreatheStep> createState() => _CompanionBreatheStepState();
}

class _CompanionBreatheStepState extends State<_CompanionBreatheStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 0.9,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOut,
      ),
    );

    return _CompanionStepFrame(
      title: widget.title,
      body: widget.body,
      colorScheme: widget.colorScheme,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
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
                  color: widget.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompanionDhikrStep extends StatefulWidget {
  const _CompanionDhikrStep({
    required this.title,
    required this.body,
    required this.colorScheme,
    required this.dhikrCount,
    required this.targetCount,
    required this.dhikrLabel,
    required this.onFinishDhikr,
  });

  final String title;
  final String body;
  final ColorScheme colorScheme;
  final int dhikrCount;
  final int targetCount;
  final String dhikrLabel;
  final VoidCallback onFinishDhikr;

  @override
  State<_CompanionDhikrStep> createState() => _CompanionDhikrStepState();
}

class _CompanionDhikrStepState extends State<_CompanionDhikrStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.dhikrCount;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _CompanionDhikrStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dhikrCount != _lastCount) {
      _lastCount = widget.dhikrCount;
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 1,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    return _CompanionStepFrame(
      title: widget.title,
      body: widget.body,
      colorScheme: widget.colorScheme,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          Text(
            widget.dhikrLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: widget.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 14),
          ScaleTransition(
            scale: scale,
            child: Text(
              '${widget.dhikrCount}',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 84,
                fontWeight: FontWeight.w400,
                color: widget.colorScheme.onSurface.withValues(alpha: 0.96),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${widget.dhikrCount}/${widget.targetCount}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: widget.onFinishDhikr,
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
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.995),
              height: 1.45,
              shadows: const [
                Shadow(
                  color: Color(0x42000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.86),
              height: 1.8,
              shadows: const [
                Shadow(
                  color: Color(0x16000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 44),
            footer!,
          ],
        ],
      ),
    );
  }
}
