# NurAI – AI Core

NurAI is an AI-powered Islamic guidance system designed to support daily worship, reflection, and spiritual well-being — with a special focus on Ramadan.

This repository contains the **AI core logic** of the NurAI mobile application.
It does NOT include any mobile or backend application code.

---

## 🌙 What is NurAI?

NurAI is designed as:
- A gentle Islamic companion
- A daily reflection helper
- A Ramadan-focused spiritual guide

It prioritizes:
- Mercy over strictness
- Simplicity over complexity
- Habit-building over information overload

NurAI does **not** replace scholars and does **not** issue fatwas.

---

## 📦 What This Repository Contains

This repo includes:

- Global AI rules (`claude.md`)
- Execution roadmap (`plan.md`)
- Modular prompt system
- Sub-agent definitions (AI roles)
- Ramadan mode behavior

It represents the **“brain”** of the NurAI product.

---

## 🗂️ Repository Structure


nurai-ai-core/
│
├── claude.md              # Global AI constitution
├── plan.md                # Execution & delivery plan
│
├── agents/                # Sub-agent definitions
│   ├── islamic_scholar.agent.md
│   ├── mobile_dev.agent.md
│   ├── ux_writer.agent.md
│   └── product_manager.agent.md
│
├── prompts/               # Modular prompt system
│   ├── system.md
│   ├── ramadan.md
│   ├── chat.md
│   ├── dua.md
│   └── ayah.md
│
└── README.md
---

## 🧠 How the AI System Works

High-level flow:

1. User input is received
2. `system.md` defines core behavior
3. Mode-specific prompt (e.g. `ramadan.md`) overrides if active
4. Content is validated by `islamic_scholar.agent`
5. Tone is polished by `ux_writer.agent`
6. Final response is delivered

Each agent has a clearly defined responsibility and boundary.

---

## 🌙 Ramadan Mode

Ramadan Mode is a special behavioral override that:

- Prioritizes fasting-related guidance
- Encourages patience, mercy, and good character
- Adds time-aware responses (sahur / iftar)
- Avoids harsh or technical debates

Ramadan Mode is designed to feel:
> Supportive, calm, and human.

---

## 🔒 What This Repository Does NOT Include

- Mobile UI code (Flutter)
- Backend code (Firebase, APIs)
- Payment or subscription logic
- Analytics or tracking
- User data

These are intentionally kept separate.

---

## 🧪 Usage

This repository is intended to be used with:
- Claude Code
- Modular AI backends
- Prompt-aware AI pipelines

Typical usage:
```bash
git clone <repo>
cd nurai-ai-core
claude .
Claude Code will automatically load:
	•	Global rules
	•	Agents
	•	Prompts
	•	Execution plan

⸻

⚠️ Disclaimer

NurAI provides general Islamic guidance for educational and spiritual support purposes only.

It does not:
	•	Issue fatwas
	•	Replace scholars
	•	Provide legal, medical, or political advice

Users are encouraged to consult qualified scholars for personal rulings.

---

🧭 Vision

NurAI aims to be:
	•	Trustworthy
	•	Gentle
	•	Consistent
	•	Spiritually comforting

Every design decision should answer one question:

“Does this make the user feel calmer and closer to Allah?”

⸻

📄 License

License to be defined.
This repository may be private or partially open-sourced.

bismillah.

code

---
