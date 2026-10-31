import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppCtaLevel { primary, secondary, tertiary }

class AppCtaButton extends StatefulWidget {
  const AppCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.level = AppCtaLevel.primary,
    this.leading,
    this.fullWidth = false,
    this.compact = false,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppCtaLevel level;
  final Widget? leading;
  final bool fullWidth;
  final bool compact;
  final TextStyle? textStyle;

  @override
  State<AppCtaButton> createState() => _AppCtaButtonState();
}

class _AppCtaButtonState extends State<AppCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(widget.compact ? 14 : 18);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = (widget.textStyle ??
            TextStyle(
              fontFamily: 'Inter',
              fontSize: widget.compact ? 12.5 : 14,
              fontWeight: widget.level == AppCtaLevel.tertiary
                  ? FontWeight.w500
                  : FontWeight.w600,
              color: _foregroundColor(colorScheme, enabled),
            ))
        .copyWith(color: _foregroundColor(colorScheme, enabled));

    final child = AnimatedScale(
      scale: _pressed && enabled ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _decoration(colorScheme, radius, enabled),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: radius,
            splashColor: _overlayColor(colorScheme, enabled),
            highlightColor: _overlayColor(colorScheme, enabled).withValues(
              alpha: enabled ? 0.08 : 0,
            ),
            overlayColor: WidgetStatePropertyAll(
              _overlayColor(colorScheme, enabled),
            ),
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel:
                enabled ? () => setState(() => _pressed = false) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            child: Padding(
              padding: widget.level == AppCtaLevel.tertiary
                  ? EdgeInsets.symmetric(
                      horizontal: widget.compact ? 6 : 12,
                      vertical: widget.compact ? 4 : 8,
                    )
                  : EdgeInsets.symmetric(
                      horizontal: widget.compact ? 12 : 18,
                      vertical: widget.compact ? 10 : 15,
                    ),
              child: Row(
                mainAxisSize:
                    widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.leading != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: widget.compact ? 16 : 18,
                        color: _foregroundColor(colorScheme, enabled),
                      ),
                      child: widget.leading!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.fullWidth) return child;
    return SizedBox(width: double.infinity, child: child);
  }

  BoxDecoration _decoration(
    ColorScheme colorScheme,
    BorderRadius radius,
    bool enabled,
  ) {
    switch (widget.level) {
      case AppCtaLevel.primary:
        return BoxDecoration(
          borderRadius: radius,
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.ctaPrimaryStart,
                    AppColors.ctaPrimaryEnd,
                  ],
                )
              : LinearGradient(
                  colors: [
                    colorScheme.outline.withValues(alpha: 0.3),
                    colorScheme.outline.withValues(alpha: 0.4),
                  ],
                ),
          boxShadow: enabled
              ? [
                  const BoxShadow(
                    color: AppColors.ctaShadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        );
      case AppCtaLevel.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: enabled
              ? AppColors.ctaSecondaryFill
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          border: Border.all(
            color: enabled
                ? AppColors.ctaSecondaryBorder
                : colorScheme.outline.withValues(alpha: 0.35),
          ),
        );
      case AppCtaLevel.tertiary:
        return const BoxDecoration();
    }
  }

  Color _foregroundColor(ColorScheme colorScheme, bool enabled) {
    if (!enabled) {
      return colorScheme.onSurface.withValues(alpha: 0.42);
    }
    switch (widget.level) {
      case AppCtaLevel.primary:
        return AppColors.ctaPrimaryText;
      case AppCtaLevel.secondary:
      case AppCtaLevel.tertiary:
        return AppColors.indigoAccent;
    }
  }

  Color _overlayColor(ColorScheme colorScheme, bool enabled) {
    if (!enabled) return Colors.transparent;
    switch (widget.level) {
      case AppCtaLevel.primary:
        return Colors.white.withValues(alpha: 0.08);
      case AppCtaLevel.secondary:
        return AppColors.indigoAccent.withValues(alpha: 0.08);
      case AppCtaLevel.tertiary:
        return AppColors.indigoAccent.withValues(alpha: 0.06);
    }
  }
}
