import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/adhan_notification_service.dart';
import '../../data/local_preferences_service.dart';
import '../../data/reflection_items_service.dart';
import '../../data/spiritual_progress_service.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class MinuteReflectionScreen extends StatefulWidget {
  const MinuteReflectionScreen({super.key});

  @override
  State<MinuteReflectionScreen> createState() => _MinuteReflectionScreenState();
}

class _MinuteReflectionScreenState extends State<MinuteReflectionScreen> {
  static const _reflectionStepSeconds = 20;
  static const _sessionItemCount = 3;
  static const _minimumStepSeconds = 15;

  Timer? _timer;
  int _currentStepRemainingSeconds = _reflectionStepSeconds;
  bool _started = false;
  bool _completed = false;
  bool _isEnablingReminder = false;
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
      final dailyItem = ReflectionItemsService.pickDailySessionItems(
        items,
        date: DateTime.now(),
        count: 1,
      ).first;
      _sessionItems = List<ReflectionItem>.filled(_sessionItemCount, dailyItem);
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
    await SpiritualProgressService.completeReflection(ReflectionPeriod.evening);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() {
      _currentStepRemainingSeconds = 0;
      _completed = true;
      _started = false;
    });
  }

  Future<void> _enableDailyReminder() async {
    if (_isEnablingReminder) return;
    setState(() => _isEnablingReminder = true);
    try {
      final granted = await AdhanNotificationService.requestPermissions();
      if (!granted || !mounted) return;
      final picked = await showTimePicker(
        context: context,
        initialTime: LocalPreferencesService.dailyReminderTime.value,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child,
          );
        },
      );
      if (picked == null) return;
      await LocalPreferencesService.setDailyReminderTime(picked);
      await LocalPreferencesService.setSpiritualNotificationsEnabled(true);
      await AdhanNotificationService.syncSpiritualNotifications();
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _isEnablingReminder = false);
    }
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
    final elapsed = _reflectionStepSeconds - _currentStepRemainingSeconds;
    if (elapsed < _minimumStepSeconds) return;
    unawaited(_advanceToNextReflection(fromAutoAdvance: false));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surfaceContainerHighest,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
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
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: reduceMotion
                                ? Offset.zero
                                : const Offset(0.018, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _completed
                        ? _ReflectionCompletionState(
                            key: const ValueKey('completed'),
                            onDone: () => Navigator.of(context).pop(),
                            onEnableReminder: _enableDailyReminder,
                            isEnablingReminder: _isEnablingReminder,
                          )
                        : _ActiveReflectionState(
                            key: ValueKey('active_$_currentReflectionIndex'),
                            started: _started,
                            reflection: _currentReflection(),
                            onStart: _start,
                            onNextReflection: _showNextReflection,
                            currentStepRemainingSeconds:
                                _currentStepRemainingSeconds,
                            currentReflectionIndex: _currentReflectionIndex,
                            canAdvance: _reflectionStepSeconds -
                                    _currentStepRemainingSeconds >=
                                _minimumStepSeconds,
                            colorScheme: colorScheme,
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  tooltip: S.get('close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
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
    required this.currentReflectionIndex,
    required this.canAdvance,
    required this.colorScheme,
  });

  final bool started;
  final ReflectionItem reflection;
  final VoidCallback onStart;
  final VoidCallback onNextReflection;
  final int currentStepRemainingSeconds;
  final int currentReflectionIndex;
  final bool canAdvance;
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
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.96),
                      height: 1.22,
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
                  const SizedBox(height: 24),
                  _ReflectionProgress(
                    currentIndex: currentReflectionIndex,
                    remainingSeconds: currentStepRemainingSeconds,
                    started: started,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: _ReflectionContentView(
                        key: ValueKey(
                          '${reflection.type}_${reflection.arabic}_$currentReflectionIndex',
                        ),
                        reflection: reflection,
                        localized: localized,
                        phaseIndex: currentReflectionIndex,
                        colorScheme: colorScheme,
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
                    Semantics(
                      liveRegion: true,
                      label:
                          '${S.get('minute_reflection_step_progress')} ${currentReflectionIndex + 1} / 3',
                      child: Text(
                        canAdvance
                            ? S.get('minute_reflection_ready_hint')
                            : S.get('minute_reflection_stay_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.56),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedOpacity(
                      opacity: canAdvance ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: IgnorePointer(
                        ignoring: !canAdvance,
                        child: TextButton(
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
                      ),
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

class _ReflectionProgress extends StatelessWidget {
  const _ReflectionProgress({
    required this.currentIndex,
    required this.remainingSeconds,
    required this.started,
  });

  final int currentIndex;
  final int remainingSeconds;
  final bool started;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${S.get('minute_reflection_step_progress')} ${currentIndex + 1} / 3',
      child: ExcludeSemantics(
        child: Row(
          children: List.generate(3, (index) {
            final progress = index < currentIndex
                ? 1.0
                : index > currentIndex
                    ? 0.0
                    : started
                        ? (1 - (remainingSeconds / 20)).clamp(0.0, 1.0)
                        : 0.0;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 3,
                    child: ColoredBox(
                      color: AppColors.cardBorder,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              child: const ColoredBox(
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ReflectionContentView extends StatelessWidget {
  const _ReflectionContentView({
    super.key,
    required this.reflection,
    required this.localized,
    required this.phaseIndex,
    required this.colorScheme,
  });

  final ReflectionItem reflection;
  final ReflectionItemLocale localized;
  final int phaseIndex;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (phaseIndex == 1) {
      return _buildPausePhase();
    }
    if (phaseIndex == 2) {
      return _buildCarryPhase();
    }
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            ),
            child: Text(
              S.get('minute_reflection_phase_read').toUpperCase(),
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
            localized.guidance ??
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

  Widget _buildPausePhase() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.get('minute_reflection_phase_pause').toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localized.guidance ?? S.get('minute_reflection_pause_fallback'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 29,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.94),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 42,
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarryPhase() {
    final primary = switch (reflection.type) {
      'asma' => localized.name ?? '',
      'dhikr' => localized.transliteration ?? '',
      _ => localized.text ?? '',
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.get('minute_reflection_phase_carry').toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            if (_hasValue(reflection.arabic))
              Text(
                reflection.arabic!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                  color: colorScheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              primary,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 26,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              S.get('minute_reflection_carry_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                height: 1.6,
                color: colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              disabledBackgroundColor: colorScheme.onSurface.withValues(
                alpha: 0.12,
              ),
              foregroundColor: colorScheme.onPrimary,
              disabledForegroundColor: colorScheme.onSurface.withValues(
                alpha: 0.42,
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
    required this.onEnableReminder,
    required this.isEnablingReminder,
  });

  final VoidCallback onDone;
  final Future<void> Function() onEnableReminder;
  final bool isEnablingReminder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.72, end: 1),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: _ReflectionPrimaryButton(
                      label: S.get('minute_reflection_finish_home'),
                      onPressed: onDone,
                      enabled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        LocalPreferencesService.spiritualNotificationsEnabled,
                    builder: (context, enabled, _) {
                      if (enabled) return const SizedBox.shrink();
                      return TextButton.icon(
                        onPressed: isEnablingReminder
                            ? null
                            : () => unawaited(onEnableReminder()),
                        icon: const Icon(Icons.notifications_none_rounded),
                        label: Text(
                          isEnablingReminder
                              ? S.get('minute_reflection_reminder_loading')
                              : S.get('minute_reflection_enable_reminder'),
                        ),
                      );
                    },
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
