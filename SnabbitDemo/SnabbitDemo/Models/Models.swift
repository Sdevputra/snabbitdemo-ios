import Foundation

// MARK: - App State
enum AppState: String, Codable {
    case loggedOut
    case questionnairePending
    case completed
}

// MARK: - User Model
struct AppUser: Codable, Equatable {
    let uid: String
    let username: String
    var displayName: String { username }
}

// MARK: - Questionnaire Models
struct QuestionnaireResponse: Codable {
    var userId: String
    var selectedTasks: [String]
    var hasSmartphone: Bool?
    var canGetPhone: Bool?
    var hasUsedGoogleMaps: Bool?
    var dateOfBirth: DateOfBirth?
    var submittedAt: Date

    init(userId: String) {
        self.userId = userId
        self.selectedTasks = []
        self.hasSmartphone = nil
        self.canGetPhone = nil
        self.hasUsedGoogleMaps = nil
        self.dateOfBirth = nil
        self.submittedAt = Date()
    }
}

struct DateOfBirth: Codable, Equatable {
    var day: String
    var month: String
    var year: String

    var isValid: Bool {
        guard let d = Int(day), let m = Int(month), let y = Int(year),
              d >= 1, d <= 31,
              m >= 1, m <= 12,
              y >= 1900, y <= Calendar.current.component(.year, from: Date()) - 18
        else { return false }
        return true
    }
}

// MARK: - Task Options
enum HouseholdTask: String, CaseIterable, Codable, Identifiable {
    case cuttingVegetables = "Cutting vegetables"
    case sweeping = "Sweeping"
    case mopping = "Mopping"
    case cleaningBathrooms = "Cleaning bathrooms"
    case laundry = "Laundry"
    case washingDishes = "Washing dishes"
    case noneOfTheAbove = "None of the above"

    var id: String { rawValue }
}

// MARK: - Break Schedule
// One item in the server-side `users/{uid}/breaks` subcollection.
// startHour + startMinute are stored in 24-hr format (e.g. 14, 30 = 2:30 PM).
struct BreakSchedule: Codable, Identifiable, Equatable {
    let id: String
    let startHour: Int       // 0-23
    let startMinute: Int     // 0-59
    let durationMinutes: Int

    // MARK: Derived timing

    /// Concrete start Date built from today's calendar + stored hour/minute.
    /// If today's window has fully elapsed, returns the same slot for tomorrow.
    func startDateForToday() -> Date {
        let cal = Calendar.current
        let now = Date()
        var components = cal.dateComponents([.year, .month, .day], from: now)
        components.hour = startHour
        components.minute = startMinute
        components.second = 0
        guard let candidate = cal.date(from: components) else { return now }
        let endCandidate = candidate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return endCandidate < now
            ? cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            : candidate
    }

    var scheduledEndTime: Date {
        startDateForToday().addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    /// true when the current clock falls inside [startTime, endTime].
    var isActiveNow: Bool {
        let now = Date()
        return now >= startDateForToday() && now < scheduledEndTime
    }

    var remainingSeconds: Int {
        max(0, Int(scheduledEndTime.timeIntervalSince(Date())))
    }

    /// Human-readable 24-hr label, e.g. "14:30"
    var startLabel: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }
}

// MARK: - Break History Entry
// Written to `users/{uid}/break_history` when a break ends (naturally or early).
struct BreakHistoryEntry: Codable, Identifiable {
    let id: String
    let scheduleId: String
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let endedEarly: Bool
    let recordedAt: Date
}
