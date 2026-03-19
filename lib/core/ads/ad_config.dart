import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/premium_service.dart';

class AdConfig {
  AdConfig._();

  static const String _iosBannerAdUnitId =
      'ca-app-pub-6544023803448612/5970962924';

  static bool get isPremium => PremiumService.isPremium.value;
  static bool get isSupportedPlatform => !kIsWeb && Platform.isIOS;
  static bool get shouldShowAds => !isPremium && isSupportedPlatform;

  static String? get bannerAdUnitId {
    if (!shouldShowAds) {
      return null;
    }

    return _iosBannerAdUnitId;
  }
}
