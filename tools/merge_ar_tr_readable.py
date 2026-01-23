import json
from collections import defaultdict

AR = "../assets/quran/raw/quran_ar.json"
TR = "../assets/quran/raw/quran_tr_readable_clean.json"
OUT = "../assets/quran/final/quran_ar_tr.json"

with open(AR, "r", encoding="utf-8") as f:
    ar_data = json.load(f)

with open(TR, "r", encoding="utf-8") as f:
    tr_data = json.load(f)

# surelere göre grupla
ar_by_surah = defaultdict(list)
tr_by_surah = defaultdict(list)

for a in ar_data:
    ar_by_surah[a["surah"]].append(a["text"])

for t in tr_data:
    tr_by_surah[t["surah"]].append(t["text"])

final = []

for surah in ar_by_surah:
    ar_ayahs = ar_by_surah[surah]
    tr_ayahs = tr_by_surah.get(surah, [])

    if len(ar_ayahs) != len(tr_ayahs):
        print(f"⚠️ Surah {surah} ayet sayısı uyuşmuyor")
        continue

    for i in range(len(ar_ayahs)):
        final.append({
            "surah": surah,
            "ayah": i + 1,
            "ar": ar_ayahs[i],
            "tr_readable": tr_ayahs[i]
        })

with open(OUT, "w", encoding="utf-8") as f:
    json.dump(final, f, ensure_ascii=False, indent=2)

print(f"✅ Arapça + Türkçe okunur eşlendi → {OUT}")
