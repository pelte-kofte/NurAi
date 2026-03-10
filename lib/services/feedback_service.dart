import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/local_preferences_service.dart';

enum FeedbackLaunchResult {
  launched,
  unavailable,
}

class FeedbackService {
  FeedbackService._();

  static const String appName = 'Duaya';
  static const String feedbackEmail = 'nurai@forvibe.app';
  // Fill this with the real App Store app id to enable direct review-page fallback.
  static const String? iosAppStoreId = null;

  static final InAppReview _inAppReview = InAppReview.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<FeedbackLaunchResult> composeFeedbackEmail() async {
    if (kIsWeb) return FeedbackLaunchResult.unavailable;

    final packageInfo = await PackageInfo.fromPlatform();
    final languageCode = LocalPreferencesService.language.value.toLowerCase();
    final subject =
        languageCode == 'tr' ? 'Duaya Geri Bildirim' : 'Duaya Feedback';
    final body = await _buildEmailBody(
      languageCode: languageCode,
      packageInfo: packageInfo,
    );
    final emailUri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: <String, String>{
        'subject': subject,
        'body': body,
      },
    );

    final launchedPreferred = await launchUrl(
      emailUri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (launchedPreferred) return FeedbackLaunchResult.launched;

    final launchedFallback = await launchUrl(
      emailUri,
      mode: LaunchMode.platformDefault,
    );
    return launchedFallback
        ? FeedbackLaunchResult.launched
        : FeedbackLaunchResult.unavailable;
  }

  static Future<FeedbackLaunchResult> requestRating() async {
    if (kIsWeb) return FeedbackLaunchResult.unavailable;

    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
        return FeedbackLaunchResult.launched;
      }

      if (Platform.isIOS) {
        const appStoreId = iosAppStoreId;
        if (appStoreId == null || appStoreId.isEmpty) {
          return FeedbackLaunchResult.unavailable;
        }
        await _inAppReview.openStoreListing(appStoreId: appStoreId);
        return FeedbackLaunchResult.launched;
      }

      await _inAppReview.openStoreListing();
      return FeedbackLaunchResult.launched;
    } catch (_) {
      return FeedbackLaunchResult.unavailable;
    }
  }

  static Future<String> _buildEmailBody({
    required String languageCode,
    required PackageInfo packageInfo,
  }) async {
    final labels = _FeedbackMetadataLabels.forLanguage(languageCode);
    final metadata = await _collectMetadata(
      languageCode: languageCode,
      packageInfo: packageInfo,
    );

    return [
      '',
      '',
      '',
      '---',
      '${labels.app}: $appName',
      '${labels.version}: ${packageInfo.version}',
      '${labels.buildNumber}: ${packageInfo.buildNumber}',
      '${labels.platform}: ${metadata.platform}',
      '${labels.osVersion}: ${metadata.osVersion}',
      '${labels.deviceModel}: ${metadata.deviceModel}',
      '${labels.appLanguage}: ${metadata.appLanguage}',
      '${labels.nextPrayerWidget}: ${metadata.nextPrayerWidgetEnabled}',
      '${labels.iftarCountdown}: ${metadata.iftarCountdownEnabled}',
    ].join('\n');
  }

  static Future<_FeedbackMetadata> _collectMetadata({
    required String languageCode,
    required PackageInfo packageInfo,
  }) async {
    final yesNo = _YesNoLabels.forLanguage(languageCode);
    final platform = Platform.isIOS ? 'iOS' : Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion.trim();
    final deviceModel = await _deviceModel();
    final appLanguage = languageCode == 'tr' ? 'TR' : 'EN';

    return _FeedbackMetadata(
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
      appLanguage: appLanguage,
      nextPrayerWidgetEnabled:
          LocalPreferencesService.nextPrayerWidgetEnabled.value
              ? yesNo.enabled
              : yesNo.disabled,
      iftarCountdownEnabled:
          LocalPreferencesService.iftarLiveActivityEnabled.value
              ? yesNo.enabled
              : yesNo.disabled,
    );
  }

  static Future<String> _deviceModel() async {
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final machine = info.utsname.machine.trim();
        final model = info.model.trim();
        if (machine.isEmpty) return model;
        if (model.isEmpty) return machine;
        return '$model ($machine)';
      }

      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        if (brand.isEmpty) return model;
        if (model.isEmpty) return brand;
        return '$brand $model';
      }
    } catch (_) {
      // Fall through to fallback text.
    }
    return 'Unknown';
  }
}

class _FeedbackMetadata {
  const _FeedbackMetadata({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.appLanguage,
    required this.nextPrayerWidgetEnabled,
    required this.iftarCountdownEnabled,
  });

  final String platform;
  final String osVersion;
  final String deviceModel;
  final String appLanguage;
  final String nextPrayerWidgetEnabled;
  final String iftarCountdownEnabled;
}

class _FeedbackMetadataLabels {
  const _FeedbackMetadataLabels({
    required this.app,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.appLanguage,
    required this.nextPrayerWidget,
    required this.iftarCountdown,
  });

  final String app;
  final String version;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String appLanguage;
  final String nextPrayerWidget;
  final String iftarCountdown;

  factory _FeedbackMetadataLabels.forLanguage(String languageCode) {
    if (languageCode == 'tr') {
      return const _FeedbackMetadataLabels(
        app: 'Uygulama',
        version: 'Sürüm',
        buildNumber: 'Derleme',
        platform: 'Platform',
        osVersion: 'İS sürümü',
        deviceModel: 'Cihaz modeli',
        appLanguage: 'Uygulama dili',
        nextPrayerWidget: 'Sıradaki Vakit Widget\'ı',
        iftarCountdown: 'İftar geri sayımı',
      );
    }
    return const _FeedbackMetadataLabels(
      app: 'App',
      version: 'Version',
      buildNumber: 'Build',
      platform: 'Platform',
      osVersion: 'OS version',
      deviceModel: 'Device model',
      appLanguage: 'App language',
      nextPrayerWidget: 'Next Prayer widget',
      iftarCountdown: 'Iftar countdown',
    );
  }
}

class _YesNoLabels {
  const _YesNoLabels({
    required this.enabled,
    required this.disabled,
  });

  final String enabled;
  final String disabled;

  factory _YesNoLabels.forLanguage(String languageCode) {
    if (languageCode == 'tr') {
      return const _YesNoLabels(enabled: 'Açık', disabled: 'Kapalı');
    }
    return const _YesNoLabels(enabled: 'Enabled', disabled: 'Disabled');
  }
}
