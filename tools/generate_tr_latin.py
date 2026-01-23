import json
import re
from pathlib import Path

# INPUT / OUTPUT
INPUT_TXT = Path("../assets/quran/source/quran_transliteration_en.txt")
OUTPUT_JSON = Path("../assets/quran/raw/quran_tr_latin.json")

OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)

def clean_text(text: str) -> str:
    # HTML-like tags <u> <b> vs temizle
    text = re.sub(r"<[^>]+>", "", text)
    # fazla boşlukları düzelt
    text = re.sub(r"\s+", " ", text)
    return text.strip().lower()

ayahs = []

with open(INPUT_TXT, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue

        # Format: surah|ayah|text
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue

        surah = int(parts[0])
        ayah = int(parts[1])
        text = clean_text(parts[2])

        ayahs.append({
            "surah": surah,
            "ayah": ayah,
            "latin": text
        })

with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(ayahs, f, ensure_ascii=False, indent=2)

print(f"✅ Generated {len(ayahs)} latin ayahs → {OUTPUT_JSON}")
