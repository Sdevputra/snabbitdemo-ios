import Foundation
import Observation
import FirebaseAuth

// MARK: - Break Screen State
// Drives what the home screen renders — keeps the View free of if/else logic.
enum BreakState: Equatable {
    case loading
    case idle                         // no schedule found
    case upcoming(startsIn: String)   // schedule exists but hasn't started yet
    case active                       // break is running right now
    case ended                        // break window just finished (or ended early)
}

// MARK: - Break ViewModel
@MainActor
@Observable
final class BreakViewModel {
    // MARK: - State
    var breakState: BreakState = .loading
    var activeSchedule: BreakSchedule? = nil
    var allSchedules: [BreakSchedule] = []
    var errorMessage: String? = nil
    var showEndBreakConfirmation: Bool = false
    var remainingSeconds: Int = 0
    var userName: String = "User"

    // MARK: - Dependencies
    private let breakService: BreakServiceProtocol
    private let authService: AuthServiceProtocol
    private weak var coordinator: BreakCoordinator?
    private var timerTask: Task<Void, Never>?

    init(coordinator: BreakCoordinator,
         breakService: BreakServiceProtocol = FirebaseBreakService(),
         authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.coordinator = coordinator
        self.breakService = breakService
        self.authService = authService
        // Uncomment below code to delete all the existng breaks.
        //deleteAllSchedules()
    }

    // MARK: - Load

    func loadBreakSchedules() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        userName = authService.currentUser?.username ?? "User"
        breakState = .loading
        stopTimer()
        
        Task {
            
            // Uncomment below code to add a break before fetching the breaks.
            /*
            do {
                let sch = try await breakService.seedMockBreak(for: userId)
            } catch {
                print(error)
            }
            */
            
            do {
                let schedules = try await breakService.fetchBreakSchedules(for: userId)
                allSchedules = schedules

                // Only the first schedule (sorted by startHour→startMinute) is acted on
                guard let first = schedules.first else {
                    // No schedule at all — home screen shows idle state, no timer
                    activeSchedule = nil
                    breakState = .idle
                    return
                }

                activeSchedule = first

                if first.isActiveNow {
                    // We are inside the break window right now — start counting down
                    remainingSeconds = first.remainingSeconds
                    breakState = .active
                    startCountdownTimer()
                } else {
                    // Break is in the future — show when it will start, then auto-begin
                    remainingSeconds = first.remainingSeconds
                    breakState = .upcoming(startsIn: first.startLabel)
                    scheduleAutoStart(for: first)
                }
            } catch {
                errorMessage = "Failed to load break schedule."
                breakState = .idle
            }
        }
    }

    // MARK: - Timer

    /// Counts down remainingSeconds every second. When it hits 0, marks break as ended.
    private func startCountdownTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                remainingSeconds -= 1
            }
            guard !Task.isCancelled else { return }
            breakState = .ended
        }
    }

    /// Waits until the schedule's start time, then automatically transitions to active.
    private func scheduleAutoStart(for schedule: BreakSchedule) {
        timerTask?.cancel()
        timerTask = Task {
            let delay = schedule.startDateForToday().timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            // Transition: upcoming → active
            remainingSeconds = schedule.remainingSeconds
            breakState = .active
            startCountdownTimer()
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Actions

    func requestEndBreak() {
        showEndBreakConfirmation = true
    }

    func confirmEndBreak() {
        guard let userId = Auth.auth().currentUser?.uid, let schedule = activeSchedule else { return }

        showEndBreakConfirmation = false
        stopTimer()

        Task {
            do {
                try await breakService.endBreakEarly(for: userId, schedule: schedule)
                activeSchedule = nil
                allSchedules.removeAll { $0.id == schedule.id }
                breakState = .ended
            } catch {
                errorMessage = "Failed to end break. Please try again."
            }
        }
    }

    func cancelEndBreak() {
        showEndBreakConfirmation = false
    }
    
    /// Deletes every break schedule for the current user and resets the screen to idle.
    func deleteAllSchedules() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        stopTimer()
        Task {
            do {
                try await breakService.deleteAllBreakSchedules(for: userId)
                activeSchedule = nil
                allSchedules = []
                breakState = .idle
            } catch {
                errorMessage = "Failed to delete schedules. Please try again."
            }
        }
    }

    func logout() {
        stopTimer()
        coordinator?.logout()
    }

    // MARK: - Formatted Values

    var formattedCountdown: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var breakEndTimeFormatted: String {
        guard let schedule = activeSchedule else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: schedule.scheduledEndTime)
    }

    var timerProgress: Double {
        guard let schedule = activeSchedule, schedule.durationMinutes > 0 else { return 0 }
        let total = Double(schedule.durationMinutes * 60)
        let elapsed = total - Double(remainingSeconds)
        return max(0, min(1, elapsed / total))
    }
}
