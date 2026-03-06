//
//  SnabbitDemoTests.swift
//  SnabbitDemoTests
//
//  Created by Shubham Sharma on 06/03/26.
//

import Testing
import Foundation
@testable import SnabbitDemo

// MARK: - Mock Services
// Shared across all test suites — defined once at file scope.

final class MockAuthService: AuthServiceProtocol {
    var isUserLoggedIn: Bool = false
    var currentUser: AppUser? = nil
    var signInResult: Result<AppUser, Error> = .success(AppUser(uid: "test-uid", username: "testuser"))
    var signUpResult: Result<AppUser, Error> = .success(AppUser(uid: "test-uid", username: "testuser"))

    func signIn(username: String, password: String) async throws -> AppUser {
        try signInResult.get()
    }
    func signUp(username: String, password: String) async throws -> AppUser {
        try signUpResult.get()
    }
    func signOut() throws {}
}

final class MockUserDefaultsService: UserDefaultsServiceProtocol {
    var savedAppState: AppState = .loggedOut
    func saveAppState(_ state: AppState) { savedAppState = state }
}

final class MockQuestionnaireService: OnboardingQuestionnaireServiceProtocol {
    var submitCalled = false
    var submitError: Error? = nil
    /// Non-nil → simulates a user who has already completed onboarding.
    var existingResponse: QuestionnaireResponse? = nil

    func submitQuestionnaire(_ response: QuestionnaireResponse) async throws {
        submitCalled = true
        if let error = submitError { throw error }
        existingResponse = response
    }
    func fetchQuestionnaire(for userId: String) async throws -> QuestionnaireResponse? {
        existingResponse
    }
}

final class MockBreakService: BreakServiceProtocol {
    var schedules: [BreakSchedule] = []
    var fetchError: Error? = nil
    var addError: Error? = nil
    var deleteError: Error? = nil
    var endEarlyCalled = false
    var seedCalled = false

    func fetchBreakSchedules(for userId: String) async throws -> [BreakSchedule] {
        if let error = fetchError { throw error }
        return schedules
    }
    func addBreakSchedule(for userId: String, startHour: Int, startMinute: Int, durationMinutes: Int) async throws -> BreakSchedule {
        if let error = addError { throw error }
        let s = BreakSchedule(id: UUID().uuidString, startHour: startHour, startMinute: startMinute, durationMinutes: durationMinutes)
        schedules.append(s)
        return s
    }
    func deleteBreakSchedule(for userId: String, scheduleId: String) async throws {
        if let error = deleteError { throw error }
        schedules.removeAll { $0.id == scheduleId }
    }
    func deleteAllBreakSchedules(for userId: String) async throws {
        schedules.removeAll()
    }
    func endBreakEarly(for userId: String, schedule: BreakSchedule) async throws {
        endEarlyCalled = true
        schedules.removeAll { $0.id == schedule.id }
    }
    func seedMockBreak(for userId: String) async throws -> BreakSchedule {
        seedCalled = true
        return try await addBreakSchedule(for: userId, startHour: 10, startMinute: 0, durationMinutes: 5)
    }
}

// MARK: - Helpers
@MainActor
private func makeAppCoordinator(loggedIn: Bool = false,
                                appState: AppState = .loggedOut,
                                questionnaireResponse: QuestionnaireResponse? = nil) -> (AppCoordinator, MockUserDefaultsService) {
    let auth = MockAuthService(); auth.isUserLoggedIn = loggedIn
    let defaults = MockUserDefaultsService(); defaults.savedAppState = appState
    let questionnaire = MockQuestionnaireService(); questionnaire.existingResponse = questionnaireResponse
    return (AppCoordinator(authService: auth, userDefaultsService: defaults, questionnaireService: questionnaire), defaults)
}

// MARK: - AppCoordinator Tests


// MARK: - LoginViewModel Tests

@Suite("LoginViewModel")
@MainActor
struct LoginViewModelTests {

    private func makeVM() -> LoginViewModel {
        LoginViewModel(coordinator: LoginCoordinator(), authService: MockAuthService())
    }

    @Test("canContinue is false when fields are empty")
    func canContinueFalseWhenEmpty() {
        #expect(makeVM().canContinue == false)
    }

    @Test("canContinue is true when username and password are valid")
    func canContinueTrueWhenValid() {
        let vm = makeVM()
        vm.username = "testuser"
        vm.password = "password123"
        #expect(vm.canContinue == true)
    }

    @Test("canContinue is false when password is too short")
    func canContinueFalseShortPassword() {
        let vm = makeVM()
        vm.username = "testuser"
        vm.password = "abc"
        #expect(vm.canContinue == false)
    }

    @Test("toggleReferralCode shows and hides the referral field")
    func toggleReferralCode() {
        let vm = makeVM()
        #expect(vm.showReferralField == false)
        vm.toggleReferralCode()
        #expect(vm.showReferralField == true)
        vm.toggleReferralCode()
        #expect(vm.showReferralField == false)
    }

    @Test("toggleReferralCode clears referral code when hiding")
    func toggleReferralCodeClearsValue() {
        let vm = makeVM()
        vm.toggleReferralCode()
        vm.referralCode = "ABC123"
        vm.toggleReferralCode()
        #expect(vm.referralCode.isEmpty)
    }

    @Test("clearError removes the error message")
    func clearErrorRemovesMessage() {
        let vm = makeVM()
        vm.errorMessage = "Something went wrong"
        vm.clearError()
        #expect(vm.errorMessage == nil)
    }
}

// MARK: - QuestionnaireViewModel Tests

@Suite("QuestionnaireViewModel")
@MainActor
struct QuestionnaireViewModelTests {

    private func makeVM() -> OnboardingQuestionnaireViewModel {
        OnboardingQuestionnaireViewModel(coordinator: OnboardingQuestionnaireCoordinator(), questionnaireService: MockQuestionnaireService())
    }

    @Test("toggleTask adds and removes a task")
    func toggleTaskAddsAndRemoves() {
        let vm = makeVM()
        vm.toggleTask("Mopping")
        #expect(vm.selectedTasks.contains("Mopping"))
        vm.toggleTask("Mopping")
        #expect(!vm.selectedTasks.contains("Mopping"))
    }

    @Test("selecting None of the Above clears other selections")
    func noneOfAboveClearsOthers() {
        let vm = makeVM()
        vm.toggleTask("Mopping")
        vm.toggleTask("Laundry")
        vm.toggleTask(HouseholdTask.noneOfTheAbove.rawValue)
        #expect(vm.selectedTasks == [HouseholdTask.noneOfTheAbove.rawValue])
    }

    @Test("selecting None of the Above again deselects it")
    func noneOfAboveTogglesOff() {
        let vm = makeVM()
        vm.toggleTask(HouseholdTask.noneOfTheAbove.rawValue)
        vm.toggleTask(HouseholdTask.noneOfTheAbove.rawValue)
        #expect(vm.selectedTasks.isEmpty)
    }

    @Test("selecting another task after None of the Above removes it")
    func taskAfterNoneRemovesNone() {
        let vm = makeVM()
        vm.toggleTask(HouseholdTask.noneOfTheAbove.rawValue)
        vm.toggleTask("Mopping")
        #expect(!vm.selectedTasks.contains(HouseholdTask.noneOfTheAbove.rawValue))
        #expect(vm.selectedTasks.contains("Mopping"))
    }

    @Test("setSmartphone(true) hides canGetPhone field")
    func setSmartphoneTrueHidesField() {
        let vm = makeVM()
        vm.setSmartphone(true)
        #expect(vm.showCanGetPhone == false)
        #expect(vm.hasSmartphone == true)
    }

    @Test("setSmartphone(false) shows canGetPhone field")
    func setSmartphoneFalseShowsField() {
        let vm = makeVM()
        vm.setSmartphone(false)
        #expect(vm.showCanGetPhone == true)
        #expect(vm.hasSmartphone == false)
    }

    @Test("setSmartphone(true) clears canGetPhone answer")
    func setSmartphoneTrueClearsCanGetPhone() {
        let vm = makeVM()
        vm.setSmartphone(false)
        vm.canGetPhone = true
        vm.setSmartphone(true)
        #expect(vm.canGetPhone == nil)
    }

    @Test("canContinue is false when questionnaire is incomplete")
    func canContinueFalseWhenIncomplete() {
        #expect(makeVM().canContinue == false)
    }

    @Test("canContinue is true when all fields are answered")
    func canContinueTrueWhenComplete() {
        let vm = makeVM()
        vm.hasSmartphone = true
        vm.hasUsedGoogleMaps = true
        vm.dobDay = "15"; vm.dobMonth = "06"; vm.dobYear = "1990"
        #expect(vm.canContinue == true)
    }

    @Test("canContinue requires canGetPhone when no smartphone")
    func canContinueRequiresCanGetPhone() {
        let vm = makeVM()
        vm.setSmartphone(false)          // shows canGetPhone field
        vm.hasUsedGoogleMaps = true
        vm.dobDay = "15"; vm.dobMonth = "06"; vm.dobYear = "1990"
        #expect(vm.canContinue == false) // canGetPhone still nil
        vm.canGetPhone = true
        #expect(vm.canContinue == true)
    }
}

// MARK: - BreakViewModel Tests

@Suite("BreakViewModel", .serialized)
@MainActor
struct BreakViewModelTests {

    private func makeVM(service: MockBreakService = MockBreakService()) -> BreakViewModel {
        BreakViewModel(coordinator: BreakCoordinator(), breakService: service, authService: MockAuthService())
    }

    @Test("formattedCountdown formats seconds as MM:SS")
    func formattedCountdownMMSS() {
        let vm = makeVM()
        vm.remainingSeconds = 162
        #expect(vm.formattedCountdown == "02:42")
    }

    @Test("formattedCountdown shows 00:00 at zero")
    func formattedCountdownZero() {
        let vm = makeVM()
        vm.remainingSeconds = 0
        #expect(vm.formattedCountdown == "00:00")
    }

    @Test("requestEndBreak shows confirmation dialog")
    func requestEndBreakShowsConfirmation() {
        let vm = makeVM()
        vm.requestEndBreak()
        #expect(vm.showEndBreakConfirmation == true)
    }

    @Test("cancelEndBreak hides confirmation dialog")
    func cancelEndBreakHidesConfirmation() {
        let vm = makeVM()
        vm.showEndBreakConfirmation = true
        vm.cancelEndBreak()
        #expect(vm.showEndBreakConfirmation == false)
    }

    @Test("timerProgress is 0 when no active schedule")
    func timerProgressZeroWithNoSchedule() {
        let vm = makeVM()
        vm.activeSchedule = nil
        #expect(vm.timerProgress == 0)
    }

    @Test("timerProgress is within [0, 1] when schedule is set")
    func timerProgressInBounds() {
        let vm = makeVM()
        let cal = Calendar.current; let now = Date()
        vm.activeSchedule = BreakSchedule(
            id: "t1",
            startHour: cal.component(.hour, from: now),
            startMinute: cal.component(.minute, from: now),
            durationMinutes: 1
        )
        vm.remainingSeconds = 30
        #expect(vm.timerProgress > 0)
        #expect(vm.timerProgress <= 1)
    }
}

// MARK: - BreakSchedule Model Tests

@Suite("BreakSchedule")
struct BreakScheduleTests {

    @Test("startLabel formats hour and minute with leading zeros")
    func startLabelFormats() {
        let s = BreakSchedule(id: "1", startHour: 9, startMinute: 5, durationMinutes: 30)
        #expect(s.startLabel == "09:05")
    }

    @Test("remainingSeconds is never negative")
    func remainingSecondsNonNegative() {
        let s = BreakSchedule(id: "1", startHour: 0, startMinute: 0, durationMinutes: 1)
        #expect(s.remainingSeconds >= 0)
    }

    @Test("isActiveNow is true when current time is inside the break window")
    func isActiveNowTrueInsideWindow() {
        let cal = Calendar.current; let now = Date()
        let s = BreakSchedule(
            id: "1",
            startHour: cal.component(.hour, from: now),
            startMinute: cal.component(.minute, from: now),
            durationMinutes: 60
        )
        #expect(s.isActiveNow == true)
    }

    @Test("isActiveNow is false when break is 5 hours in the future")
    func isActiveNowFalseForFutureBreak() {
        let future = Date().addingTimeInterval(5 * 3600)
        let cal = Calendar.current
        let s = BreakSchedule(
            id: "1",
            startHour: cal.component(.hour, from: future),
            startMinute: cal.component(.minute, from: future),
            durationMinutes: 30
        )
        #expect(s.isActiveNow == false)
    }

    @Test("startDateForToday returns a date with the correct hour and minute")
    func startDateForTodayHasCorrectComponents() {
        let s = BreakSchedule(id: "1", startHour: 14, startMinute: 30, durationMinutes: 60)
        let cal = Calendar.current
        let start = s.startDateForToday()
        // If today's window hasn't passed, hour/minute match exactly
        if s.isActiveNow || start > Date() {
            #expect(cal.component(.hour, from: start) == 14)
            #expect(cal.component(.minute, from: start) == 30)
        }
    }
}

// MARK: - MockBreakService CRUD Tests

@Suite("MockBreakService CRUD")
struct MockBreakServiceTests {

    @Test("add then fetch returns the added schedule")
    func addAndFetch() async throws {
        let s = MockBreakService()
        let added = try await s.addBreakSchedule(for: "uid", startHour: 9, startMinute: 0, durationMinutes: 30)
        let fetched = try await s.fetchBreakSchedules(for: "uid")
        #expect(fetched.count == 1)
        #expect(fetched.first?.id == added.id)
    }

    @Test("delete removes the schedule")
    func deleteRemovesSchedule() async throws {
        let s = MockBreakService()
        let added = try await s.addBreakSchedule(for: "uid", startHour: 9, startMinute: 0, durationMinutes: 30)
        try await s.deleteBreakSchedule(for: "uid", scheduleId: added.id)
        let fetched = try await s.fetchBreakSchedules(for: "uid")
        #expect(fetched.isEmpty)
    }

    @Test("deleteAll removes every schedule")
    func deleteAllRemovesAll() async throws {
        let s = MockBreakService()
        try await s.addBreakSchedule(for: "uid", startHour: 9, startMinute: 0, durationMinutes: 30)
        try await s.addBreakSchedule(for: "uid", startHour: 14, startMinute: 0, durationMinutes: 15)
        try await s.deleteAllBreakSchedules(for: "uid")
        #expect(s.schedules.isEmpty)
    }

    @Test("endBreakEarly removes the schedule and sets the flag")
    func endBreakEarlyRemovesAndFlags() async throws {
        let s = MockBreakService()
        let schedule = try await s.addBreakSchedule(for: "uid", startHour: 9, startMinute: 0, durationMinutes: 30)
        try await s.endBreakEarly(for: "uid", schedule: schedule)
        #expect(s.endEarlyCalled == true)
        #expect(s.schedules.isEmpty)
    }

    @Test("seedMockBreak adds one schedule and sets the seed flag")
    func seedAddsOneSchedule() async throws {
        let s = MockBreakService()
        let seeded = try await s.seedMockBreak(for: "uid")
        #expect(s.seedCalled == true)
        #expect(s.schedules.first?.id == seeded.id)
    }
}

// MARK: - DateOfBirth Validation Tests

@Suite("DateOfBirth Validation")
struct DateOfBirthTests {

    @Test("valid date of birth passes validation")
    func validDOB() {
        #expect(DateOfBirth(day: "15", month: "06", year: "1990").isValid == true)
    }

    @Test("day above 31 is invalid", arguments: ["32", "99", "0"])
    func invalidDay(day: String) {
        #expect(DateOfBirth(day: day, month: "06", year: "1990").isValid == false)
    }

    @Test("month above 12 is invalid", arguments: ["13", "99", "0"])
    func invalidMonth(month: String) {
        #expect(DateOfBirth(day: "15", month: month, year: "1990").isValid == false)
    }

    @Test("year within last 18 years is invalid")
    func tooRecentYear() {
        #expect(DateOfBirth(day: "15", month: "06", year: "2015").isValid == false)
    }

    @Test("empty fields are invalid")
    func emptyFields() {
        #expect(DateOfBirth(day: "", month: "", year: "").isValid == false)
    }

    @Test("non-numeric values are invalid")
    func nonNumericValues() {
        #expect(DateOfBirth(day: "ab", month: "cd", year: "efgh").isValid == false)
    }
}
