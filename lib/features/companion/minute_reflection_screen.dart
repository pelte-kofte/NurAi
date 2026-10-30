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
      _sessionItems = ReflectionItemsService.pickDailySessionItems(
        items,
        date: DateTime.now(),
        count: _sessionItemCount,
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
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
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
      backgroundColor: AppColors.scaffoldBg,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.scaffoldBg,
                        AppColors.cardBgSoft,
                      ],
                    ),
                  ),
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
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.025, 0),
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
                            onRestart: _restart,
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
    required this.colorScheme,
  });

  final bool started;
  final ReflectionItem reflection;
  final VoidCallback onStart;
  final VoidCallback onNextReflection;
  final int currentStepRemainingSeconds;
  final int currentReflectionIndex;
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
                  GestureDetector(
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
                            '${reflection.type}_${reflection.arabic}_${localized.guidance}',
                          ),
                          reflection: reflection,
                          localized: localized,
                          colorScheme: colorScheme,
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
    return Row(
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
    required this.onEnableReminder,
    required this.isEnablingReminder,
  });

  final VoidCallback onDone;
  final VoidCallback onRestart;
  final Future<void> Function() onEnableReminder;
  final bool isEnablingReminder;

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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.72, end: 1),
                    duration: const Duration(milliseconds: 680),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.ctaSecondaryFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 32,
                        color: AppColors.emphasisAccent,
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
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        LocalPreferencesService.spiritualNotificationsEnabled,
                    builder: (context, enabled, _) {
                      if (enabled) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: _ReflectionPrimaryButton(
                            label: isEnablingReminder
                                ? S.get('minute_reflection_reminder_loading')
                                : S.get('minute_reflection_enable_reminder'),
                            onPressed: () => unawaited(onEnableReminder()),
                            enabled: !isEnablingReminder,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
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
                      onPressed: onRestart,
                      child: Text(
                        S.get('minute_reflection_finish_repeat'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
