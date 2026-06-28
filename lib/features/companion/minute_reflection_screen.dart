import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local_preferences_service.dart';
import '../../data/reflection_items_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../l10n/app_strings.dart';

class MinuteReflectionScreen extends StatefulWidget {
  const MinuteReflectionScreen({super.key});

  @override
  State<MinuteReflectionScreen> createState() => _MinuteReflectionScreenState();
}

class _MinuteReflectionScreenState extends State<MinuteReflectionScreen> {
  static const _backgroundAsset = 'assets/images/reflection/reflection_bg.png';
  static const _reflectionStepSeconds = 20;
  static const _sessionItemCount = 3;

  Timer? _timer;
  int _currentStepRemainingSeconds = _reflectionStepSeconds;
  bool _started = false;
  bool _completed = false;
  int _currentReflectionIndex = 0;
  List<ReflectionItem> _sessionItems = ReflectionItemsService.fallbackItems;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSessionItems());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessionItems() async {
    final items = await ReflectionItemsService.loadItems();
    if (!mounted) return;
    setState(() {
      _sessionItems = ReflectionItemsService.pickSessionItems(
        items,
        count: _sessionItemCount,
        random: Random(),
      );
      _currentReflectionIndex = _currentReflectionIndex.clamp(
        0,
        _sessionItems.length - 1,
      );
    });
  }

  Future<void> _start() async {
    if (_started || _completed) return;
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _currentStepRemainingSeconds = _reflectionStepSeconds;
      _currentReflectionIndex = 0;
      _started = true;
      _completed = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_currentStepRemainingSeconds <= 1) {
        await _advanceToNextReflection(fromAutoAdvance: true);
        return;
      }
      setState(() {
        _currentStepRemainingSeconds -= 1;
      });
    });
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await LocalPreferencesService.markReflectionCompletedToday();
    await SpiritualProgressService.completeReflection(ReflectionPeriod.evening);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() {
      _currentStepRemainingSeconds = 0;
      _completed = true;
      _started = false;
    });
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _currentStepRemainingSeconds = _reflectionStepSeconds;
      _started = false;
      _completed = false;
      _currentReflectionIndex = 0;
    });
    unawaited(_loadSessionItems());
    _start();
  }

  ReflectionItem _currentReflection() {
    return _sessionItems[_currentReflectionIndex];
  }

  Future<void> _advanceToNextReflection({required bool fromAutoAdvance}) async {
    if (!_started || _completed) return;
    if (_currentReflectionIndex >= _sessionItems.length - 1) {
      await _complete();
      return;
    }
    if (fromAutoAdvance) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    if (!mounted) return;
    setState(() {
      _currentReflectionIndex += 1;
      _currentStepRemainingSeconds = _reflectionStepSeconds;
    });
  }

  void _showNextReflection() {
    unawaited(_advanceToNextReflection(fromAutoAdvance: false));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.56,
                      child: Image.asset(
                        _backgroundAsset,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.0),
                            const Color(0xFFF4ECE1).withValues(alpha: 0.08),
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
                child: ColoredBox(
                  color: const Color(0xFFF9F2E8).withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _completed
                        ? _ReflectionCompletionState(
                            key: const ValueKey('completed'),
                            onDone: () => Navigator.of(context).pop(),
                            onRestart: _restart,
                          )
                        : _ActiveReflectionState(
                            key: ValueKey('active_$_currentReflectionIndex'),
                            started: _started,
                            reflection: _currentReflection(),
                            onStart: _start,
                            onNextReflection: _showNextReflection,
                            currentStepRemainingSeconds:
                                _currentStepRemainingSeconds,
                            colorScheme: colorScheme,
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

class _ActiveReflectionState extends StatelessWidget {
  const _ActiveReflectionState({
    super.key,
    required this.started,
    required this.reflection,
    required this.onStart,
    required this.onNextReflection,
    required this.currentStepRemainingSeconds,
    required this.colorScheme,
  });

  final bool started;
  final ReflectionItem reflection;
  final VoidCallback onStart;
  final VoidCallback onNextReflection;
  final int currentStepRemainingSeconds;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final localized = reflection.localized(languageCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 96,
                minWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    S.get('minute_reflection_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.96),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    S.get('minute_reflection_screen_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: started ? onNextReflection : null,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: _ReflectionContentView(
                            key: ValueKey(
                              '${reflection.type}_${reflection.arabic}_${localized.guidance}',
                            ),
                            reflection: reflection,
                            localized: localized,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!started) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _ReflectionPrimaryButton(
                        label: S.get('minute_reflection_start'),
                        onPressed: onStart,
                        enabled: true,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    Text(
                      '${S.get('minute_reflection_next_hint')} · $currentStepRemainingSeconds${S.get('minute_reflection_seconds_short')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.56),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: onNextReflection,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.76,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(S.get('continue')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReflectionContentView extends StatelessWidget {
  const _ReflectionContentView({
    super.key,
    required this.reflection,
    required this.localized,
    required this.colorScheme,
  });

  final ReflectionItem reflection;
  final ReflectionItemLocale localized;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.34),
              ),
            ),
            child: Text(
              _typeLabel(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ),
          if (_hasValue(reflection.arabic)) ...[
            const SizedBox(height: 26),
            Text(
              reflection.arabic!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: reflection.type == 'asma' ? 34 : 28,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.86),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ..._contentBlocks(),
          const SizedBox(height: 22),
          Text(
            S.get('minute_reflection_item_guidance_timed'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _contentBlocks() {
    switch (reflection.type) {
      case 'ayah':
        return [
          Text(
            localized.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.95),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            localized.source ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.45,
            ),
          ),
        ];
      case 'asma':
        return [
          Text(
            localized.name ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.95),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localized.meaning ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.55,
            ),
          ),
        ];
      case 'dhikr':
        return [
          Text(
            localized.transliteration ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 31,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.95),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localized.meaning ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.55,
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  String _typeLabel() {
    switch (reflection.type) {
      case 'ayah':
        return S.get('minute_reflection_type_ayah');
      case 'dhikr':
        return S.get('minute_reflection_type_dhikr');
      case 'asma':
        return S.get('minute_reflection_type_asma');
      default:
        return '';
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _ReflectionPrimaryButton extends StatefulWidget {
  const _ReflectionPrimaryButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_ReflectionPrimaryButton> createState() =>
      _ReflectionPrimaryButtonState();
}

class _ReflectionPrimaryButtonState extends State<_ReflectionPrimaryButton> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    if (!widget.enabled) return;
    setState(() => _scale = pressed ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEFE6D9),
              disabledBackgroundColor: const Color(0xFFEFE6D9),
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.88),
              disabledForegroundColor: colorScheme.onSurface.withValues(
                alpha: 0.52,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectionCompletionState extends StatelessWidget {
  const _ReflectionCompletionState({
    super.key,
    required this.onDone,
    required this.onRestart,
  });

  final VoidCallback onDone;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 96,
                minWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    S.get('minute_reflection_finish_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.96),
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.get('minute_reflection_finish_subtitle_ui'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    S.get('minute_reflection_finish_today'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 42),
                  SizedBox(
                    width: double.infinity,
                    child: _ReflectionPrimaryButton(
                      label: S.get('minute_reflection_finish_repeat'),
                      onPressed: onRestart,
                      enabled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onDone,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.82,
                        ),
                        side: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        S.get('minute_reflection_finish_home'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
