import re
import json

INPUT_SQL = "quran.sql"
OUTPUT_JSON = "../assets/quran/raw/quran_ar.json"

ayahs = []

# Regex: INSERT satırındaki değerleri yakalar
pattern = re.compile(
    r"\(\s*\d+\s*,\s*\d+\s*,\s*'(.+?)'\s*,\s*(\d+)\s*,\s*\d+\s*,\s*(\d+)\s*,",
    re.UNICODE
)

with open(INPUT_SQL, "r", encoding="utf-8") as f:
    content = f.read()

matches = pattern.findall(content)

for text, ayah_number, surah_id in matches:
    clean_text = text.lstrip("\ufeff")  # BOM temizle

    ayahs.append({
        "surah": int(surah_id),
        "ayah": int(ayah_number),
        "text": clean_text
    })

with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(ayahs, f, ensure_ascii=False, indent=2)

print(f"✅ {len(ayahs)} ayet JSON'a yazıldı → {OUTPUT_JSON}")

