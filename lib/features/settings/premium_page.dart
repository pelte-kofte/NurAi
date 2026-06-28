import 'package:flutter/material.dart';

import '../../data/premium_service.dart';
import '../home/today_screen.dart';
import '../ramadan/ramadan_hub_screen.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/app_cta_button.dart';
import '../../widgets/premium_experience_widgets.dart';
import 'settings_screen.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  static const Color _premiumPrimary = Color(0xFF2F6B57);
  static const Color _premiumSecondary = Color(0xFF7EA08C);
  static const Color _premiumGlow = Color(0xFFF0E4C8);
  static const Color _premiumInk = Color(0xFF314744);
  static const String _premiumHeroBgAsset =
      'assets/images/home_cards/guide_card_bg.PNG';

  @override
  void initState() {
    super.initState();
    PremiumService.loadProducts();
    PremiumService.activationSuccessRevision
        .addListener(_handlePremiumActivationSuccess);
  }

  @override
  void dispose() {
    PremiumService.activationSuccessRevision
        .removeListener(_handlePremiumActivationSuccess);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardDecoration = BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.07),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.get('premium_app_title')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ValueListenableBuilder<bool>(
            valueListenable: PremiumService.isPremium,
            builder: (context, isPremium, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: PremiumService.isLoading,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: PremiumService.isProductLoading,
                    builder: (context, isProductLoading, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: PremiumService.showProductRetryAction,
                        builder: (context, showProductRetryAction, _) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: PremiumService.errorMessage,
                            builder: (context, errorMessage, _) {
                              return ValueListenableBuilder(
                                valueListenable: PremiumService.productNotifier,
                                builder: (context, product, _) {
                                  return ListView(
                                    children: [
                                      _buildHeroSection(
                                        isPremium: isPremium,
                                        productPrice: product?.price,
                                      ),
                                      const SizedBox(height: 24),
                                      if (isPremium) ...[
                                        const PremiumActiveCard(),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildTierComparisonCard(cardDecoration),
                                      const SizedBox(height: 24),
                                      if (isPremium)
                                        _buildStatusCard(
                                          cardDecoration,
                                          text: S.get('premium_active'),
                                        )
                                      else if (product != null)
                                        _buildProductCard(
                                          cardDecoration,
                                          title:
                                              S.get('premium_membership_label'),
                                          price: product.price,
                                        )
                                      else
                                        _buildLoadingCard(cardDecoration),
                                      if (errorMessage != null &&
                                          product != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          errorMessage,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: colorScheme.error,
                                          ),
                                        ),
                                      ],
                                      if (!isPremium &&
                                          product == null &&
                                          showProductRetryAction &&
                                          !isProductLoading) ...[
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed:
                                              PremiumService.loadProducts,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 36),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child:
                                              Text(S.get('premium_try_again')),
                                        ),
                                      ],
                                      const SizedBox(height: 28),
                                      if (isLoading)
                                        const Center(
                                          child: Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 16),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _premiumSecondary
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 24,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: AppCtaButton(
                                            label: _ctaLabel(context),
                                            fullWidth: true,
                                            onPressed: isPremium ||
                                                    isLoading ||
                                                    isProductLoading ||
                                                    product == null
                                                ? null
                                                : PremiumService.buyMonthly,
                                            textStyle: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: Text(
                                          S.get('premium_cta_context'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.72),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: Text(
                                          _trustLine(context),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.62),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : PremiumService.restorePurchases,
                                          child: Text(
                                            S.get('premium_restore_purchases'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _handlePremiumActivationSuccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      final revision = PremiumService.activationSuccessRevision.value;
      if (!PremiumService.markActivationSuccessPresented(revision)) return;
      await _showPremiumSuccessSheet();
    });
  }

  Future<void> _showPremiumSuccessSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => PremiumSuccessSheet(
        onManageNotifications: () {
          Navigator.of(sheetContext).pop();
          _openSettingsPage();
        },
        onOpenNightGuidance: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TodayScreen(
                intent: TodayScreenIntent.beforeSleep,
              ),
            ),
          );
        },
        onViewProgress: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RamadanHubScreen()),
          );
        },
      ),
    );
  }

  void _openSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(S.get('settings'))),
          body: const SafeArea(child: SettingsScreen()),
        ),
      ),
    );
  }

  Widget _buildHeroSection({
    required bool isPremium,
    required String? productPrice,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _premiumSecondary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _premiumHeroBgAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.76,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFFF7F0E4).withValues(alpha: 0.92),
                                const Color(0xFFF7F0E4).withValues(alpha: 0.78),
                                const Color(0xFFF7F0E4).withValues(alpha: 0.40),
                                const Color(0xFFF7F0E4).withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.38, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.62,
                        heightFactor: 0.62,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-0.78, -0.64),
                              radius: 1.08,
                              colors: [
                                const Color(0xFF2B4038).withValues(alpha: 0.20),
                                const Color(0xFF2B4038).withValues(alpha: 0.10),
                                const Color(0xFF2B4038).withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.48, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.03,
                      child: Image.asset(
                        fit: BoxFit.cover,
                        _premiumHeroBgAsset,
                        alignment: Alignment.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -26,
            right: -12,
            child: IgnorePointer(
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _premiumGlow.withValues(alpha: 0.8),
                      _premiumGlow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -18,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      _premiumSecondary.withValues(alpha: 0.24),
                      _premiumSecondary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 26,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 0.22,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 84,
            left: 18,
            right: 22,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: CustomPaint(
                  size: const Size(double.infinity, 80),
                  painter: _PremiumTexturePainter(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    S.get('premium_title'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _premiumPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  S.get('premium_hero_title'),
                  style: const TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 31,
                    fontWeight: FontWeight.w400,
                    color: _premiumInk,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        color: Color(0x38212E29),
                        blurRadius: 16,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  S.get('premium_hero_subtitle'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: mutedTextColor,
                    height: 1.6,
                    shadows: const [
                      Shadow(
                        color: Color(0x30212E29),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  S.get('premium_social_proof'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: mutedTextColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        icon: isPremium
                            ? Icons.verified_rounded
                            : Icons.auto_awesome_rounded,
                        title: isPremium
                            ? S.get('premium_active')
                            : S.get('premium_membership_label'),
                        value: isPremium
                            ? S.get('premium_status_active')
                            : (productPrice ??
                                S.get('premium_subscription_loading')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.nightlight_round,
                        title: S.get('premium_focus_title'),
                        value: S.get('premium_focus_value'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierComparisonCard(BoxDecoration cardDecoration) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.get('premium_compare_title'),
            style: TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.get('premium_compare_subtitle'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.68),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SizedBox(
                  height: 214,
                  child: _TierColumn(
                    title: S.get('premium_compare_free_title'),
                    rows: [
                      S.get('premium_compare_free_notifications'),
                      S.get('premium_compare_free_tasbih'),
                      S.get('premium_compare_free_focus'),
                    ],
                    highlighted: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 214,
                  child: _TierColumn(
                    title: S.get('premium_compare_premium_title'),
                    rows: [
                      S.get('premium_compare_premium_notifications'),
                      S.get('premium_compare_premium_tasbih'),
                      S.get('premium_compare_premium_focus'),
                    ],
                    highlighted: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BoxDecoration cardDecoration,
      {required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration.copyWith(
        color: _premiumPrimary.withValues(alpha: 0.10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _premiumPrimary,
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BoxDecoration cardDecoration, {
    required String title,
    required String price,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _premiumGlow.withValues(alpha: 0.34),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.66),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              fontFamily: 'Merriweather',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: _premiumPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.get('premium_cancel_anytime'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BoxDecoration cardDecoration) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Text(
        S.get('premium_subscription_loading'),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  String _ctaLabel(BuildContext context) {
    return S.get('premium_cta_soft');
  }

  String _trustLine(BuildContext context) {
    return S.get('premium_cancel_anytime');
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _PremiumPageState._premiumPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: _PremiumPageState._premiumPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        _PremiumPageState._premiumInk.withValues(alpha: 0.58),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _PremiumPageState._premiumPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierColumn extends StatelessWidget {
  const _TierColumn({
    required this.title,
    required this.rows,
    required this.highlighted,
  });

  final String title;
  final List<String> rows;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? _PremiumPageState._premiumPrimary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? _PremiumPageState._premiumPrimary.withValues(alpha: 0.18)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlighted
                  ? _PremiumPageState._premiumPrimary
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            highlighted
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                            size: 15,
                            color: highlighted
                                ? _PremiumPageState._premiumPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rows[index],
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.78,
                              ),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != rows.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _PremiumPageState._premiumSecondary.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final firstPath = Path()
      ..moveTo(0, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.05,
        size.width * 0.48,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.54,
        size.width,
        size.height * 0.18,
      );

    final secondPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.64,
        size.width * 0.58,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height,
        size.width * 0.96,
        size.height * 0.72,
      );

    canvas.drawPath(firstPath, paint);
    canvas.drawPath(secondPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
