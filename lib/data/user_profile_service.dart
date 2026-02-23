import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

class UserProfileService {
  static const _keyDisplayName = 'profile_display_name';
  static const _keyNamePromptShown = 'profile_name_prompt_shown';
  static const _secureKeyDisplayName = 'secure_profile_display_name';

  static SharedPreferences? _prefs;

  static final ValueNotifier<String?> displayNameNotifier =
      ValueNotifier<String?>(null);

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    final secureDisplayName = _normalize(
      await SecureStorageService.read(_secureKeyDisplayName),
    );
    final legacyDisplayName = _normalize(_prefs?.getString(_keyDisplayName));

    if (secureDisplayName == null && legacyDisplayName != null) {
      await SecureStorageService.write(
          _secureKeyDisplayName, legacyDisplayName);
    }
    if (legacyDisplayName != null) {
      await _prefs?.remove(_keyDisplayName);
    }

    displayNameNotifier.value = secureDisplayName ?? legacyDisplayName;
  }

  static String? get displayName => displayNameNotifier.value;

  static bool get shouldShowNamePrompt =>
      !(_prefs?.getBool(_keyNamePromptShown) ?? false);

  static Future<void> markNamePromptShown() async {
    await _prefs?.setBool(_keyNamePromptShown, true);
  }

  static Future<void> setDisplayName(String? name) async {
    final normalized = _normalize(name);
    if (normalized == null) {
      await SecureStorageService.delete(_secureKeyDisplayName);
      await _prefs?.remove(_keyDisplayName);
      displayNameNotifier.value = null;
      return;
    }

    await SecureStorageService.write(_secureKeyDisplayName, normalized);
    await _prefs?.remove(_keyDisplayName);
    displayNameNotifier.value = normalized;
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
