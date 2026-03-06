## Architecture

This project follows **MVVM-C** (Model–View–ViewModel–Coordinator).

- **Models** — plain Swift structs holding data (`BreakSchedule`, `QuestionnaireResponse`, etc.)
- **ViewModels** — `@Observable` classes that own state and business logic, one per screen
- **Views** — SwiftUI structs that read from their ViewModel and send actions back
- **Coordinators** — `@Observable` classes that own navigation state (`NavigationPath`) and wire screens together; the `AppCoordinator` is the single source of truth for which screen is visible

---

## App Flow

```
Launch
  └── SplashScreen (shown while auth status is resolved)
        ├── Not logged in          → Login
        ├── Logged in, no questionnaire → Questionnaire
        └── Logged in, questionnaire done → Break (Home)
```

On the Break screen, the app checks the user's break schedule:

| Condition | UI shown |
|---|---|
| No schedule found | Idle — "No break scheduled" |
| Schedule exists, hasn't started yet | Upcoming — countdown to start time |
| Inside the break window | Active — circular timer |
| Break window ended or ended early | Ended — checkmark message |

---

## Login

### Test Credentials

| Field | Value |
|---|---|
| Username | `raja` |
| Password | `123456` |

> There is no Sign Up UI. To create a new test account, see below.

### Creating a New User

Open `LoginViewModel.swift` and find the commented block near the top of `init`. Uncomment it, run the app once to create the account, then comment it back out.

```swift
// Uncomment the below code to create a new user; later can be used to login
/*
Task {
    try await authService.signUp(username: "roja", password: "123456")
}
*/
```

---

## Logout

Tap the **☰ menu icon** in the top-left corner of the Break screen.

---

## Testing Break Schedules

A user can have multiple `BreakSchedule` entries stored under `users/{uid}/breaks` in Firestore. There is no UI to manage them yet, so use the helpers below.

### Add a Break (seed a demo schedule)

Open `BreakViewModel.swift` and find `loadBreakSchedules()`. Uncomment the seed block to insert a 5-minute break starting ~30 seconds from now before the fetch runs:

```swift
// Uncomment below code to add a break before fetching the breaks.
/*
do {
    let _ = try await breakService.seedMockBreak(for: userId)
} catch {
    print(error)
}
*/
```

Run the app — the timer will start automatically once the 30-second window opens.

### Delete All Existing Breaks

In `BreakViewModel.swift`, find and uncomment the delete call at the top of `loadBreakSchedules()`:

```swift
// Uncomment below code to delete all the existing breaks.
// deleteAllSchedules()
```

Run the app once to clear all schedules, then comment it out again.
