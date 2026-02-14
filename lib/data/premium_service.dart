import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  PremiumService._();

  static const _keyEntitled = 'premium_entitled';
  static SharedPreferences? _prefs;

  static final isPremium = ValueNotifier<bool>(false);
  static bool get isDebugUnlockAvailable => !kReleaseMode;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    isPremium.value = _prefs?.getBool(_keyEntitled) ?? false;
  }

  static Future<void> setPremiumDebug(bool value) async {
    await _prefs?.setBool(_keyEntitled, value);
    isPremium.value = value;
  }

  static Future<void> restorePurchasesStub() async {
    // Placeholder for future in_app_purchase restore flow.
    final entitled = _prefs?.getBool(_keyEntitled) ?? false;
    isPremium.value = entitled;
  }
}
