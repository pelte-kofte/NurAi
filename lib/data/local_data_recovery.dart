import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataRecovery {
  LocalDataRecovery._();

  static void log(String scope, Object error, [StackTrace? stackTrace]) {
    assert(() {
      debugPrint('[LocalDataRecovery][$scope] $error');
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
      return true;
    }());
  }

  static Future<void> clearPrefsKeys(
    SharedPreferences? prefs,
    Iterable<String> keys,
  ) async {
    if (prefs == null) return;
    for (final key in keys) {
      try {
        await prefs.remove(key);
      } catch (error, stackTrace) {
        log('clearPrefsKeys:$key', error, stackTrace);
      }
    }
  }

  static bool getBool(
    SharedPreferences? prefs,
    String key, {
    bool fallback = false,
  }) {
    try {
      return prefs?.getBool(key) ?? fallback;
    } catch (error, stackTrace) {
      log('getBool:$key', error, stackTrace);
      unawaited(clearPrefsKeys(prefs, [key]));
      return fallback;
    }
  }

  static int? getInt(
    SharedPreferences? prefs,
    String key, {
    int? fallback,
  }) {
    try {
      return prefs?.getInt(key) ?? fallback;
    } catch (error, stackTrace) {
      log('getInt:$key', error, stackTrace);
      unawaited(clearPrefsKeys(prefs, [key]));
      return fallback;
    }
  }

  static double? getDouble(
    SharedPreferences? prefs,
    String key, {
    double? fallback,
  }) {
    try {
      return prefs?.getDouble(key) ?? fallback;
    } catch (error, stackTrace) {
      log('getDouble:$key', error, stackTrace);
      unawaited(clearPrefsKeys(prefs, [key]));
      return fallback;
    }
  }

  static String? getString(
    SharedPreferences? prefs,
    String key, {
    String? fallback,
  }) {
    try {
      return prefs?.getString(key) ?? fallback;
    } catch (error, stackTrace) {
      log('getString:$key', error, stackTrace);
      unawaited(clearPrefsKeys(prefs, [key]));
      return fallback;
    }
  }

  static List<String>? getStringList(
    SharedPreferences? prefs,
    String key, {
    List<String>? fallback,
  }) {
    try {
      return prefs?.getStringList(key) ?? fallback;
    } catch (error, stackTrace) {
      log('getStringList:$key', error, stackTrace);
      unawaited(clearPrefsKeys(prefs, [key]));
      return fallback;
    }
  }

  static bool containsKey(SharedPreferences? prefs, String key) {
    try {
      return prefs?.containsKey(key) ?? false;
    } catch (error, stackTrace) {
      log('containsKey:$key', error, stackTrace);
      unawaited(clearPrefsKeys(prefs, [key]));
      return false;
    }
  }

  static Set<String> getKeys(SharedPreferences? prefs) {
    try {
      return prefs?.getKeys() ?? const <String>{};
    } catch (error, stackTrace) {
      log('getKeys', error, stackTrace);
      return const <String>{};
    }
  }
}
