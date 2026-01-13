# UI Component Specification – NurAI
Version: 1.0

This document defines the REQUIRED UI components for NurAI
with a focus on calm interaction, low pressure, and gentle guidance.

This is NOT a visual design file.
This specification defines behavior, hierarchy, and interaction rules.

Visual styling (colors, fonts, branding) is intentionally excluded.

---

## 🧠 CORE UI PRINCIPLES

- Calm over attention
- Invitation over instruction
- Silence over noise
- User control over system control

Components must NEVER:
- Block user flow
- Demand action
- Create guilt or urgency

---

## 🟩 COMPONENT 1: AyahCard

### Purpose
Display a short Quranic ayah meaning as gentle spiritual support.

AyahCard is NOT:
- A chat message
- A lecture
- A mandatory interaction

---

### When AyahCard is Rendered

AyahCard MUST be shown ONLY if:

- Screen == Home AND dailyAyahAvailable == true  
OR
- Screen == Chat AND ayahTriggerActive == true  
OR
- RamadanMode == true AND context == sahur/iftar/home

AyahCard MUST NOT be shown if:
- User disabled ayah cards
- User explicitly declined ayah content
- Last ayah card was shown within the last 12 hours

---

### Content Structure

Visual hierarchy (top → bottom):

1. Soft label (optional)
   - Example: “Bugün için küçük bir hatırlatma”

2. Ayah meaning (primary content)
   - One short meaning-based ayah
   - No verse number unless explicitly requested

3. Short reflection (optional)
   - Maximum 1 sentence
   - Calm, non-instructional tone

4. Actions (optional)
   - “Sonra”
   - “Kapat”

---

### Interaction Rules

- “Sonra”:
  - Hide AyahCard for 12 hours

- “Kapat”:
  - Hide AyahCard for the rest of the day

- No swipe dismissal required
- No forced interaction

---

### Accessibility Rules

- Text must be readable at default system font size
- No flashing or motion-heavy animations
- High contrast preferred, but soft

---

## 🟦 COMPONENT 2: ReadingCard

### Purpose
Encourage gentle Quran reading without pressure or tracking anxiety.

ReadingCard is a suggestion, not a task.

---

### When ReadingCard is Rendered

ReadingCard MAY be shown if:
- User has not marked reading today
- Notification system indicates reading reminder eligibility

ReadingCard MUST NOT be shown if:
- User already marked reading today
- User disabled reading reminders
- User dismissed ReadingCard earlier the same day

---

### Content Structure

Visual hierarchy:

1. Prompt text
   - Example: “Bugün Kur’an ile temas ettin mi?”

2. Primary actions
   - “Okudum”
   - “Sonra”

3. Optional helper text
   - Example: “Birkaç ayet bile yeterli olabilir.”

---

### Interaction Rules

- “Okudum”:
  - Triggers reading tracker backend
  - Shows lightweight confirmation:
    - “Allah kabul etsin 🤍”
  - ReadingCard disappears

- “Sonra”:
  - Hide ReadingCard for the rest of the day

- No countdowns
- No streak indicators
- No progress bars

---

## 🧩 STATE DEPENDENCIES (FRONTEND)

The UI must rely on backend-provided state:

```json
{
  "ayahTriggerActive": boolean,
  "dailyAyahAvailable": boolean,
  "hasReadToday": boolean,
  "ramadanMode": boolean
}
```

Frontend MUST NOT infer spiritual state on its own.

---

## ❌ EXPLICIT NON-GOALS

UI components MUST NOT:
- Display streaks
- Show missed days
- Use warning or guilt language
- Push notifications directly
- Replace user intent with system intent

---

## 🧭 FINAL UI PRINCIPLE

If a component feels like pressure:
- Remove it
If a component feels like noise:
- Silence it

NurAI UI should feel like a quiet companion,
not a productivity tool.

---

END OF SPECIFICATION
