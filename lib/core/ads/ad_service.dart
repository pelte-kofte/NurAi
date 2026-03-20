import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class AdService {
  AdService._();

  static bool _isInitialized = false;

  static void _log(String message) {
    assert(() {
      // Keep ad diagnostics in debug builds only.
      // ignore: avoid_print
      print('[AdService] $message');
      return true;
    }());
  }

  static bool get isPremium => AdConfig.isPremium;
  static bool get isSupportedPlatform => AdConfig.isSupportedPlatform;
  static bool get canRequestAds => _isInitialized && AdConfig.shouldShowAds;

  static String? get bannerAdUnitId {
    return AdConfig.bannerAdUnitId;
  }

  static Future<void> initialize() async {
    _log(
      'initialize requested: '
      'isInitialized=$_isInitialized '
      'isPremium=${AdConfig.isPremium} '
      'isSupportedPlatform=${AdConfig.isSupportedPlatform} '
      'shouldShowAds=${AdConfig.shouldShowAds}',
    );
    if (_isInitialized || !AdConfig.isSupportedPlatform) {
      _log('initialize skipped.');
      return;
    }

    try {
      _log('calling MobileAds.instance.initialize()');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _log('MobileAds initialized successfully.');
    } catch (_) {
      _isInitialized = false;
      _log('MobileAds initialization failed.');
    }
  }

  static BannerAd? createBannerAd({
    required AdSize size,
    required BannerAdListener listener,
  }) {
    final adUnitId = bannerAdUnitId;
    _log(
      'createBannerAd requested: '
      'isInitialized=$_isInitialized '
      'isPremium=${AdConfig.isPremium} '
      'canRequestAds=$canRequestAds '
      'adUnitId=$adUnitId '
      'size=${size.width}x${size.height}',
    );
    if (!_isInitialized || adUnitId == null) {
      _log('createBannerAd returning null.');
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
