# Flutter Architecture – NurAI

## Principles
- Calm, non-gamified Islamic app
- No streaks, no points, no charts
- Reading > productivity
- Silence preferred over notification

## Data
- Quran data loaded from assets
- JSON is the single source of truth
- Data loaded once and cached in memory

## State
- Simple Future-based state
- No heavy state management (no Redux, Bloc, Riverpod)
- Prefer Stateless + FutureBuilder

## Structure
- models/: pure data models
- data/: data loaders and selectors
- widgets/: small reusable UI components
- screens/: page-level widgets

## UX
- Small verse cards
- Soft transitions
- Minimal navigation
- No forced actions
