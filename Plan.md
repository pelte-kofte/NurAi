# NurAI – Execution Plan

Version: 1.0  
Status: Active  
Owner: Solo Founder

---

## 🎯 PRIMARY GOAL

Build a production-ready MVP of an AI-powered Islamic mobile application with a strong Ramadan Mode, optimized for daily usage and spiritual habit formation.

---

## ⏳ TIME CONSTRAINT

- Total timeline: 30 days
- Solo development
- Fast iteration, no over-engineering

---

## 📦 MVP SCOPE (WHAT IS IN)

### Core Features
- AI-powered Islamic chat (text)
- Ramadan Mode
- Daily Ayah
- Daily Dua
- Basic user settings
- Subscription-ready architecture (no full paywall yet)

### Explicitly Out of Scope (v1)
- Video content
- Social features
- Community forums
- Advanced fiqh depth
- Offline mode

---

## 🧱 PHASE BREAKDOWN

### PHASE 1 – Foundation (Days 1–4)
**Goal:** Prepare AI brain and product scope

Tasks:
- Finalize claude.md
- Define sub-agents
- Write system & Ramadan prompts
- Lock MVP feature list

Deliverables:
- Stable AI behavior
- Prompt architecture ready

---

### PHASE 2 – UX & Flow (Days 5–7)
**Goal:** Clear user journey

Tasks:
- Define main screens:
  - Home
  - Chat
  - Ramadan
  - Profile
- Decide daily engagement loop
- Write UX microcopy (Islamic tone)

Deliverables:
- Screen flow diagram (text)
- UX copy draft

---

### PHASE 3 – AI Prompt System (Days 8–12)
**Goal:** Reliable, non-hallucinating AI responses

Tasks:
- Implement prompt chaining
- Integrate islamic_scholar.agent
- Add Ramadan override logic
- Add hallucination guard rules

Deliverables:
- Modular prompt files
- Sample Q&A tests

---

### PHASE 4 – Mobile MVP (Days 13–20)
**Goal:** Functional Flutter app

Tasks:
- App shell (Flutter)
- Firebase Auth
- Chat UI
- Home dashboard
- Ramadan screen

Deliverables:
- Running app
- Basic UI polish

---

### PHASE 5 – Monetization & Retention (Days 21–24)
**Goal:** Prepare for revenue

Tasks:
- Define premium features
- Subscription logic (soft)
- Daily reminder hooks
- Ramadan streak logic

Deliverables:
- Pricing plan
- Feature gating

---

### PHASE 6 – Testing & Polish (Days 25–28)
**Goal:** Reduce risk

Tasks:
- Manual QA
- Content sanity checks
- Edge case prompts
- Tone consistency review

Deliverables:
- Bug list resolved
- Stable build

---

### PHASE 7 – Launch Prep (Days 29–30)
**Goal:** Ready to ship

Tasks:
- Store listing copy
- Screenshots
- Soft launch checklist

Deliverables:
- Launch-ready app

---

## 📊 SUCCESS METRICS

- Daily Active Users (DAU)
- Session length > 3 minutes
- Ramadan Mode usage rate
- Premium interest clicks

---

## ⚠️ CONSTRAINTS & RISKS

- AI hallucination risk
- Religious sensitivity
- Over-feature creep
- Solo founder burnout

Mitigation:
- Keep answers short
- Avoid fatwa-style language
- Weekly scope review

---

## 🧠 CLAUDE USAGE RULE

Before generating code, Claude must:
1. Read claude.md
2. Read plan.md
3. Explain the plan step being executed
4. Only then generate output

If unclear:
- Ask one clarification question max.



# NurAI – Development Plan

## Phase 0 – Foundation (Current)
Status: In progress

- Product vision finalized
- PDR.md completed and frozen (v1)
- UI visual direction defined
- AI boundaries clearly defined

Goal:
Establish a clear, calm product foundation before any coding.

---

## Phase 1 – Core Reading Experience (MVP)
Status: Planned

- Prepare raw Quran data (AR / TR / EN)
- Implement Explore:
  - Surah list
  - Ayah reading
  - Translation toggle
  - Optional ayah focus mode

Goal:
Ensure the app functions as a reliable Quran reading experience.

---

## Phase 2 – Home & Daily Presence
Status: Planned

- Implement Home screen
- Daily Verse rotation from NurAI Ayah Pool
- Gentle navigation to Explore and Settings

Goal:
Create a calm entry point and daily spiritual presence.

---

## Phase 3 – Intentional Features
Status: Planned

- Surah Reading Intent (non-goal based)
- Ramadan / special period support
- Local-only data storage

Goal:
Support spiritual intention without performance pressure.

---

## Phase 4 – Guidance (AI-Assisted)
Status: Planned

- Theme detection from user input
- Verse suggestion from NurAI Ayah Pool
- Strict AI boundaries enforced

Goal:
Offer gentle guidance only when the user seeks it.

---

## Phase 5 – Utilities & Presence
Status: Planned

- Prayer time notifications
- Qibla direction tool

Goal:
Provide quiet, functional religious utilities.

---

## Phase 6 – Polish & Reflection
Status: Planned

- UI spacing and typography refinement
- Notification tone tuning
- Performance and accessibility improvements

Goal:
Polish the experience without adding new features.

---

END OF DOCUMENT
