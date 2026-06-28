# Bug Standard

## Required Workflow

### 1. AUDIT ONLY
- no edits
- inspect files
- list root cause candidates
- list exact conditions
- list files involved

### 2. ROOT CAUSE CONFIRMATION
- confirm the most likely cause
- reject weaker causes
- explain why

### 3. MINIMAL FIX
- smallest safe change
- no broad refactor
- preserve logic unless needed
- run flutter analyze

### 4. REGRESSION AUDIT
- check affected flows
- check related state/cache/localization
- check old bug cannot recur

### 5. DEVICE TEST
- real iPhone test when iOS/widget/notification/purchase/location is affected
- simulator is not enough for widgets, permissions, purchases, notifications

## Additional Rules
- Do not jump from symptom to fix.
- State the exact condition that triggers the bug.
- Name the deciding file and function.
- Keep the fix narrow until the root cause is proven.
