# Reading Tracker Backend Specification – NurAI
Version: 1.0

This document defines the REQUIRED backend behavior
for tracking Quran reading activity in the NurAI application.

This system is designed for:
- Gentle encouragement
- Zero guilt
- No streak pressure
- Soft habit formation

This is NOT executable code.
This is an implementation specification to be used by Claude Code.

---

## 🎯 PURPOSE

Allow users to:
- Mark Quran reading activity
- Track progress gently
- Resume from where they left off

WITHOUT:
- Streak pressure
- Missed-day penalties
- Gamification stress

Reading is voluntary and private.

---

## 🧠 CORE PRINCIPLES

- No negative feedback
- No “you missed” messages
- No performance comparison
- Reading data belongs to the user

---

## 🗂️ REQUIRED DATA MODEL

Each user must have a persistent reading tracker state.

```json
{
  "lastReadAt": null | timestamp,
  "lastReadType": null | "ayah" | "page" | "juz",
  "lastReadReference": null | string,
  "readingHistory": [
    {
      "type": "ayah" | "page" | "juz",
      "reference": string,
      "timestamp": timestamp
    }
  ]
}
```

---

## 🧩 USER ACTIONS

### Action 1: Mark Reading as Done

Triggered when the user taps:
- “Okudum”
- “Bugün Kur’an ile temas ettim”

```pseudo
function markReading(user, type, reference):

    entry = {
        type: type,
        reference: reference,
        timestamp: now()
    }

    append entry to user.readingHistory

    user.lastReadAt = now()
    user.lastReadType = type
    user.lastReadReference = reference

    save(user)
```

---

### Action 2: Resume Reading

Triggered when the user opens:
- Home screen
- Reading screen
- Reminder deep link

```pseudo
function getResumePoint(user):

    if user.lastReadReference exists:
        return user.lastReadReference
    else:
        return null
```

UI decides how to present the resume point.

---

## 📅 DAILY BEHAVIOR RULES

- Reading can be marked multiple times per day
- No daily limits
- No daily requirements

The system MUST NOT:
- Expect daily reading
- Reset counters
- Create streaks
- Penalize inactivity

---

## 🔔 NOTIFICATION INTEGRATION

The reading tracker integrates with the notification system.

Backend MUST expose the following computed state:

```json
{
  "hasReadToday": boolean
}
```

Rules:
- If hasReadToday == true:
  - Reading reminder MUST NOT be sent
- If hasReadToday == false:
  - Reading reminder MAY be sent (per notification spec)

---

## 🧪 EDGE CASES

- Accidental marking:
  - Allow overwrite
  - Preserve history

- Long inactivity:
  - Resume from lastReadReference
  - No “you missed X days” logic

- User never reads:
  - No penalty
  - No forced reminders

---

## ❌ EXPLICIT NON-GOALS

The reading tracker MUST NOT:
- Track streaks
- Show missed days
- Compare users
- Rank progress
- Enforce goals

---

## 🧭 FINAL PRINCIPLE

The reading tracker should feel like:
“I returned gently, not because I was chased.”

If any feature introduces pressure:
- Remove it

---

END OF SPECIFICATION
