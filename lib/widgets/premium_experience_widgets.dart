import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';

class PremiumActiveCard extends StatelessWidget {
  const PremiumActiveCard({
    super.key,
    this.onTap,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final VoidCallback? onTap;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  static const Color _premiumPrimary = Color(0xFF2F6B57);
  static const Color _premiumSecondary = Color(0xFF7EA08C);
  static const Color _premiumInk = Color(0xFF314744);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF7F1E5),
                Color(0xFFE8EFE8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: _premiumSecondary.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _premiumPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.get('premium_active_card_title'),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _premiumPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          S.get('premium_active_card_subtitle'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _premiumInk.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                S.get('premium_active_card_body'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: _premiumInk.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _BenefitPill(
                      label: S.get('premium_active_pill_notifications')),
                  _BenefitPill(label: S.get('premium_active_pill_progress')),
                ],
              ),
              if (primaryActionLabel != null && onPrimaryAction != null) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: onPrimaryAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    foregroundColor: _premiumPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    primaryActionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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

class PremiumSuccessSheet extends StatefulWidget {
  const PremiumSuccessSheet({
    super.key,
    required this.onManageNotifications,
    required this.onOpenNightGuidance,
    required this.onViewProgress,
  });

  final VoidCallback onManageNotifications;
  final VoidCallback onOpenNightGuidance;
  final VoidCallback onViewProgress;

  static const Color _premiumPrimary = Color(0xFF2F6B57);
  static const Color _premiumInk = Color(0xFF314744);

  @override
  State<PremiumSuccessSheet> createState() => _PremiumSuccessSheetState();
}

class _PremiumSuccessSheetState extends State<PremiumSuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scale = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PremiumSuccessSheet._premiumPrimary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: PremiumSuccessSheet._premiumPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.get('premium_success_title'),
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                S.get('premium_success_body'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color:
                      PremiumSuccessSheet._premiumInk.withValues(alpha: 0.76),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const _UnlockedLine(
                  labelKey: 'premium_active_pill_notifications'),
              const SizedBox(height: 8),
              const _UnlockedLine(labelKey: 'premium_active_pill_progress'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onManageNotifications,
                  child: Text(S.get('premium_success_action_notifications')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onViewProgress,
                  child: Text(S.get('premium_success_action_progress')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecommendationPill extends StatelessWidget {
  const RecommendationPill({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: PremiumActiveCard._premiumSecondary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: PremiumActiveCard._premiumInk.withValues(alpha: 0.76),
        ),
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: PremiumActiveCard._premiumPrimary,
        ),
      ),
    );
  }
}

class _UnlockedLine extends StatelessWidget {
  const _UnlockedLine({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: PremiumSuccessSheet._premiumPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: PremiumSuccessSheet._premiumPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            S.get(labelKey),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PremiumSuccessSheet._premiumInk.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
