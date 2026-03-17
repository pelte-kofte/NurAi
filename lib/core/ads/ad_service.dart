import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdService {
  AdService._();

  static bool _isInitialized = false;

  static bool get isPremium => AdConfig.isPremium;
  static bool get isSupportedPlatform => AdConfig.isSupportedPlatform;
  static bool get canRequestAds => _isInitialized && AdConfig.shouldShowAds;

  static String? get bannerAdUnitId {
    return AdConfig.bannerAdUnitId;
  }

  static Future<void> initialize() async {
    if (_isInitialized || !AdConfig.shouldShowAds) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  static BannerAd? createBannerAd({
    required AdSize size,
    required BannerAdListener listener,
  }) {
    final adUnitId = bannerAdUnitId;
    if (!_isInitialized || adUnitId == null) {
      return null;
    }

    return BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: listener,
    );
  }
}
