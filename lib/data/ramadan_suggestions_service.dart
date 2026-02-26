import 'dart:convert';

import 'local_preferences_service.dart';

enum RamadanSuggestionType { dua, ayet, iyilik }

class RamadanSuggestionItem {
  const RamadanSuggestionItem({
    required this.type,
    required this.headerKey,
    required this.text,
    this.secondary,
  });

  final RamadanSuggestionType type;
  final String headerKey;
  final String text;
  final String? secondary;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'headerKey': headerKey,
        'text': text,
        'secondary': secondary,
      };

  static RamadanSuggestionItem fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] as String? ?? 'dua').trim();
    final type = RamadanSuggestionType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => RamadanSuggestionType.dua,
    );
    return RamadanSuggestionItem(
      type: type,
      headerKey: (json['headerKey'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      secondary: (json['secondary'] as String?)?.trim(),
    );
  }
}

class RamadanSuggestionFavorite {
  const RamadanSuggestionFavorite({
    required this.type,
    required this.text,
    this.secondary,
    required this.savedAtIso,
  });

  final RamadanSuggestionType type;
  final String text;
  final String? secondary;
  final String savedAtIso;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'secondary': secondary,
        'savedAtIso': savedAtIso,
      };

  static RamadanSuggestionFavorite fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] as String? ?? 'dua').trim();
    final type = RamadanSuggestionType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => RamadanSuggestionType.dua,
    );
    return RamadanSuggestionFavorite(
      type: type,
      text: (json['text'] as String? ?? '').trim(),
      secondary: (json['secondary'] as String?)?.trim(),
      savedAtIso: (json['savedAtIso'] as String? ?? '').trim(),
    );
  }

  bool matches(RamadanSuggestionItem item) {
    return type == item.type &&
        text == item.text &&
        (secondary ?? '') == (item.secondary ?? '');
  }
}

class RamadanSuggestionsBundle {
  const RamadanSuggestionsBundle({
    required this.dateKey,
    required this.duaIndex,
    required this.ayetIndex,
    required this.iyilikIndex,
    required this.dua,
    required this.ayet,
    required this.iyilik,
  });

  final String dateKey;
  final int duaIndex;
  final int ayetIndex;
  final int iyilikIndex;
  final RamadanSuggestionItem dua;
  final RamadanSuggestionItem ayet;
  final RamadanSuggestionItem iyilik;
}

class RamadanSuggestionsService {
  RamadanSuggestionsService._();

  static const List<Map<String, String>> _duasTr = [
    {'text': 'Allah’ım kalbime huzur, dilime zikrini nasip et.', 'secondary': 'Kısa dua'},
    {'text': 'Rabbim, niyetimi halis, amellerimi bereketli eyle.', 'secondary': 'Ramazan duası'},
    {'text': 'Allah’ım, bugünümü hayırla doldur, beni hayra yönelt.'},
    {'text': 'Rabbim, bana sabır ve yumuşak bir kalp ver.'},
    {'text': 'Allah’ım, beni affınla kuşat, merhametinle güçlendir.'},
    {'text': 'Rabbim, dilimi doğrulukla, gönlümü şükürle süsle.'},
    {'text': 'Allah’ım, aileme sağlık, evime huzur, kalbime sekinet ver.'},
    {'text': 'Rabbim, beni faydalı ilim ve güzel ahlakla yaşat.'},
    {'text': 'Allah’ım, bugün yaptığım her işi rızana uygun kıl.'},
    {'text': 'Rabbim, gönlümdeki darlığı ferahlığa çevir.'},
    {'text': 'Allah’ım, bana doğruda sebat, yanlıştan uzaklık nasip et.'},
    {'text': 'Rabbim, kalbime Kur’an sevgisi ve anlayış ver.'},
    {'text': 'Allah’ım, beni kibirden koru, tevazu ile yaşat.'},
    {'text': 'Rabbim, hatalarımı bağışla, beni güzel olana yönelt.'},
    {'text': 'Allah’ım, bugün birine iyilik yapmayı bana kolaylaştır.'},
    {'text': 'Rabbim, öfkemi yatıştır, sözümü güzelleştir.'},
    {'text': 'Allah’ım, beni israftan ve gafletten uzak tut.'},
    {'text': 'Rabbim, bugünümü bereketli, gecemi huzurlu eyle.'},
    {'text': 'Allah’ım, bana kanaat ve şükür bilinci ver.'},
    {'text': 'Rabbim, kalbimi kırmaktan da kırılmaktan da koru.'},
    {'text': 'Allah’ım, bana helal rızık ve temiz niyet ver.'},
    {'text': 'Rabbim, beni faydasız söz ve işten uzak tut.'},
    {'text': 'Allah’ım, kalbimi umutla diri tut.'},
    {'text': 'Rabbim, beni doğruluktan ayırma.'},
    {'text': 'Allah’ım, bugünümü hayırla tamamlamayı nasip et.'},
  ];

  static const List<Map<String, String>> _ayetlerTr = [
    {'text': 'Kalpler ancak Allah’ı anmakla huzur bulur.', 'secondary': 'Ra’d · 28'},
    {'text': 'Şüphesiz zorlukla beraber bir kolaylık vardır.', 'secondary': 'İnşirah · 6'},
    {'text': 'Allah sabredenlerle beraberdir.', 'secondary': 'Bakara · 153'},
    {'text': 'Rabbim ilmimi artır.', 'secondary': 'Taha · 114'},
    {'text': 'Allah size kolaylık ister, zorluk istemez.', 'secondary': 'Bakara · 185'},
    {'text': 'Şükrederseniz elbette nimetimi artırırım.', 'secondary': 'İbrahim · 7'},
    {'text': 'Allah, kuluna kâfi değil midir?', 'secondary': 'Zümer · 36'},
    {'text': 'İyilikle kötülük bir olmaz.', 'secondary': 'Fussilet · 34'},
    {'text': 'Allah adaleti ve ihsanı emreder.', 'secondary': 'Nahl · 90'},
    {'text': 'Bana dua edin, size cevap vereyim.', 'secondary': 'Mümin · 60'},
    {'text': 'Rabbin seni ne terk etti ne darıldı.', 'secondary': 'Duha · 3'},
    {'text': 'Allah, müminlere karşı çok merhametlidir.', 'secondary': 'Ahzab · 43'},
    {'text': 'Kim Allah’a dayanırsa O ona yeter.', 'secondary': 'Talak · 3'},
    {'text': 'Allah sizin için temiz olanları helal kıldı.', 'secondary': 'Maide · 4'},
    {'text': 'Güzel söz sadakadır.', 'secondary': 'Bakara · 263'},
    {'text': 'Allah, iyilik yapanları sever.', 'secondary': 'Bakara · 195'},
    {'text': 'Rabbim bana doğruyu ilham et.', 'secondary': 'Şems · 8'},
    {'text': 'Allah affedicidir, affı sever.', 'secondary': 'Nisa · 99'},
    {'text': 'Allah, dilediğine hesapsız rızık verir.', 'secondary': 'Bakara · 212'},
    {'text': 'Rabbinizin rahmetinden ümit kesmeyin.', 'secondary': 'Zümer · 53'},
    {'text': 'Doğrularla beraber olun.', 'secondary': 'Tevbe · 119'},
    {'text': 'Allah, güzel iş yapanların ecrini zayi etmez.', 'secondary': 'Hud · 115'},
    {'text': 'Rabbinin nimetini anlat.', 'secondary': 'Duha · 11'},
    {'text': 'Geceyi dinlenesiniz diye yarattık.', 'secondary': 'Yunus · 67'},
    {'text': 'Allah kuluna şah damarından daha yakındır.', 'secondary': 'Kaf · 16'},
  ];

  static const List<Map<String, String>> _iyiliklerTr = [
    {'text': 'Bugün birine içten bir tebessüm hediye et.', 'secondary': 'Minik öneri'},
    {'text': 'Ailenden birine teşekkür mesajı gönder.'},
    {'text': 'Bir bardak suyu niyetle birine ikram et.'},
    {'text': 'Bugün kimsenin sözünü kesmeden dinlemeyi dene.'},
    {'text': 'Evde küçük bir işi gönüllü olarak üstlen.'},
    {'text': 'Uzun zamandır konuşmadığın birini hatırla.'},
    {'text': 'Birine dua edeceğini söyle ve gerçekten dua et.'},
    {'text': 'Bugün gereksiz bir eleştiriyi ertele.'},
    {'text': 'Çevrende birine nazik bir cümle kur.'},
    {'text': 'Sofrada israfı azaltmak için küçük bir adım at.'},
    {'text': 'Bugün bir özür borcunu yerine getir.'},
    {'text': 'Birine yol ver, acele etmeden sabret.'},
    {'text': 'Telefonu kısa süre kenara bırakıp ailene vakit ayır.'},
    {'text': 'Bir dostuna “Nasılsın?” diye samimi bir mesaj yaz.'},
    {'text': 'Bugün birine sessizce destek ol.'},
    {'text': 'Kırgın olduğun biri için iyi niyet dile.'},
    {'text': 'Küçük bir bağışı niyet ederek yap.'},
    {'text': 'Bugün yumuşak bir üslupla konuşmaya özen göster.'},
    {'text': 'Bir büyüğünün hâlini sor.'},
    {'text': 'Kalbini yoran bir konuyu Allah’a havale et.'},
    {'text': 'Bugün birine “Allah razı olsun” demeyi unutma.'},
    {'text': 'Masanı veya odanı toparlayıp ferahlık oluştur.'},
    {'text': 'Bir çocuğu sevindir, küçük bir ilgi göster.'},
    {'text': 'Bugün birini yargılamadan anlamayı dene.'},
    {'text': 'Geceye bir teşekkür listesiyle gir.'},
  ];

  static const List<Map<String, String>> _duasEn = [
    {'text': 'O Allah, grant peace to my heart and remembrance to my tongue.', 'secondary': 'Short dua'},
    {'text': 'My Lord, purify my intention and bless my deeds.', 'secondary': 'Ramadan dua'},
    {'text': 'O Allah, fill my day with goodness and guide me to what is right.'},
    {'text': 'My Lord, grant me patience and a gentle heart.'},
    {'text': 'O Allah, surround me with forgiveness and mercy.'},
    {'text': 'My Lord, adorn my speech with truth and my heart with gratitude.'},
    {'text': 'O Allah, grant my family health, my home peace, and my heart serenity.'},
    {'text': 'My Lord, keep me steadfast on what is true and beneficial.'},
    {'text': 'O Allah, make my actions pleasing to You today.'},
    {'text': 'My Lord, turn my worries into ease and trust in You.'},
  ];

  static const List<Map<String, String>> _ayetlerEn = [
    {'text': 'Surely in the remembrance of Allah do hearts find rest.', 'secondary': 'Ar-Rad 13:28'},
    {'text': 'Indeed, with hardship comes ease.', 'secondary': 'Ash-Sharh 94:6'},
    {'text': 'Indeed, Allah is with the patient.', 'secondary': 'Al-Baqarah 2:153'},
    {'text': 'My Lord, increase me in knowledge.', 'secondary': 'Ta-Ha 20:114'},
    {'text': 'Allah intends ease for you, not hardship.', 'secondary': 'Al-Baqarah 2:185'},
    {'text': 'If you are grateful, I will surely increase you.', 'secondary': 'Ibrahim 14:7'},
    {'text': 'Is Allah not sufficient for His servant?', 'secondary': 'Az-Zumar 39:36'},
    {'text': 'Good and evil are not equal.', 'secondary': 'Fussilat 41:34'},
    {'text': 'Allah commands justice and excellence.', 'secondary': 'An-Nahl 16:90'},
    {'text': 'Call upon Me; I will respond to you.', 'secondary': 'Ghafir 40:60'},
  ];

  static const List<Map<String, String>> _iyiliklerEn = [
    {'text': 'Offer a sincere smile to someone today.', 'secondary': 'Small kindness'},
    {'text': 'Send a thank-you message to a family member.'},
    {'text': 'Give water to someone with a good intention.'},
    {'text': 'Listen fully without interrupting someone today.'},
    {'text': 'Take on one small task at home willingly.'},
    {'text': 'Reach out to someone you have not spoken to in a while.'},
    {'text': 'Promise to make dua for someone, then do it.'},
    {'text': 'Postpone one unnecessary criticism today.'},
    {'text': 'Say one kind sentence to someone around you.'},
    {'text': 'End the day by writing a short gratitude list.'},
  ];

  static String dateKeyFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static RamadanSuggestionsBundle deterministicBundleForDate(DateTime date) {
    final pools = _contentPoolsForActiveLanguage();
    final dateKey = dateKeyFor(date);
    final duaIndex =
        _indexFor(dateKey, RamadanSuggestionType.dua, pools.duas.length);
    final ayetIndex =
        _indexFor(dateKey, RamadanSuggestionType.ayet, pools.ayetler.length);
    final iyilikIndex =
        _indexFor(dateKey, RamadanSuggestionType.iyilik, pools.iyilikler.length);

    return RamadanSuggestionsBundle(
      dateKey: dateKey,
      duaIndex: duaIndex,
      ayetIndex: ayetIndex,
      iyilikIndex: iyilikIndex,
      dua: _mapToItem(RamadanSuggestionType.dua, pools.duas[duaIndex]),
      ayet: _mapToItem(RamadanSuggestionType.ayet, pools.ayetler[ayetIndex]),
      iyilik:
          _mapToItem(RamadanSuggestionType.iyilik, pools.iyilikler[iyilikIndex]),
    );
  }

  static Future<RamadanSuggestionsBundle> getTodayBundle({
    DateTime? now,
  }) async {
    final pools = _contentPoolsForActiveLanguage();
    final date = now ?? DateTime.now();
    final dateKey = dateKeyFor(date);

    final cached = LocalPreferencesService.getRamadanSuggestionSelection();
    if (cached != null &&
        cached.dateKey == dateKey &&
        cached.duaIndex >= 0 &&
        cached.duaIndex < pools.duas.length &&
        cached.ayetIndex >= 0 &&
        cached.ayetIndex < pools.ayetler.length &&
        cached.iyilikIndex >= 0 &&
        cached.iyilikIndex < pools.iyilikler.length) {
      return RamadanSuggestionsBundle(
        dateKey: dateKey,
        duaIndex: cached.duaIndex,
        ayetIndex: cached.ayetIndex,
        iyilikIndex: cached.iyilikIndex,
        dua: _mapToItem(RamadanSuggestionType.dua, pools.duas[cached.duaIndex]),
        ayet:
            _mapToItem(RamadanSuggestionType.ayet, pools.ayetler[cached.ayetIndex]),
        iyilik: _mapToItem(
          RamadanSuggestionType.iyilik,
          pools.iyilikler[cached.iyilikIndex],
        ),
      );
    }

    final generated = deterministicBundleForDate(date);
    await LocalPreferencesService.setRamadanSuggestionSelection(
      dateKey: generated.dateKey,
      duaIndex: generated.duaIndex,
      ayetIndex: generated.ayetIndex,
      iyilikIndex: generated.iyilikIndex,
    );
    return generated;
  }

  static Future<void> refreshToday({DateTime? now}) async {
    final generated = deterministicBundleForDate(now ?? DateTime.now());
    await LocalPreferencesService.setRamadanSuggestionSelection(
      dateKey: generated.dateKey,
      duaIndex: generated.duaIndex,
      ayetIndex: generated.ayetIndex,
      iyilikIndex: generated.iyilikIndex,
    );
  }

  static Future<List<RamadanSuggestionFavorite>> getFavorites() async {
    final raw = LocalPreferencesService.getRamadanSuggestionFavoritesRaw();
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = decoded
          .whereType<Map>()
          .map((e) => RamadanSuggestionFavorite.fromJson(
              Map<String, dynamic>.from(e)))
          .where((e) => e.text.isNotEmpty)
          .toList(growable: false);
      items.sort((a, b) => b.savedAtIso.compareTo(a.savedAtIso));
      return items;
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> isFavorite(RamadanSuggestionItem item) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.matches(item));
  }

  static Future<void> toggleFavorite(RamadanSuggestionItem item) async {
    final favorites = List<RamadanSuggestionFavorite>.from(await getFavorites());
    final existingIndex = favorites.indexWhere((f) => f.matches(item));
    if (existingIndex >= 0) {
      favorites.removeAt(existingIndex);
    } else {
      favorites.insert(
        0,
        RamadanSuggestionFavorite(
          type: item.type,
          text: item.text,
          secondary: item.secondary,
          savedAtIso: DateTime.now().toIso8601String(),
        ),
      );
    }
    await _writeFavorites(favorites);
  }

  static Future<void> removeFavorite(RamadanSuggestionFavorite favorite) async {
    final favorites = List<RamadanSuggestionFavorite>.from(await getFavorites());
    favorites.removeWhere((f) =>
        f.type == favorite.type &&
        f.text == favorite.text &&
        (f.secondary ?? '') == (favorite.secondary ?? ''));
    await _writeFavorites(favorites);
  }

  static Future<void> _writeFavorites(
    List<RamadanSuggestionFavorite> favorites,
  ) async {
    final raw = jsonEncode(favorites.map((e) => e.toJson()).toList());
    await LocalPreferencesService.setRamadanSuggestionFavoritesRaw(raw);
  }

  static RamadanSuggestionItem _mapToItem(
    RamadanSuggestionType type,
    Map<String, String> raw,
  ) {
    final headerKey = switch (type) {
      RamadanSuggestionType.dua => 'ramadan_suggestion_card_dua',
      RamadanSuggestionType.ayet => 'ramadan_suggestion_card_ayet',
      RamadanSuggestionType.iyilik => 'ramadan_suggestion_card_iyilik',
    };
    return RamadanSuggestionItem(
      type: type,
      headerKey: headerKey,
      text: raw['text']?.trim() ?? '',
      secondary: raw['secondary']?.trim(),
    );
  }

  static int _indexFor(String dateKey, RamadanSuggestionType type, int length) {
    final input = '$dateKey:${type.name}';
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % length;
  }

  static _SuggestionContentPools _contentPoolsForActiveLanguage() {
    final lang = LocalPreferencesService.language.value.toLowerCase();
    if (lang == 'tr') {
      return const _SuggestionContentPools(
        duas: _duasTr,
        ayetler: _ayetlerTr,
        iyilikler: _iyiliklerTr,
      );
    }
    return const _SuggestionContentPools(
      duas: _duasEn,
      ayetler: _ayetlerEn,
      iyilikler: _iyiliklerEn,
    );
  }
}

class _SuggestionContentPools {
  const _SuggestionContentPools({
    required this.duas,
    required this.ayetler,
    required this.iyilikler,
  });

  final List<Map<String, String>> duas;
  final List<Map<String, String>> ayetler;
  final List<Map<String, String>> iyilikler;
}
