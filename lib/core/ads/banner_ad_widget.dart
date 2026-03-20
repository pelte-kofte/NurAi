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
  String? _lastBuildLog;

  void _log(String message) {
    assert(() {
      // Keep banner diagnostics in debug builds only.
      // ignore: avoid_print
      print('[BannerAdWidget] $message');
      return true;
    }());
  }

  @override
  void initState() {
    super.initState();
    _log('initState: premium=${PremiumService.isPremium.value}');
    PremiumService.isPremium.addListener(_handlePremiumChanged);
    _loadBanner();
  }

  void _handlePremiumChanged() {
    _log('premium changed: premium=${PremiumService.isPremium.value}');
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
    _log(
      'loadBanner requested: '
      'premium=${PremiumService.isPremium.value} '
      'canRequestAds=${AdService.canRequestAds}',
    );
    if (!AdService.canRequestAds) {
      _log('loadBanner aborted because ads cannot be requested.');
      return;
    }

    final banner = AdService.createBannerAd(
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final bannerAd = ad as BannerAd;
          _log(
            'onAdLoaded: premium=${PremiumService.isPremium.value} '
            'size=${bannerAd.size.width}x${bannerAd.size.height}',
          );
          if (PremiumService.isPremium.value) {
            bannerAd.dispose();
            return;
          }

          if (!mounted) {
            bannerAd.dispose();
            return;
          }

          setState(() {
            _bannerAd = bannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          _log(
            'onAdFailedToLoad: '
            'code=${error.code} '
            'message=${error.message} '
            'domain=${error.domain} '
            'responseInfo=${error.responseInfo}',
          );
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
      _log('loadBanner aborted because createBannerAd returned null.');
      return;
    }

    _log(
      'banner created: '
      'adUnitId=${banner.adUnitId} '
      'size=${banner.size.width}x${banner.size.height}',
    );
    await banner.load();
    _log('banner.load() invoked.');
  }

  @override
  void dispose() {
    _log('dispose');
    PremiumService.isPremium.removeListener(_handlePremiumChanged);
    _disposeBanner();
    super.dispose();
  }

  void _disposeBanner() {
    _log('disposeBanner: hasBanner=${_bannerAd != null} isLoaded=$_isLoaded');
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final buildLog = 'build: premium=${PremiumService.isPremium.value} '
        'isLoaded=$_isLoaded '
        'hasBanner=${_bannerAd != null}';
    if (_lastBuildLog != buildLog) {
      _log(buildLog);
      _lastBuildLog = buildLog;
    }

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
