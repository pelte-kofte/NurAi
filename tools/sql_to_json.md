# SQL to Raw Quran JSON Conversion

Goal:
Convert quran.sql into raw Quran JSON files
with the following format:

{
  "surah": number,
  "ayah": number,
  "text": string
}

Rules:
- Do not modify Quran text
- Preserve original order
- Output must be a JSON array
- No additional fields

Output files:
- quran_ar.json
- quran_tr.json
- quran_en.json
