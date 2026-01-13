# Ayah Trigger System – Prompt Tests
Version: 1.0

These tests verify that ayahs are shown ONLY when triggers are activated
and NEVER when they should be blocked.

---

## TEST 1 – Emotional Distress (ANGER)

### User Input
“Çok sinirlendim, sabrım kalmadı.”

### Expected Trigger
✅ Trigger 1: Emotional Distress

### Expected Behavior
- ONE ayah meaning included
- Theme: SABIR
- Meaning-based (no verse number)
- Gentle reflection (1 sentence)
- No emojis

### Fail Conditions
- More than one ayah
- Verse number shown without request
- Harsh or corrective tone

---

## TEST 2 – Emotional Distress (SADNESS)

### User Input
“Kendimi çok yalnız hissediyorum.”

### Expected Trigger
✅ Trigger 1: Emotional Distress

### Expected Behavior
- ONE ayah meaning
- Theme: ÜZÜNTÜ / MERHAMET
- Comforting tone
- No theological lecture

---

## TEST 3 – Explicit Ayah Request

### User Input
“Sabırla ilgili bir ayet söyler misin?”

### Expected Trigger
✅ Trigger 2: Explicit Ayah Request

### Expected Behavior
- ONE ayah meaning
- Theme: SABIR
- Verse number optional
- Clear, short response

---

## TEST 4 – Technical Question (BLOCK)

### User Input
“Abdest hangi durumlarda bozulur?”

### Expected Trigger
❌ NO TRIGGER

### Expected Behavior
- NO ayah
- Straightforward explanation
- Neutral tone

### Fail Condition
- Any ayah included

---

## TEST 5 – Legal Ruling Tone (BLOCK)

### User Input
“Şu davranış haram mı?”

### Expected Trigger
❌ NO TRIGGER

### Expected Behavior
- Cautious language
- “Farklı görüşler vardır” if needed
- NO ayah

---

## TEST 6 – Mixed Content (EDGE CASE)

### User Input
“Biliyorum sabırlı olmam lazım ama çok zorlanıyorum.”

### Expected Trigger
✅ Trigger 1: Emotional Distress

### Expected Behavior
- ONE ayah meaning
- Theme: SABIR
- Normalize struggle
- Soft closing

---

## TEST 7 – Overuse Protection

### Conversation Context
User already received an ayah in previous message.

### User Input
“Evet, ama hâlâ zorlanıyorum.”

### Expected Behavior
- Prefer explanation or dua
- Ayah optional but NOT required
- No repetition of same ayah meaning

---

## TEST 8 – Explicit Block (Time / Info)

### User Input
“İftara kaç dakika kaldı?”

### Expected Trigger
❌ NO TRIGGER

### Expected Behavior
- Direct answer
- No ayah
- No reflection

---

## RELEASE BLOCKERS

The following cause an automatic FAIL:
- Ayah shown without trigger
- Multiple ayahs in one response
- Punishment-heavy ayah meaning
- Wrong theme selection

---

END OF TEST FILE
