# Architecture Principles

## Ownership
- Home is navigation and daily entry only.
- Prayer Times owns prayer UI, not widget calculation.
- Widgets read shared App Group payloads.
- Quran owns Surah and Juz Journey.
- Reflection uses dataset content.
- Companion is emotional Islamic flow.
- Tasbih owns dhikr/custom/asmal modes.
- Premium owns purchase UI only, not purchase logic changes unless requested.

## Module Notes

### Home
- Home should guide, orient, and route.
- Keep it focused on daily spiritual entry points.

### Prayer Times
- Owns prayer screens, location-driven prayer display, and prayer-facing UI flows.
- Do not push widget-specific decision logic into prayer UI unless required.

### Widgets
- Widgets should consume shared payloads, not recompute large app flows independently.
- Shared App Group storage is the contract surface.

### Quran
- Owns reading, surah browsing, and Juz Journey.
- Quran-related progression should remain inside Quran domain boundaries.

### Reflection
- Reflection is content-led, dataset-backed, and spiritually concise.

### Companion
- Companion is a separate emotional flow and should not collapse into a generic reflection screen.

### Tasbih
- Owns dhikr, custom, and Asma-based counting/memorization modes.

### Premium
- Premium presentation can evolve.
- Purchase entitlement logic should stay isolated and only change when explicitly requested.

## Engineering Preference
- Preserve clear module ownership.
- Avoid feature bleed across screens.
- Prefer state contracts over hidden cross-feature assumptions.
