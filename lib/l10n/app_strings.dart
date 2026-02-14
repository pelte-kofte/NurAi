import '../data/local_preferences_service.dart';

/// Lightweight localization using a static dictionary.
/// Reads from [LocalPreferencesService.language] at call time.
/// UI reactivity comes from wrapping the widget tree in a
/// ValueListenableBuilder that rebuilds on language changes.
class S {
  S._();

  static String get _lang => LocalPreferencesService.language.value;
  static const supportedLanguageCodes = <String>['tr', 'en', 'ar', 'de'];

  /// Look up a key with fallback chain:
  /// selected language -> English -> Turkish -> raw key.
  static String get(String key) =>
      _strings[_lang]?[key] ??
      _strings['en']?[key] ??
      _strings['tr']?[key] ??
      key;

  static const _strings = <String, Map<String, String>>{
    'tr': {
      // Greetings
      'greeting_night': 'Hayirli geceler',
      'greeting_morning': 'Hayirli sabahlar',
      'greeting_day': 'Hayirli gunler',
      'greeting_evening': 'Hayirli aksamlar',

      // Home
      'daily_ayah': 'Gunun Ayeti',
      'daily_hadith_title': 'Gunun Hadisi',
      'daily_word_title': 'Nazik Hatirlatma',
      'daily_hadith_empty': 'Bugun icin hadis bulunamadi.',
      'daily_word_empty': 'Bugun icin hatirlatma bulunamadi.',
      'notes_placeholder': 'Bugun nasilsiniz?',
      'ramadan_prep': 'Ramazan ayina hazirlik zamani',
      'start_reading': 'Okumaya basla',
      'hatim_title': 'Hatim Niyeti',
      'hatim_subtitle': 'Bastan sona okuma niyeti',
      'juz_title': 'Cuz Niyeti',
      'juz_subtitle': 'Birlikte okuma icin niyet et',
      'surah_label': 'Suresi',
      'ayah_label': 'Ayet',
      'juz_selected': 'Cuz secildi',
      'juz_label': 'Cuz',

      // Quick Actions
      'quick_actions': 'Hizli islemler',
      'qibla': 'Kible Bulucu',
      'adhan_alarms': 'Ezan bildirimleri',
      'adhan_times': 'Ezan Vakitleri',

      // Notification dialog
      'notif_title': 'Bildirim Izni',
      'notif_body':
          'Ezan vakitlerini bildirebilmemiz icin bildirim iznine ihtiyacimiz var.\n\nCihaz ayarlarindan bildirimleri etkinlestirebilirsiniz.',
      'ok': 'Tamam',

      // Settings
      'settings': 'Ayarlar',
      'language': 'Dil',
      'appearance': 'Gorunum',
      'system': 'Sistem',
      'light': 'Acik',
      'dark': 'Koyu',
      'haptics': 'Haptik geri bildirim',
      'send_feedback': 'Geri bildirim gonder',
      'privacy_policy': 'Gizlilik Politikasi',
      'terms': 'Kullanim Sartlari',
      'theme_system': 'Sistem',
      'theme_light': 'Acik',
      'theme_dark': 'Koyu',
      'stub_feedback': 'Geri bildirim ozelligi yakinda eklenecek.',
      'stub_link': 'Baglanti eklenecek.',
      'profile': 'Profil',
      'display_name': 'Hitap Ismi',
      'my_notes': 'Notlarim',
      'note_title': 'Not',
      'note_hint': 'Notunuzu yazin',
      'notes_empty': 'Henuz not eklenmedi.',
      'notes_premium_required': 'Ayet notlari Premium ozelligidir.',
      'note_delete_confirm': 'Bu notu silmek istiyor musunuz?',
      'delete': 'Sil',
      'cancel': 'Vazgec',
      'premium_title': 'Premium',
      'premium_unlock': 'Premium\'u ac',
      'premium_unlock_soon': 'Yakinda',
      'premium_restore': 'Geri yukle',
      'premium_restore_not_available':
          'Geri yukleme su anda kullanilabilir degil.',
      'premium_disclaimer': 'Odeme altyapisi yakinda.',
      'premium_local_notes_disclaimer':
          'Notlar bu cihazda yerel olarak saklanir.',
      'premium_feature_ayah_notes': 'Ayet Notlari',
      'premium_feature_notes_list': 'Tum notlarini tek yerde gor',
      'premium_feature_sync_soon': 'Senkronizasyon (yakinda)',
      'name_hint': 'Isminiz (istege bagli)',
      'name_not_set': 'Belirtilmedi',
      'clear': 'Temizle',
      'save': 'Kaydet',
      'continue': 'Devam et',
      'skip': 'Atla',
      'name_prompt_title': 'Size nasil hitap edelim?',
      'today_title': 'Bugun nasilsiniz?',
      'today_hint': 'Icinizden gecenleri yazabilirsiniz',
      'today_intention_saved': 'Bugun icin niyetiniz kaydedildi.',
      'today_for': 'Bugun icin',
      'ayah_type': 'Ayet',
      'hadith_type': 'Hadis',
      'language_tr': 'Turkce',
      'language_en': 'English',
      'language_ar': 'Arapca',
      'language_de': 'Almanca',
      'prayer_times': 'Namaz Vakitleri',
      'prayer_times_title': 'Namaz Vakitleri',
      'prayer_times_subtitle_current': 'Mevcut konum',
      'prayer_times_subtitle_city_prefix': 'Konum',
      'prayer_times_enable_location_title': 'Namaz vakitleri hazir',
      'prayer_times_enable_location_body':
          'Konum izni vererek bulundugun yere gore bugunun vakitlerini gorebilirsin.',
      'prayer_times_use_current': 'Konumu kullan',
      'prayer_times_choose_city': 'Sehir sec',
      'prayer_times_permission_denied': 'Konum izni verilmedi.',
      'prayer_times_open_settings': 'Ayarlari ac',
      'prayer_times_loading': 'Yukleniyor...',
      'prayer_times_next_prayer': 'Siradaki vakit',
      'prayer_times_no_location': 'Konum secilmedi',
      'prayer_times_search_city': 'Sehir veya ulke ara',
      'prayer_times_selected_location': 'Secilen konum',
      'prayer_times_notifications_on': 'Bildirimler: Acik',
      'prayer_times_notifications_off': 'Bildirimler: Kapali',
      'prayer_times_scheduled': 'Planlandi',
      'prayer_times_passed': 'Gecti',
      'prayer_timezone_device_disclaimer':
          'Saat dilimi cihaz ayarlarina gore kullaniliyor.',
      'prayer_notif_title': '{prayerName} vakti',
      'prayer_notif_body': '{prayerName} • {cityName} • {time}',
      'prayer_notif_scheduled': 'Bildirimler planlandi.',
      'prayer_notif_permission_title': 'Bildirim izni gerekli',
      'prayer_notif_permission_body':
          'Ezan bildirimlerini gonderebilmek icin bildirim iznine ihtiyacimiz var.',
      'prayer_notif_open_settings': 'Ayarlari ac',
      'prayer_location_needed_title': 'Konum gerekli',
      'prayer_location_needed_body':
          'Dogru namaz vakitleri icin konum bilgisine ihtiyacimiz var.',
      'prayer_choose_city_instead': 'Bunun yerine sehir sec',
      'prayer_notifications': 'Namaz bildirimleri',
      'location': 'Konum',
      'use_current_location': 'Mevcut konumu kullan',
      'select_city': 'Sehir sec',
      'location_privacy_note':
          'Sadece cihaz konumu kullanilir. Veriler sunuculara gonderilmez.',
      'city_placeholder': 'Sehir secimi yakinda eklenecek.',
      'location_service_disabled': 'Konum servisi kapali. Lutfen acin.',
      'location_permission_denied': 'Konum izni verilmedi.',
      'location_permission_denied_forever':
          'Konum izni kalici olarak reddedildi. Ayarlardan izin verin.',
      'location_unavailable_web': 'Bu ozellik webde kullanilamaz.',
      'location_read_failed': 'Konum bilgisi alinamadi. Tekrar deneyin.',
      'prayer_times_today': 'Bugun',
      'prayer_location_current': 'Mevcut konum',
      'prayer_times_location_required':
          'Namaz vakitlerini gormek icin konum secin.',
      'enable_location': 'Konumu etkinlestir',
      'fajr': 'Sabah',
      'sunrise': 'Gunes',
      'dhuhr': 'Ogle',
      'asr': 'Ikindi',
      'maghrib': 'Aksam',
      'isha': 'Yatsi',
      'suggestion_gratitude_1_text':
          'Eger sukrederseniz elbette size artiririm.',
      'suggestion_gratitude_1_source': 'Ibrahim 14:7',
      'suggestion_gratitude_2_text': 'Allah kulunun sukrunden razi olur.',
      'suggestion_gratitude_2_source': 'Muslim',
      'suggestion_gratitude_3_text':
          'Oyleyse Rabbinizin hangi nimetini yalanlarsiniz?',
      'suggestion_gratitude_3_source': 'Rahman 55:13',
      'suggestion_calm_1_text': 'Kalpler ancak Allahi anmakla huzur bulur.',
      'suggestion_calm_1_source': 'Rad 13:28',
      'suggestion_calm_2_text': 'Kolaylastirin, zorlastirmayin.',
      'suggestion_calm_2_source': 'Buhari',
      'suggestion_calm_3_text':
          'Rabbinin adini an ve tum kalbinle Ona yonel.',
      'suggestion_calm_3_source': 'Muzzemmil 73:8',
      'suggestion_anxious_1_text': 'Allah bize yeter, O ne guzel vekildir.',
      'suggestion_anxious_1_source': 'Al-i Imran 3:173',
      'suggestion_anxious_2_text': 'Allahin rahmetinden umit kesmeyin.',
      'suggestion_anxious_2_source': 'Zumer 39:53',
      'suggestion_anxious_3_text': 'Dua, muminin dayanagidir.',
      'suggestion_anxious_3_source': 'Tirmizi',
      'suggestion_sad_1_text': 'Suphesiz zorlukla beraber bir kolaylik vardir.',
      'suggestion_sad_1_source': 'Insirah 94:6',
      'suggestion_sad_2_text': 'Rabbin seni terk etmedi ve sana darilmadi.',
      'suggestion_sad_2_source': 'Duha 93:3',
      'suggestion_sad_3_text': 'Muminin hali hayirdir.',
      'suggestion_sad_3_source': 'Muslim',
      'suggestion_tired_1_text': 'Biz insani en guzel bicimde yarattik.',
      'suggestion_tired_1_source': 'Tin 95:4',
      'suggestion_tired_2_text': 'Bedeninin de senin uzerinde hakki vardir.',
      'suggestion_tired_2_source': 'Buhari',
      'suggestion_tired_3_text':
          'Her nefse ancak gucunun yettigi kadar yuk yuklenir.',
      'suggestion_tired_3_source': 'Bakara 2:286',
      'suggestion_neutral_1_text':
          'Rabbiniz buyurdu: Bana dua edin, size cevap vereyim.',
      'suggestion_neutral_1_source': 'Mumin 40:60',
      'suggestion_neutral_2_text':
          'Amellerin en hayirlisi az da olsa devamli olandir.',
      'suggestion_neutral_2_source': 'Buhari',
      'suggestion_neutral_3_text': 'Kim Allaha dayanirsa O kendisine yeter.',
      'suggestion_neutral_3_source': 'Talak 65:3',

      // Surah list
      'surahs': 'Sureler',
      'ayah_count_suffix': 'ayet',

      // Loading / Error
      'loading': 'Bismillah',
      'load_error': 'Veriler yuklenemedi.\nLutfen uygulamayi yeniden baslatin.',
    },
    'en': {
      // Greetings
      'greeting_night': 'Blessed night',
      'greeting_morning': 'Good morning',
      'greeting_day': 'Good day',
      'greeting_evening': 'Good evening',

      // Home
      'daily_ayah': 'Verse of the Day',
      'daily_hadith_title': 'Hadith of the Day',
      'daily_word_title': 'Gentle Reminder',
      'daily_hadith_empty': 'No hadith available for today.',
      'daily_word_empty': 'No reminder available for today.',
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
      'juz_label': 'Juz',

      // Quick Actions
      'quick_actions': 'Quick actions',
      'qibla': 'Qibla Finder',
      'adhan_alarms': 'Adhan notifications',
      'adhan_times': 'Adhan Times',

      // Notification dialog
      'notif_title': 'Notification Permission',
      'notif_body':
          'We need notification permission to alert you for prayer times.\n\nYou can enable notifications from device settings.',
      'ok': 'OK',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'appearance': 'Appearance',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'haptics': 'Haptic feedback',
      'send_feedback': 'Send feedback',
      'privacy_policy': 'Privacy Policy',
      'terms': 'Terms of Use',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'stub_feedback': 'Feedback feature coming soon.',
      'stub_link': 'Link will be added.',
      'profile': 'Profile',
      'display_name': 'Display name',
      'my_notes': 'My Notes',
      'note_title': 'Note',
      'note_hint': 'Write your note',
      'notes_empty': 'No notes yet.',
      'notes_premium_required': 'Ayah notes are a Premium feature.',
      'note_delete_confirm': 'Delete this note?',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'premium_title': 'Premium',
      'premium_unlock': 'Unlock Premium',
      'premium_unlock_soon': 'Coming soon',
      'premium_restore': 'Restore',
      'premium_restore_not_available':
          'Restore is not available at the moment.',
      'premium_disclaimer': 'Payment infrastructure is coming soon.',
      'premium_local_notes_disclaimer':
          'Notes are stored locally on this device.',
      'premium_feature_ayah_notes': 'Ayah Notes',
      'premium_feature_notes_list': 'See all your notes in one place',
      'premium_feature_sync_soon': 'Sync (coming soon)',
      'name_hint': 'Your name (optional)',
      'name_not_set': 'Not set',
      'clear': 'Clear',
      'save': 'Save',
      'continue': 'Continue',
      'skip': 'Skip',
      'name_prompt_title': 'How should we address you?',
      'today_title': 'How are you today?',
      'today_hint': 'You can write what is on your mind',
      'today_intention_saved': 'Your intention for today has been saved.',
      'today_for': 'For today',
      'ayah_type': 'Ayah',
      'hadith_type': 'Hadith',
      'language_tr': 'Turkish',
      'language_en': 'English',
      'language_ar': 'Arabic',
      'language_de': 'German',
      'prayer_times': 'Prayer Times',
      'prayer_times_title': 'Prayer Times',
      'prayer_times_subtitle_current': 'Current location',
      'prayer_times_subtitle_city_prefix': 'Location',
      'prayer_times_enable_location_title': 'Prayer times are ready',
      'prayer_times_enable_location_body':
          'Allow location access or choose a city to see today\'s prayer times.',
      'prayer_times_use_current': 'Use current location',
      'prayer_times_choose_city': 'Choose city',
      'prayer_times_permission_denied': 'Location permission denied.',
      'prayer_times_open_settings': 'Open settings',
      'prayer_times_loading': 'Loading...',
      'prayer_times_next_prayer': 'Next prayer',
      'prayer_times_no_location': 'No location selected',
      'prayer_times_search_city': 'Search city or country',
      'prayer_times_selected_location': 'Selected location',
      'prayer_times_notifications_on': 'Notifications: ON',
      'prayer_times_notifications_off': 'Notifications: OFF',
      'prayer_times_scheduled': 'Scheduled',
      'prayer_times_passed': 'Passed',
      'prayer_timezone_device_disclaimer':
          'Timezone based on device settings.',
      'prayer_notif_title': 'Time for {prayerName}',
      'prayer_notif_body': '{prayerName} in {cityName} • {time}',
      'prayer_notif_scheduled': 'Notifications scheduled.',
      'prayer_notif_permission_title': 'Notification permission needed',
      'prayer_notif_permission_body':
          'We need notification permission to send Adhan reminders.',
      'prayer_notif_open_settings': 'Open settings',
      'prayer_location_needed_title': 'Location needed',
      'prayer_location_needed_body':
          'We need location to calculate accurate prayer times.',
      'prayer_choose_city_instead': 'Choose city instead',
      'prayer_notifications': 'Prayer notifications',
      'location': 'Location',
      'use_current_location': 'Use current location',
      'select_city': 'Select city',
      'location_privacy_note':
          'Uses device location only. No data is sent to servers.',
      'city_placeholder': 'City selection will be added soon.',
      'location_service_disabled':
          'Location services are disabled. Please enable them.',
      'location_permission_denied': 'Location permission was not granted.',
      'location_permission_denied_forever':
          'Location permission is permanently denied. Enable it from settings.',
      'location_unavailable_web': 'This feature is unavailable on web.',
      'location_read_failed': 'Could not read location. Please try again.',
      'prayer_times_today': 'Today',
      'prayer_location_current': 'Current location',
      'prayer_times_location_required':
          'Select a location to view prayer times.',
      'enable_location': 'Enable location',
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'suggestion_gratitude_1_text':
          'If you are grateful, I will surely increase you.',
      'suggestion_gratitude_1_source': 'Ibrahim 14:7',
      'suggestion_gratitude_2_text':
          'Allah is pleased with His servant being grateful.',
      'suggestion_gratitude_2_source': 'Muslim',
      'suggestion_gratitude_3_text':
          'Then which of your Lord\'s favors will you deny?',
      'suggestion_gratitude_3_source': 'Ar-Rahman 55:13',
      'suggestion_calm_1_text': 'Surely, hearts find peace in the remembrance of Allah.',
      'suggestion_calm_1_source': 'Ar-Rad 13:28',
      'suggestion_calm_2_text': 'Make things easy and do not make them difficult.',
      'suggestion_calm_2_source': 'Bukhari',
      'suggestion_calm_3_text':
          'Remember the name of your Lord and devote yourself to Him wholeheartedly.',
      'suggestion_calm_3_source': 'Al-Muzzammil 73:8',
      'suggestion_anxious_1_text': 'Allah is sufficient for us, and He is the best Disposer of affairs.',
      'suggestion_anxious_1_source': 'Aal Imran 3:173',
      'suggestion_anxious_2_text': 'Do not despair of the mercy of Allah.',
      'suggestion_anxious_2_source': 'Az-Zumar 39:53',
      'suggestion_anxious_3_text': 'Supplication is the support of the believer.',
      'suggestion_anxious_3_source': 'Tirmidhi',
      'suggestion_sad_1_text': 'Indeed, with hardship comes ease.',
      'suggestion_sad_1_source': 'Ash-Sharh 94:6',
      'suggestion_sad_2_text': 'Your Lord has not forsaken you, nor is He displeased.',
      'suggestion_sad_2_source': 'Ad-Duhaa 93:3',
      'suggestion_sad_3_text': 'The affair of the believer is always good.',
      'suggestion_sad_3_source': 'Muslim',
      'suggestion_tired_1_text': 'We have certainly created man in the best form.',
      'suggestion_tired_1_source': 'At-Tin 95:4',
      'suggestion_tired_2_text': 'Your body has a right over you.',
      'suggestion_tired_2_source': 'Bukhari',
      'suggestion_tired_3_text':
          'No soul is burdened beyond what it can bear.',
      'suggestion_tired_3_source': 'Al-Baqarah 2:286',
      'suggestion_neutral_1_text':
          'Your Lord said: Call upon Me; I will respond to you.',
      'suggestion_neutral_1_source': 'Ghafir 40:60',
      'suggestion_neutral_2_text':
          'The most beloved deeds are those done consistently, even if small.',
      'suggestion_neutral_2_source': 'Bukhari',
      'suggestion_neutral_3_text': 'Whoever relies upon Allah, He is sufficient for them.',
      'suggestion_neutral_3_source': 'At-Talaq 65:3',

      // Surah list
      'surahs': 'Surahs',
      'ayah_count_suffix': 'ayahs',

      // Loading / Error
      'loading': 'Bismillah',
      'load_error': 'Data could not be loaded.\nPlease restart the app.',
    },
    'ar': {
      // Placeholder language map (falls back to English/Turkish when missing)
      'language_tr': 'التركية',
      'language_en': 'الانجليزية',
      'language_ar': 'العربية',
      'language_de': 'الالمانية',
    },
    'de': {
      // Placeholder language map (falls back to English/Turkish when missing)
      'language_tr': 'Turkisch',
      'language_en': 'Englisch',
      'language_ar': 'Arabisch',
      'language_de': 'Deutsch',
    },
  };
}
