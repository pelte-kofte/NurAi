# Notification Backend Specification – NurAI
Version: 1.0

This document defines the REQUIRED backend behavior
for all notification-related logic in the NurAI application.

This is NOT executable code.
This is an implementation specification to be used by Claude Code
when generating backend services (e.g. Firebase Cloud Functions).

---

## 🎯 PURPOSE

Send the right notification:
- To the right user
- At the right time
- With the right frequency
- Without causing notification fatigue

User peace and trust are higher priority than engagement metrics.

---

## 🧠 REQUIRED USER STATE (PER USER)

Each user must have a persistent notification state stored in the database.

```json
{
  "ramadanMode": boolean,
  "lastNotificationAt": timestamp,
  "dailyNotificationCount": number,
  "preferences": {
    "adhan": boolean,
    "reading": boolean,
    "specialDays": boolean
  }
}
```

---

## ⏰ SCHEDULER

A scheduled backend job MUST run periodically.

- Recommended interval: every 5 minutes
- This job evaluates notification eligibility for all active users

```pseudo
function notificationScheduler():
    currentTime = now()
    activeUsers = getActiveUsers()

    for each user in activeUsers:
        evaluateUserNotifications(user, currentTime)
```

---

## 🧠 NOTIFICATION EVALUATION LOGIC

```pseudo
function evaluateUserNotifications(user, currentTime):

    state = user.notificationState

    // GLOBAL BLOCKS
    if user.notificationsMuted == true:
        return

    if state.dailyNotificationCount >= 2:
        return

    // RAMADAN IFTAR NOTIFICATION
    if state.ramadanMode == true AND state.preferences.adhan == true:
        if isIftarApproaching(currentTime, user.location):
            if not sentRecently(state.lastNotificationAt):
                sendIftarNotification(user)
                updateNotificationState(user)
                return

    // DAILY QURAN READING REMINDER
    if state.preferences.reading == true:
        if isUserReadingTime(currentTime, user):
            if not sentToday(user, "readingReminder"):
                sendReadingReminder(user)
                updateNotificationState(user)
                return

    // INACTIVITY SOFT RETURN
    if userInactiveForDays(user, 3):
        if not sentRecently(state.lastNotificationAt):
            sendSoftReturnNotification(user)
            updateNotificationState(user)
            return
```

---

## 🧩 HELPER FUNCTIONS

```pseudo
function sentRecently(lastNotificationAt):
    return (now() - lastNotificationAt) < 6 hours

function updateNotificationState(user):
    user.notificationState.lastNotificationAt = now()
    user.notificationState.dailyNotificationCount += 1
    save(user)
```

---

## 📩 NOTIFICATION SENDERS

```pseudo
function sendIftarNotification(user):
    sendPush(
        title: "İftara az kaldı 🌙",
        body: "Bugün için küçük bir niyet hatırlatması iyi gelebilir."
    )

function sendReadingReminder(user):
    sendPush(
        title: "Kısa bir Kur’an molası",
        body: "Bugün için birkaç dakikalık bir durak yeterli olabilir."
    )

function sendSoftReturnNotification(user):
    sendPush(
        title: "Bir selam bırakıyoruz",
        body: "Ne zaman hazır hissedersen buradayız."
    )
```

---

## 🌙 DAILY RESET JOB

- Runs once per day (00:00 local time)

```pseudo
function resetDailyNotificationCounters():
    users = getAllUsers()

    for each user in users:
        user.notificationState.dailyNotificationCount = 0
        save(user)
```

---

## ❌ EXPLICIT NON-GOALS

The system MUST NOT:
- Send more than 2 notifications per day
- Send streak or guilt-based notifications
- Send multiple notifications in short succession
- Ignore user notification preferences

---

## 🧭 FINAL PRINCIPLE

If there is any doubt:
- Do NOT send the notification
- Silence is always safer than interruption

END OF SPECIFICATION
