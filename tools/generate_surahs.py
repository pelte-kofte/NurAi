import json
from collections import defaultdict
from pathlib import Path

# Paths
QURAN_AR_PATH = Path("../assets/quran/raw/quran_ar.json")
OUTPUT_PATH = Path("../assets/quran/meta/surahs.json")

# --- Static Surah Metadata (ilk 5 – test için) ---
SURAH_META = {
  1: {"name_ar": "الفاتحة", "name_tr": "Fâtiha", "name_en": "Al-Fatihah", "place": "Meccan"},
  2: {"name_ar": "البقرة", "name_tr": "Bakara", "name_en": "Al-Baqarah", "place": "Medinan"},
  3: {"name_ar": "آل عمران", "name_tr": "Âl-i İmrân", "name_en": "Aal-E-Imran", "place": "Medinan"},
  4: {"name_ar": "النساء", "name_tr": "Nisâ", "name_en": "An-Nisa", "place": "Medinan"},
  5: {"name_ar": "المائدة", "name_tr": "Mâide", "name_en": "Al-Ma'idah", "place": "Medinan"},
  6: {"name_ar": "الأنعام", "name_tr": "En‘âm", "name_en": "Al-An'am", "place": "Meccan"},
  7: {"name_ar": "الأعراف", "name_tr": "A‘râf", "name_en": "Al-A'raf", "place": "Meccan"},
  8: {"name_ar": "الأنفال", "name_tr": "Enfâl", "name_en": "Al-Anfal", "place": "Medinan"},
  9: {"name_ar": "التوبة", "name_tr": "Tevbe", "name_en": "At-Tawbah", "place": "Medinan"},
  10: {"name_ar": "يونس", "name_tr": "Yûnus", "name_en": "Yunus", "place": "Meccan"},
  11: {"name_ar": "هود", "name_tr": "Hûd", "name_en": "Hud", "place": "Meccan"},
  12: {"name_ar": "يوسف", "name_tr": "Yûsuf", "name_en": "Yusuf", "place": "Meccan"},
  13: {"name_ar": "الرعد", "name_tr": "Ra‘d", "name_en": "Ar-Ra'd", "place": "Medinan"},
  14: {"name_ar": "إبراهيم", "name_tr": "İbrâhîm", "name_en": "Ibrahim", "place": "Meccan"},
  15: {"name_ar": "الحجر", "name_tr": "Hicr", "name_en": "Al-Hijr", "place": "Meccan"},
  16: {"name_ar": "النحل", "name_tr": "Nahl", "name_en": "An-Nahl", "place": "Meccan"},
  17: {"name_ar": "الإسراء", "name_tr": "İsrâ", "name_en": "Al-Isra", "place": "Meccan"},
  18: {"name_ar": "الكهف", "name_tr": "Kehf", "name_en": "Al-Kahf", "place": "Meccan"},
  19: {"name_ar": "مريم", "name_tr": "Meryem", "name_en": "Maryam", "place": "Meccan"},
  20: {"name_ar": "طه", "name_tr": "Tâhâ", "name_en": "Ta-Ha", "place": "Meccan"},
  21: {"name_ar": "الأنبياء", "name_tr": "Enbiyâ", "name_en": "Al-Anbiya", "place": "Meccan"},
  22: {"name_ar": "الحج", "name_tr": "Hac", "name_en": "Al-Hajj", "place": "Medinan"},
  23: {"name_ar": "المؤمنون", "name_tr": "Mü’minûn", "name_en": "Al-Mu'minun", "place": "Meccan"},
  24: {"name_ar": "النور", "name_tr": "Nûr", "name_en": "An-Nur", "place": "Medinan"},
  25: {"name_ar": "الفرقان", "name_tr": "Furkân", "name_en": "Al-Furqan", "place": "Meccan"},
  26: {"name_ar": "الشعراء", "name_tr": "Şuarâ", "name_en": "Ash-Shu'ara", "place": "Meccan"},
  27: {"name_ar": "النمل", "name_tr": "Neml", "name_en": "An-Naml", "place": "Meccan"},
  28: {"name_ar": "القصص", "name_tr": "Kasas", "name_en": "Al-Qasas", "place": "Meccan"},
  29: {"name_ar": "العنكبوت", "name_tr": "Ankebût", "name_en": "Al-Ankabut", "place": "Meccan"},
  30: {"name_ar": "الروم", "name_tr": "Rûm", "name_en": "Ar-Rum", "place": "Meccan"},
  31: {"name_ar": "لقمان", "name_tr": "Lokmân", "name_en": "Luqman", "place": "Meccan"},
  32: {"name_ar": "السجدة", "name_tr": "Secde", "name_en": "As-Sajdah", "place": "Meccan"},
  33: {"name_ar": "الأحزاب", "name_tr": "Ahzâb", "name_en": "Al-Ahzab", "place": "Medinan"},
  34: {"name_ar": "سبإ", "name_tr": "Sebe’", "name_en": "Saba", "place": "Meccan"},
  35: {"name_ar": "فاطر", "name_tr": "Fâtır", "name_en": "Fatir", "place": "Meccan"},
  36: {"name_ar": "يس", "name_tr": "Yâsîn", "name_en": "Ya-Sin", "place": "Meccan"},
  37: {"name_ar": "الصافات", "name_tr": "Sâffât", "name_en": "As-Saffat", "place": "Meccan"},
  38: {"name_ar": "ص", "name_tr": "Sâd", "name_en": "Sad", "place": "Meccan"},
  39: {"name_ar": "الزمر", "name_tr": "Zümer", "name_en": "Az-Zumar", "place": "Meccan"},
  40: {"name_ar": "غافر", "name_tr": "Mü’min", "name_en": "Ghafir", "place": "Meccan"},
  41: {"name_ar": "فصلت", "name_tr": "Fussilet", "name_en": "Fussilat", "place": "Meccan"},
  42: {"name_ar": "الشورى", "name_tr": "Şûrâ", "name_en": "Ash-Shura", "place": "Meccan"},
  43: {"name_ar": "الزخرف", "name_tr": "Zuhruf", "name_en": "Az-Zukhruf", "place": "Meccan"},
  44: {"name_ar": "الدخان", "name_tr": "Duhân", "name_en": "Ad-Dukhan", "place": "Meccan"},
  45: {"name_ar": "الجاثية", "name_tr": "Câsiye", "name_en": "Al-Jathiyah", "place": "Meccan"},
  46: {"name_ar": "الأحقاف", "name_tr": "Ahkâf", "name_en": "Al-Ahqaf", "place": "Meccan"},
  47: {"name_ar": "محمد", "name_tr": "Muhammed", "name_en": "Muhammad", "place": "Medinan"},
  48: {"name_ar": "الفتح", "name_tr": "Fetih", "name_en": "Al-Fath", "place": "Medinan"},
  49: {"name_ar": "الحجرات", "name_tr": "Hucurât", "name_en": "Al-Hujurat", "place": "Medinan"},
  50: {"name_ar": "ق", "name_tr": "Kâf", "name_en": "Qaf", "place": "Meccan"},
  51: {"name_ar": "الذاريات", "name_tr": "Zâriyât", "name_en": "Adh-Dhariyat", "place": "Meccan"},
  52: {"name_ar": "الطور", "name_tr": "Tûr", "name_en": "At-Tur", "place": "Meccan"},
  53: {"name_ar": "النجم", "name_tr": "Necm", "name_en": "An-Najm", "place": "Meccan"},
  54: {"name_ar": "القمر", "name_tr": "Kamer", "name_en": "Al-Qamar", "place": "Meccan"},
  55: {"name_ar": "الرحمن", "name_tr": "Rahmân", "name_en": "Ar-Rahman", "place": "Medinan"},
  56: {"name_ar": "الواقعة", "name_tr": "Vâkıa", "name_en": "Al-Waqi'ah", "place": "Meccan"},
  57: {"name_ar": "الحديد", "name_tr": "Hadîd", "name_en": "Al-Hadid", "place": "Medinan"},
  58: {"name_ar": "المجادلة", "name_tr": "Mücâdele", "name_en": "Al-Mujadila", "place": "Medinan"},
  59: {"name_ar": "الحشر", "name_tr": "Haşr", "name_en": "Al-Hashr", "place": "Medinan"},
  60: {"name_ar": "الممتحنة", "name_tr": "Mümtehine", "name_en": "Al-Mumtahanah", "place": "Medinan"},
  61: {"name_ar": "الصف", "name_tr": "Saff", "name_en": "As-Saff", "place": "Medinan"},
  62: {"name_ar": "الجمعة", "name_tr": "Cum‘a", "name_en": "Al-Jumu'ah", "place": "Medinan"},
  63: {"name_ar": "المنافقون", "name_tr": "Münâfikûn", "name_en": "Al-Munafiqun", "place": "Medinan"},
  64: {"name_ar": "التغابن", "name_tr": "Tegâbün", "name_en": "At-Taghabun", "place": "Medinan"},
  65: {"name_ar": "الطلاق", "name_tr": "Talâk", "name_en": "At-Talaq", "place": "Medinan"},
  66: {"name_ar": "التحريم", "name_tr": "Tahrîm", "name_en": "At-Tahrim", "place": "Medinan"},
  67: {"name_ar": "الملك", "name_tr": "Mülk", "name_en": "Al-Mulk", "place": "Meccan"},
  68: {"name_ar": "القلم", "name_tr": "Kalem", "name_en": "Al-Qalam", "place": "Meccan"},
  69: {"name_ar": "الحاقة", "name_tr": "Hâkka", "name_en": "Al-Haqqah", "place": "Meccan"},
  70: {"name_ar": "المعارج", "name_tr": "Meâric", "name_en": "Al-Ma'arij", "place": "Meccan"},
  71: {"name_ar": "نوح", "name_tr": "Nûh", "name_en": "Nuh", "place": "Meccan"},
  72: {"name_ar": "الجن", "name_tr": "Cin", "name_en": "Al-Jinn", "place": "Meccan"},
  73: {"name_ar": "المزمل", "name_tr": "Müzzemmil", "name_en": "Al-Muzzammil", "place": "Meccan"},
  74: {"name_ar": "المدثر", "name_tr": "Müddessir", "name_en": "Al-Muddathir", "place": "Meccan"},
  75: {"name_ar": "القيامة", "name_tr": "Kıyâmet", "name_en": "Al-Qiyamah", "place": "Meccan"},
  76: {"name_ar": "الإنسان", "name_tr": "İnsân", "name_en": "Al-Insan", "place": "Medinan"},
  77: {"name_ar": "المرسلات", "name_tr": "Mürselât", "name_en": "Al-Mursalat", "place": "Meccan"},
  78: {"name_ar": "النبأ", "name_tr": "Neb’e", "name_en": "An-Naba", "place": "Meccan"},
  79: {"name_ar": "النازعات", "name_tr": "Nâzi‘ât", "name_en": "An-Nazi'at", "place": "Meccan"},
  80: {"name_ar": "عبس", "name_tr": "Abese", "name_en": "Abasa", "place": "Meccan"},
  81: {"name_ar": "التكوير", "name_tr": "Tekvîr", "name_en": "At-Takwir", "place": "Meccan"},
  82: {"name_ar": "الإنفطار", "name_tr": "İnfitâr", "name_en": "Al-Infitar", "place": "Meccan"},
  83: {"name_ar": "المطففين", "name_tr": "Mutaffifîn", "name_en": "Al-Mutaffifin", "place": "Meccan"},
  84: {"name_ar": "الإنشقاق", "name_tr": "İnşikâk", "name_en": "Al-Inshiqaq", "place": "Meccan"},
  85: {"name_ar": "البروج", "name_tr": "Bürûc", "name_en": "Al-Buruj", "place": "Meccan"},
  86: {"name_ar": "الطارق", "name_tr": "Târık", "name_en": "At-Tariq", "place": "Meccan"},
  87: {"name_ar": "الأعلى", "name_tr": "A‘lâ", "name_en": "Al-A'la", "place": "Meccan"},
  88: {"name_ar": "الغاشية", "name_tr": "Gâşiye", "name_en": "Al-Ghashiyah", "place": "Meccan"},
  89: {"name_ar": "الفجر", "name_tr": "Fecr", "name_en": "Al-Fajr", "place": "Meccan"},
  90: {"name_ar": "البلد", "name_tr": "Beled", "name_en": "Al-Balad", "place": "Meccan"},
  91: {"name_ar": "الشمس", "name_tr": "Şems", "name_en": "Ash-Shams", "place": "Meccan"},
  92: {"name_ar": "الليل", "name_tr": "Leyl", "name_en": "Al-Layl", "place": "Meccan"},
  93: {"name_ar": "الضحى", "name_tr": "Duha", "name_en": "Ad-Duha", "place": "Meccan"},
  94: {"name_ar": "الشرح", "name_tr": "İnşirâh", "name_en": "Ash-Sharh", "place": "Meccan"},
  95: {"name_ar": "التين", "name_tr": "Tîn", "name_en": "At-Tin", "place": "Meccan"},
  96: {"name_ar": "العلق", "name_tr": "Alak", "name_en": "Al-Alaq", "place": "Meccan"},
  97: {"name_ar": "القدر", "name_tr": "Kadr", "name_en": "Al-Qadr", "place": "Meccan"},
  98: {"name_ar": "البينة", "name_tr": "Beyyine", "name_en": "Al-Bayyinah", "place": "Medinan"},
  99: {"name_ar": "الزلزلة", "name_tr": "Zilzâl", "name_en": "Az-Zalzalah", "place": "Medinan"},
  100: {"name_ar": "العاديات", "name_tr": "Âdiyât", "name_en": "Al-Adiyat", "place": "Meccan"},
  101: {"name_ar": "القارعة", "name_tr": "Kâria", "name_en": "Al-Qari'ah", "place": "Meccan"},
  102: {"name_ar": "التكاثر", "name_tr": "Tekâsür", "name_en": "At-Takathur", "place": "Meccan"},
  103: {"name_ar": "العصر", "name_tr": "Asr", "name_en": "Al-Asr", "place": "Meccan"},
  104: {"name_ar": "الهمزة", "name_tr": "Hümeze", "name_en": "Al-Humazah", "place": "Meccan"},
  105: {"name_ar": "الفيل", "name_tr": "Fîl", "name_en": "Al-Fil", "place": "Meccan"},
  106: {"name_ar": "قريش", "name_tr": "Kureyş", "name_en": "Quraysh", "place": "Meccan"},
  107: {"name_ar": "الماعون", "name_tr": "Mâûn", "name_en": "Al-Ma'un", "place": "Meccan"},
  108: {"name_ar": "الكوثر", "name_tr": "Kevser", "name_en": "Al-Kawthar", "place": "Meccan"},
  109: {"name_ar": "الكافرون", "name_tr": "Kâfirûn", "name_en": "Al-Kafirun", "place": "Meccan"},
  110: {"name_ar": "النصر", "name_tr": "Nasr", "name_en": "An-Nasr", "place": "Medinan"},
  111: {"name_ar": "المسد", "name_tr": "Tebbet", "name_en": "Al-Masad", "place": "Meccan"},
  112: {"name_ar": "الإخلاص", "name_tr": "İhlâs", "name_en": "Al-Ikhlas", "place": "Meccan"},
  113: {"name_ar": "الفلق", "name_tr": "Felak", "name_en": "Al-Falaq", "place": "Meccan"},
  114: {"name_ar": "الناس", "name_tr": "Nâs", "name_en": "An-Nas", "place": "Meccan"}
}



# Load Quran ayahs
with open(QURAN_AR_PATH, "r", encoding="utf-8") as f:
    ayahs = json.load(f)

# Count ayahs per surah
surah_counts = defaultdict(int)
for ayah in ayahs:
    surah_counts[ayah["surah"]] += 1

# Build surahs.json
surahs = []
for surah_id in sorted(surah_counts.keys()):
    meta = SURAH_META.get(surah_id)
    if not meta:
        continue  # şimdilik sadece test sureleri

    surahs.append({
        "id": surah_id,
        "name_ar": meta["name_ar"],
        "name_tr": meta["name_tr"],
        "name_en": meta["name_en"],
        "ayah_count": surah_counts[surah_id],
        "revelation_place": meta["place"],
        "order": surah_id
    })

# Ensure output dir exists
OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

# Write file
with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
    json.dump(surahs, f, ensure_ascii=False, indent=2)

print(f"✅ surahs.json generated with {len(surahs)} surahs")
