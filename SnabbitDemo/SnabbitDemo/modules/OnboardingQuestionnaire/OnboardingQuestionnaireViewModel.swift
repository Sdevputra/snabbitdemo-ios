import Foundation
import Observation
import FirebaseAuth

// MARK: - Questionnaire ViewModel
@MainActor
@Observable
final class OnboardingQuestionnaireViewModel {
    // MARK: - Questionnaire Answers
    var selectedTasks: Set<String> = []
    var hasSmartphone: Bool? = nil
    var canGetPhone: Bool? = nil
    var hasUsedGoogleMaps: Bool? = nil
    var dobDay: String = ""
    var dobMonth: String = ""
    var dobYear: String = ""

    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showCanGetPhone: Bool = false

    // MARK: - Computed
    var canContinue: Bool {
        hasSmartphone != nil &&
        hasUsedGoogleMaps != nil &&
        !dobDay.isEmpty && !dobMonth.isEmpty && !dobYear.isEmpty &&
        (hasSmartphone == true || canGetPhone != nil)
    }

    var allTasks: [HouseholdTask] { HouseholdTask.allCases }

    // MARK: - Dependencies
    private let questionnaireService: OnboardingQuestionnaireServiceProtocol
    private weak var coordinator: OnboardingQuestionnaireCoordinator?

    init(
        coordinator: OnboardingQuestionnaireCoordinator,
        questionnaireService: OnboardingQuestionnaireServiceProtocol = FirebaseOnboardingQuestionnaireService()
    ) {
        self.coordinator = coordinator
        self.questionnaireService = questionnaireService
    }

    // MARK: - Actions
    func toggleTask(_ task: String) {
        if task == HouseholdTask.noneOfTheAbove.rawValue {
            selectedTasks = selectedTasks.contains(task) ? [] : [task]
        } else {
            selectedTasks.remove(HouseholdTask.noneOfTheAbove.rawValue)
            if selectedTasks.contains(task) {
                selectedTasks.remove(task)
            } else {
                selectedTasks.insert(task)
            }
        }
    }

    func setSmartphone(_ value: Bool) {
        hasSmartphone = value
        showCanGetPhone = !value
        if value { canGetPhone = nil }
    }

    func submit() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        
        let dob = DateOfBirth(day: dobDay, month: dobMonth, year: dobYear)
        
        guard dob.isValid else {
            errorMessage = "Incorrect date of birth."
            isLoading = false
            return
        }

        var response = QuestionnaireResponse(userId: userId)
        response.selectedTasks = Array(selectedTasks)
        response.hasSmartphone = hasSmartphone
        response.canGetPhone = showCanGetPhone ? canGetPhone : nil
        response.hasUsedGoogleMaps = hasUsedGoogleMaps
        response.dateOfBirth = DateOfBirth(day: dobDay, month: dobMonth, year: dobYear)

        Task {
            defer { isLoading = false }
            do {
                try await questionnaireService.submitQuestionnaire(response)
                coordinator?.questionnaireCompleted()
            } catch {
                errorMessage = "Failed to submit. Please try again."
            }
        }
    }
}
