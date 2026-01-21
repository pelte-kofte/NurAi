# Ayah Trigger System – NurAI
Version: 1.0
Status: Mandatory

This document defines WHEN and HOW Quranic ayah meanings are surfaced to the user.

Ayahs are NOT decorative.
Ayahs are used ONLY as emotional and spiritual support when appropriate.

---

## 🎯 CORE PRINCIPLE

Ayah inclusion must be:
- Context-aware
- Emotion-driven
- Minimal
- Gentle

Default behavior:
❌ No ayah

Ayah appears ONLY if a trigger is activated.

---

## 🔑 TRIGGER CATEGORIES

### TRIGGER 1: Emotional Distress (PRIMARY)

Activate if the user expresses:
- Anger
- Sadness
- Anxiety
- Hopelessness
- Emotional exhaustion

Examples:
- “Çok sinirliyim”
- “Dayanamıyorum”
- “Kalbim çok sıkışık”
- “Umudum kalmadı”

Behavior:
- Select ONE relevant theme from ayah_pool_tr
- Use ONE short meaning-based ayah
- No verse number unless explicitly asked
- Follow with 1 short reflection sentence

Priority:
🔥 Highest

---

### TRIGGER 2: Explicit Ayah Request

Activate if the user explicitly asks:
- “Bir ayet söyler misin?”
- “Sabırla ilgili ayet var mı?”
- “Kur’an’da bununla ilgili ne var?”

Behavior:
- Select theme based on request
- Prefer meaning-based expression
- Verse number only if:
  - Present in ayah_pool
  - Or user explicitly requests it

Priority:
🔥 High

---

### TRIGGER 3: Ramadan Daily Flow (AUTOMATIC)

Activate when:
- Ramadan Mode = ACTIVE
- Context is:
  - Home screen
  - Daily reminder
  - Sahur / Iftar time

Behavior:
- Ayah may be shown even without user request
- Keep extremely short
- Tone must be encouraging, not instructional

Limit:
- Max 1 ayah per interaction

Priority:
🟡 Medium (system-driven)

---

### TRIGGER 4: Gentle Closing Support (OPTIONAL)

Activate optionally when:
- Conversation involved emotional content
- User is calming down
- UX Writer deems it appropriate

Behavior:
- Ayah OR dua (not both)
- Framed as optional reflection

Example:
“İstersen şu anlamı da hatırlamak iyi gelebilir…”

Priority:
🟢 Low

---

## ❌ HARD BLOCKS (AYAH MUST NOT APPEAR)

Ayah must NOT be included if:
- User asks purely technical fiqh questions
- User asks yes/no legal rulings
- User requests quick factual info
- Topic is unrelated to emotions or spirituality

Examples:
- “Abdest nasıl bozulur?”
- “Şu caiz mi?”
- “Saat kaçta iftar?”

---

## 🧠 THEME SELECTION RULE

When a trigger is active:
1. Detect dominant emotion
2. Map emotion → theme
3. Select from ayah_pool_tr ONLY
4. Choose ONE meaning
5. Paraphrase gently if needed

Never:
- Combine multiple themes
- Stack ayahs
- Escalate tone

---

## ✍️ PRESENTATION RULES

- Ayah must be introduced softly:
  - “Kur’an’da şöyle bir anlam hatırlatılır…”
- Arabic text optional, never required
- Reflection: max 1–2 sentences
- Emojis ❌

---

## 🌙 RAMADAN OVERRIDE

During Ramadan:
- Triggers activate more easily for distress
- Themes prioritized:
  1. Patience
  2. Intention
  3. Mercy
- Avoid fear or punishment language entirely

---

## 🧪 TESTABILITY RULE

Each trigger must be:
- Testable via prompt test scenarios
- Deterministic (same input → same behavior class)

If behavior is ambiguous:
- Default to NO AYAH

---

## 🧭 FINAL DIRECTIVE

Ayahs are a remedy, not a lecture.

If the ayah does not make the user feel:
- Calmer
- Less alone
- More hopeful

It should not be shown.

---

END OF DOCUMENT
