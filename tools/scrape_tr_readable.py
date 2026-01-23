import requests
from bs4 import BeautifulSoup
import json
import re
import time
from surah_slugs import SURAH_SLUGS

BASE_URL = "https://www.hafizefendi.com/turkce_kurani_kerim/{num:03d}-{slug}.html"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

OUTPUT_JSON = "../assets/quran/raw/quran_tr_readable.json"
all_ayahs = []

def clean(t):
    t = t.replace("\xa0", " ")
    t = re.sub(r"\s+", " ", t)
    return t.strip()

for surah, slug in SURAH_SLUGS.items():
    url = BASE_URL.format(num=surah, slug=slug)
    print(f"📖 {url}")

    r = requests.get(url, headers=HEADERS, timeout=10)
    if r.status_code != 200:
        print("❌ failed")
        continue

    soup = BeautifulSoup(r.text, "html.parser")
    font = soup.find("font")
    if not font:
        print("⚠️ font yok")
        continue

    lines = font.get_text("\n").split("\n")
    for line in lines:
        line = clean(line)
        m = re.match(r"(\d+)\.\s*(.+)", line)
        if m:
            all_ayahs.append({
                "surah": surah,
                "ayah": int(m.group(1)),
                "tr_readable": m.group(2)
            })

    time.sleep(0.7)

with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(all_ayahs, f, ensure_ascii=False, indent=2)

print(f"✅ {len(all_ayahs)} ayet yazıldı")
