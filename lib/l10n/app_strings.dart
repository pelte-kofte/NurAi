import '../data/local_preferences_service.dart';

/// Lightweight localization using a static dictionary.
/// Reads from [LocalPreferencesService.language] at call time.
/// UI reactivity comes from wrapping the widget tree in a
/// ValueListenableBuilder that rebuilds on language changes.
class S {
  S._();

  static String get _lang => LocalPreferencesService.language.value;

  /// Look up a key in the current language, fallback to Turkish.
  static String get(String key) =>
      _strings[_lang]?[key] ?? _strings['tr']![key] ?? key;

  // ── String table ────────────────────────────────────────────────

  static const _strings = <String, Map<String, String>>{
    'tr': {
      // Greetings
      'greeting_night': 'Hay\u0131rl\u0131 geceler',
      'greeting_morning': 'Hay\u0131rl\u0131 sabahlar',
      'greeting_day': 'Hay\u0131rl\u0131 g\u00fcnler',
      'greeting_evening': 'Hay\u0131rl\u0131 ak\u015famlar',

      // Home
      'daily_ayah': 'G\u00fcn\u00fcn Ayeti',
      'notes_placeholder': 'Bug\u00fcn nas\u0131ls\u0131n\u0131z?',
      'ramadan_prep': 'Ramazan ay\u0131na haz\u0131rl\u0131k zaman\u0131',
      'start_reading': 'Okumaya ba\u015fla',
      'hatim_title': 'Hatim Niyeti',
      'hatim_subtitle': 'Ba\u015ftan sona okuma niyeti',
      'juz_title': 'C\u00fcz Niyeti',
      'juz_subtitle': 'Birlikte okuma i\u00e7in niyet et',
      'surah_label': 'Suresi',
      'ayah_label': 'Ayet',
      'juz_selected': 'C\u00fcz se\u00e7ildi',

      // Quick Actions
      'quick_actions': 'H\u0131zl\u0131 i\u015flemler',
      'qibla': 'K\u0131ble',
      'adhan_alarms': 'Ezan alarmlar\u0131',

      // Notification dialog
      'notif_title': 'Bildirim \u0130zni',
      'notif_body':
          'Ezan vakitlerini bildirebilmemiz i\u00e7in bildirim iznine ihtiyac\u0131m\u0131z var.\n\nCihaz ayarlar\u0131ndan bildirimleri etkinle\u015ftirebilirsiniz.',
      'ok': 'Tamam',

      // Settings
      'settings': 'Ayarlar',
      'language': 'Dil',
      'appearance': 'G\u00f6r\u00fcn\u00fc\u015f',
      'haptics': 'Haptik geri bildirim',
      'send_feedback': 'Geri bildirim g\u00f6nder',
      'privacy_policy': 'Gizlilik Politikas\u0131',
      'terms': 'Kullan\u0131m \u015eartlar\u0131',
      'theme_system': 'Sistem',
      'theme_light': 'A\u00e7\u0131k',
      'theme_dark': 'Koyu',
      'stub_feedback': 'Geri bildirim \u00f6zelli\u011fi yak\u0131nda eklenecek.',
      'stub_link': 'Ba\u011flant\u0131 eklenecek.',

      // Surah list
      'surahs': 'Sureler',
      'ayah_count_suffix': 'ayet',

      // Loading / Error
      'loading': 'Bismillah',
      'load_error':
          'Veriler y\u00fcklenemedi.\nL\u00fctfen uygulama\u0131 yeniden ba\u015flat\u0131n.',
    },
    'en': {
      // Greetings
      'greeting_night': 'Blessed night',
      'greeting_morning': 'Good morning',
      'greeting_day': 'Good day',
      'greeting_evening': 'Good evening',

      // Home
      'daily_ayah': 'Verse of the Day',
      'notes_placeholder': 'How are you today?',
      'ramadan_prep': 'Time to prepare for Ramadan',
      'start_reading': 'Start reading',
      'hatim_title': 'Khatm Intention',
      'hatim_subtitle': 'Reading from cover to cover',
      'juz_title': 'Juz Intention',
      'juz_subtitle': 'Set an intention for collective reading',
      'surah_label': 'Surah',
      'ayah_label': 'Ayah',
      'juz_selected': 'Juz selected',

      // Quick Actions
      'quick_actions': 'Quick actions',
      'qibla': 'Qibla',
      'adhan_alarms': 'Adhan alarms',

      // Notification dialog
      'notif_title': 'Notification Permission',
      'notif_body':
          'We need notification permission to alert you for prayer times.\n\nYou can enable notifications from device settings.',
      'ok': 'OK',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'appearance': 'Appearance',
      'haptics': 'Haptic feedback',
      'send_feedback': 'Send feedback',
      'privacy_policy': 'Privacy Policy',
      'terms': 'Terms of Use',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'stub_feedback': 'Feedback feature coming soon.',
      'stub_link': 'Link will be added.',

      // Surah list
      'surahs': 'Surahs',
      'ayah_count_suffix': 'ayahs',

      // Loading / Error
      'loading': 'Bismillah',
      'load_error':
          'Data could not be loaded.\nPlease restart the app.',
    },
  };
}
