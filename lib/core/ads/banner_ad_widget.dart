import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/premium_service.dart';
import 'ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.margin = const EdgeInsets.only(top: 16),
  });

  final EdgeInsetsGeometry margin;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    PremiumService.isPremium.addListener(_handlePremiumChanged);
    _loadBanner();
  }

  void _handlePremiumChanged() {
    if (PremiumService.isPremium.value) {
      _disposeBanner();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (_bannerAd == null && !_isLoaded) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (!AdService.canRequestAds) {
      return;
    }

    final banner = AdService.createBannerAd(
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (PremiumService.isPremium.value) {
            ad.dispose();
            return;
          }

          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    if (banner == null) {
      return;
    }

    await banner.load();
  }

  @override
  void dispose() {
    PremiumService.isPremium.removeListener(_handlePremiumChanged);
    _disposeBanner();
    super.dispose();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  Widget build(BuildContext context) {
    if (PremiumService.isPremium.value) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
