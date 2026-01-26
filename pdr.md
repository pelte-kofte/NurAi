# NurAI – Product Definition & Requirements

## Explore – Quran Reading

### Purpose
Allow users to freely read any surah and ayah without AI guidance,
tracking, or pressure.

### Scope
- Full surah list (1–114)
- Ayah-by-ayah reading
- Optional translation toggle
- Optional focused ayah reading mode

### Explicit Non-Goals
- No progress tracking
- No reading statistics
- No streaks or completion indicators
- No AI suggestions inside Explore

### User Flow
Explore →
Surah List →
Surah Detail (Ayahs) →
(Optional) Ayah Focus Mode

### Data Source
- Raw Quran JSON (AR / TR / EN)
- Read-only
- Offline-first


## 1. Product Vision
NurAI is a calm, private Islamic mobile application focused on
reflection, reading, and gentle spiritual companionship.
It avoids productivity pressure, gamification, and loud engagement tactics.

## 2. Core Principles
- Calm over engagement
- Silence over interruption
- Guidance over instruction
- Trust over metrics

## 3. Core User Journeys

### 3.1 Reading Journey (Explore)
Users can freely browse:
- Surahs (1–114)
- Ayahs within a Surah
This journey is AI-free and fully deterministic.

### 3.2 Daily Verse Journey
Users are shown one gentle verse per day from a curated NurAI pool.
This does not require AI.

### 3.3 Conversational Guidance Journey
Users may write freely.
The system detects emotional themes and suggests a relevant verse
from the curated NurAI ayah pool.
AI never generates ayahs or translations.

### 3.4 Surah Reading Intent
Users may optionally mark surahs they intend to read during
a specific spiritual period.
This is not tracked as progress or performance.
No streaks, percentages, or completion pressure are shown.

### 3.5 Prayer Time Reminders
Prayer notifications are optional and gentle.
Users may acknowledge or postpone a reminder.
No prayer completion history, streaks, or analytics are stored.

### 3.6 Qibla Direction
The app provides a simple qibla direction tool
using device sensors.
No data is stored or tracked.
The feature is purely functional and silent.


## 4. Content Architecture

### 4.1 Raw Quran Data
- Full Quran text (AR / TR / EN)
- Read-only
- No themes
- Used for reading only

### 4.2 NurAI Ayah Pool
- Selected ayahs only
- Tagged with themes and mood
- Used for daily verse and AI suggestions

## 5. AI Boundaries
AI:
- May detect themes
- May generate reflection prompts
- May suggest tone

AI must never:
- Generate Quran text
- Generate translations
- Modify ayah content

## 6. Notifications
- Optional
- Gentle language
- No urgency
- No streaks
- User-controlled

## 7. Non-Goals
- No gamification
- No streaks
- No progress tracking
- No leaderboards
- No habit pressure

## 8. MVP Scope (v1)
- Explore (Surah / Ayah reading)
- Home with Daily Verse
- NurAI Ayah Pool (10–20 ayahs)
- Basic conversational theme detection

## Home – Daily Presence

### Purpose
Home is a quiet entry point into the app.
It offers gentle companionship without urgency, pressure, or guidance.

### Core Elements

#### Daily Verse
- One verse is shown per day from the curated NurAI Ayah Pool.
- The verse is selected deterministically (date-based rotation).
- No AI is required for selection.
- The verse remains the same throughout the day.

#### Entry Points
- Continue to Explore (Qur’an reading)
- Open Reflection (optional, quiet)
- Access Settings

### Tone & Language
- Soft, invitational language
- No calls to action that imply urgency
- No productivity framing

### Explicit Non-Goals
- No streaks or daily completion indicators
- No “missed day” messaging
- No reminders to read if the user does not engage
- No analytics-driven personalization

### Data Source
- Daily Verse is sourced ONLY from `nurai_ayahs.json`
- Raw Quran data is NOT used here

### AI Boundaries
- AI is not involved in Daily Verse selection
- AI may later assist with optional reflection prompts, never verse content

### Persistence
- The same daily verse is shown for all sessions within the same calendar day
- A new verse is shown the next day

## Surah Reading Intent (Non-Goal Based)

### Purpose
Surah Reading Intent allows users to gently mark surahs they
intend to read during a specific spiritual period
(e.g. Ramadan, special nights, or a personal time frame).

This feature supports intention (niyet), not performance.

### How It Works
- Users may create a reading intent tied to a named period
  (e.g. “Ramadan 2026”).
- Users manually select one or more surahs.
- A surah may be marked as “read” by the user at any time.

### Data Handling
- All intent data is stored locally by default.
- No historical logs, statistics, or analytics are kept.
- No data is shared, compared, or visualized.

### UI Principles
- No percentages, progress bars, or completion ratios.
- No streaks or consecutive-day logic.
- No “behind”, “missed”, or “catch up” language.
- Completed surahs are shown quietly (e.g. subtle checkmark).

### Tone & Language
- Language must remain gentle and invitational.
- The system must never imply obligation or failure.
- Silence is preferred over reminders.

### Explicit Non-Goals
- No gamification
- No performance metrics
- No competitive or comparative elements
- No reminders based on incomplete intent

### Relationship to Explore
- Surah Reading Intent integrates with Explore.
- Users may mark a surah as read from the Surah Detail screen.
- Explore remains fully usable without any intent created.


## Collective Reading (Cüz Niyeti / Birlikte Okuma)

### Purpose

Collective Reading allows users to silently participate in a shared
Qur’an reading intention (e.g. Ramadan hatim),
without social pressure, visibility, or performance tracking.

The feature emphasizes shared niyet, not shared progress.

### Core Principles

- Reading remains individual
- Intention may be collective
- No obligation, no deadlines
- No visible progress comparison
- Silence is preferred over feedback

### Scope
- Primarily designed for Ramadan
- May be reused for other spiritual periods
- Fully optional
- Local-first by default

### Conceptual Model
- Collective Reading is based on Juz assignment, not surah completion.
- A Juz is treated as a reading range, not a UI object.

### Juz Structure (Critical Design Decision)
- A Juz:
  - May begin in the middle of a surah
  - May end in the middle of another surah
  - Is NOT represented as a standalone reading screen
  - Instead, a Juz exists only as a background ayah range.
      JuzRange {
        juzNumber: Int
        start: { surah, ayah }
        end: { surah, ayah }
      }

   - This structure is not exposed to the user.
     
### User Experience
- Users read Qur’an normally via Explore
- No special “Juz mode” UI
- No ayah labels indicating Juz boundaries
- No interruption to reading flow
If a user reads an ayah that falls within their assigned Juz range,
the system silently counts it toward the collective intention.

### Completion
- Users may optionally mark their Juz as completed
- The system responds only with a gentle acknowledgment:
    “Allah kabul etsin.”
- No celebration
- No statistics
- No automatic reassignment

### Visibility & Privacy
- Users cannot see:
  - Other participants
  - Completion status
  - Remaining Juz count
- The system never displays:
  - Percentages
  - Progress bars
  -Timelines

### Relationship to Explore
- Explore remains fully usable without Collective Reading
- Collective Reading never alters Explore behavior
- Users may complete or ignore their assigned Juz without consequence

### Explicit Non-Goals
- No group chat
- No leaderboard
- No public hatim status
- No reminders based on incomplete reading
- No forced continuation

END.
