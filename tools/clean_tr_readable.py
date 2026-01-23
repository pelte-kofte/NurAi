import json
import re

INPUT = "../assets/quran/raw/quran_tr_readable.json"
OUTPUT = "../assets/quran/raw/quran_tr_readable_clean.json"

with open(INPUT, "r", encoding="utf-8") as f:
    data = json.load(f)

cleaned = []

for item in data:
    text = item["text"]

    # 1.  2)  3-  4: gibi ayet numaralarını sil
    text = re.sub(r"^\s*\d+\s*[\.\)\-:]\s*", "", text)

    # parantez içlerini sil
    text = re.sub(r"\([^)]*\)", "", text)

    # fazla boşlukları temizle
    text = re.sub(r"\s+", " ", text).strip()

    cleaned.append({
        "surah": item["surah"],
        "text": text
    })

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(cleaned, f, ensure_ascii=False, indent=2)

print(f"✅ Ayet numaraları + parantezler temizlendi → {OUTPUT}")
