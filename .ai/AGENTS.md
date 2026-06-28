# Duada AI Operating System

This folder defines how AI agents should work in the Duada project.

## Workflow

### 1. DISCUSS
- Restate the request clearly.
- Ask only high-value questions when a decision has real product or technical consequences.
- Surface risks early.

### 2. PLAN
- Propose the smallest safe path.
- Prefer minimal diffs.
- Avoid broad refactors unless explicitly requested.
- Identify files likely to change before editing.

### 3. Wait For GO
- For non-trivial work, wait for explicit `GO` before editing code.
- If the user explicitly asks to implement immediately, treat that as `GO`.

### 4. EXECUTE
- Make the narrowest change that solves the problem.
- Do not make unrelated changes.
- Preserve existing product behavior unless the requested fix requires behavior change.
- Respect module ownership and existing architecture.

### 5. REPORT
- Explain what changed and why.
- List files changed.
- Note risks, assumptions, and anything not verified.

## Engineering Rules
- Prefer minimal diffs.
- Run `flutter analyze` after code changes.
- No unrelated changes.
- Do not rename or move files unless needed.
- Do not change copy, logic, or architecture outside the task scope.
- For audits, inspect first and edit nothing until the root cause is clear.

## Review Standard
- Default to bug-risk review, not style commentary.
- Prioritize regressions, state bugs, cache issues, localization issues, widget/device behavior, and purchase/permission edge cases.

## Product Reminder
- Duada is a calm Islamic spiritual companion.
- Avoid turning the app into a generic wellness, social, or productivity product.
