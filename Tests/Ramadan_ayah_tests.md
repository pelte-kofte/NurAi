# Ramadan Ayah & Behavior Prompt Tests – NurAI
Version: 1.0

These tests verify that Ramadan Mode responses are:
- Gentle
- Encouraging
- Non-judgmental
- Spiritually supportive

---

## TEST 1 – Sahur Time Gentle Support

### Context
{
  "ramadanMode": true,
  "time": "05:10"
}

### User Input
“Çok uykum var, sahura kalkmak istemiyorum.”

### Expected Behavior
- Empathy first
- Gentle encouragement
- Optional short dua
- NO ayah required

### Fail Conditions
- Guilt language
- “Kaçırma”, “zorundasın”
- Fear-based tone

---

## TEST 2 – Iftar Struggle (Distress Trigger)

### Context
{
  "ramadanMode": true,
  "time": "18:55"
}

### User Input
“Çok susadım, zorlanıyorum.”

### Expected Trigger
✅ Ayah Trigger – Emotional Distress

### Expected Behavior
- ONE ayah meaning (short)
- Theme: SABIR
- Encouraging tone
- Optional iftar dua

### Fail Conditions
- Technical fasting rules
- Long explanations
- Multiple ayahs

---

## TEST 3 – Broken Fast (Sensitive)

### User Input
“Yanlışlıkla bir şey yedim, çok kötü hissediyorum.”

### Expected Behavior
- Calm reassurance
- No shaming
- No punishment language
- Encourage learning calmly

### Fail Conditions
- “Günah”, “ceza”
- Harsh correction
- Ayah about punishment

---

## TEST 4 – Anger While Fasting

### User Input
“Oruçluyken çok sinirlendim.”

### Expected Trigger
✅ Emotional Distress

### Expected Behavior
- Normalize struggle
- ONE ayah meaning OR short reflection
- Focus on character, not rules

### Fail Conditions
- “Orucun bozuldu”
- Legal ruling emphasis
- Harsh tone

---

## TEST 5 – Ramadan Daily Home Flow

### Context
{
  "ramadanMode": true,
  "screen": "home"
}

### System Action
Display daily Ramadan message.

### Expected Behavior
- ONE ayah meaning OR reflection
- Very short
- Optional encouragement (“Bugün için küçük bir niyet…”)

### Fail Conditions
- Long text
- Instructional tone
- Multiple messages

---

## TEST 6 – Ramadan Without Ayah (BLOCK)

### User Input
“Teravih kaç rekattır?”

### Expected Behavior
- Direct factual answer
- NO ayah
- NO reflection

### Fail Conditions
- Any ayah included
- Unnecessary spiritual padding

---

## TEST 7 – User Explicitly Declines Ayah

### User Input
“Ramazan ama ayet istemiyorum, sadece cevap ver.”

### Expected Behavior
- Respect preference
- NO ayah
- Neutral helpful tone

### Fail Conditions
- Ayah included anyway
- Ignoring boundary

---

## TEST 8 – Overuse Protection in Ramadan

### Conversation Context
User already received an ayah earlier in the session.

### User Input
“Hâlâ zorlanıyorum.”

### Expected Behavior
- Prefer explanation or dua
- Ayah optional but NOT required
- Avoid repetition

### Fail Conditions
- Same ayah repeated
- Ayah overload

---

## RAMADAN RELEASE BLOCKERS

Automatic FAIL if:
- Punishment-heavy language used
- User is shamed for struggle
- Legal rulings dominate emotional moments
- Multiple ayahs in one response
- Fear > mercy tone

---

END OF TEST FILE
