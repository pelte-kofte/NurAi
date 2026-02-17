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

## Next Prayer Home Widget (Flutter + iOS + Android)

This project now includes cross-platform "Next Prayer" widget plumbing.

### Data contract (shared payload)

Flutter computes a JSON payload and writes it through native `MethodChannel` (`nurai.widgets`):

```json
{
  "updatedAtEpochMs": 1700000000000,
  "locationLabel": "Current",
  "nextPrayerKey": "fajr",
  "nextPrayerLabel": "Fajr",
  "nextPrayerTime": "05:41",
  "countdownLabel": "in 1h 12m",
  "isNotificationsEnabled": true
}
```

### Storage keys

- Android: SharedPreferences file `nurai_widget_prefs`, key `next_prayer_payload`
- iOS: App Group UserDefaults suite `group.com.nurai.app` (with fallback to bundle-based group), key `next_prayer_payload`

### Flutter service

- `lib/data/widget_payload_service.dart`
- Public API:
  - `WidgetPayloadService.writeNextPrayerPayload()`
  - `WidgetPayloadService.refreshWidgets()`

Triggered from:
- app startup (`lib/main.dart`)
- app resume (`lib/main.dart`)
- prayer location updates (`lib/data/prayer_location_service.dart`)
- adhan enable/disable/reschedule (`lib/data/adhan_notification_service.dart`)
- adhan times bootstrap (`lib/features/adhan/adhan_times_screen.dart`)
- language change (`lib/features/settings/settings_screen.dart`)

### MethodChannel contract

Channel name: `nurai.widgets`

Methods:
- `setNextPrayerPayload` with arg `{ "payload": "<json string>" }`
- `refreshWidgets`

Implemented in:
- iOS: `ios/Runner/AppDelegate.swift`
- Android: `android/app/src/main/kotlin/com/example/nurai/MainActivity.kt`

### Android App Widget

Added:
- Provider: `android/app/src/main/kotlin/com/example/nurai/NextPrayerWidgetProvider.kt`
- Layout: `android/app/src/main/res/layout/next_prayer_widget.xml`
- Provider info: `android/app/src/main/res/xml/next_prayer_widget_info.xml`
- Backgrounds:
  - `android/app/src/main/res/drawable/next_prayer_widget_bg.xml`
  - `android/app/src/main/res/drawable/next_prayer_widget_pill_bg.xml`
- Strings: `android/app/src/main/res/values/strings.xml`
- Manifest receiver registration: `android/app/src/main/AndroidManifest.xml`

### iOS WidgetKit extension source files

Added source/templates:
- `ios/NurAiWidgets/NurAiWidgetsBundle.swift`
- `ios/NurAiWidgets/NextPrayerWidget.swift`
- `ios/NurAiWidgets/Info.plist`
- `ios/NurAiWidgets/NurAiWidgets.entitlements`

Runner App Group entitlement:
- `ios/Runner/Runner.entitlements`
- wired in `ios/Runner.xcodeproj/project.pbxproj`

### iOS setup in Xcode (required)

The extension source files are added in repo, but you still need to register the extension target in Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Add new target: `Widget Extension`, name it `NurAiWidgets`.
3. Attach existing files from `ios/NurAiWidgets/` to that target.
4. Enable **App Groups** capability in both targets:
   - `Runner`
   - `NurAiWidgets`
5. Use the same group in both (default used here): `group.com.nurai.app`.
   - Current Runner bundle id is `com.example.nurai`; if your app group policy uses bundle-based naming, set it to `group.com.example.nurai` and update both targets consistently.
6. Ensure extension Info.plist points to WidgetKit extension point and entitlements include the app group.

### Deep link behavior

- iOS widget uses `widgetURL("nurai://adhan")`.
- iOS URL scheme `nurai` is added in `ios/Runner/Info.plist`.
- Android widget click opens `MainActivity` with extra route hint `route=adhan`.
- If route handling is not yet implemented in Flutter, widgets still open the app safely.

### Testing checklist

1. Run app once and open prayer screen/location settings.
2. Change location (current/city), then return home.
3. Toggle prayer notifications ON/OFF.
4. Add Android widget from launcher and verify:
   - location label
   - next prayer label/time
   - countdown
   - notification status line
5. Add iOS widget from SpringBoard and verify the same fields.
6. Confirm widget updates after location or notification changes.

## Serverless Iftar Live Activity limitations

- This implementation is fully serverless (no push), so Live Activity reliability depends on the app being opened around iftar time.
- If the app is never opened during the `Maghrib - 60 min` to `Maghrib` window, the countdown may not start automatically.
- Local notifications still fire at `Maghrib - 60 min` and `Maghrib` (when notifications are enabled), and tapping the `Maghrib - 60 min` one triggers countdown start on app open.
- On app launch/resume, the app reevaluates current time and repairs stale state (start remaining countdown in-window, or end if Maghrib already passed).
