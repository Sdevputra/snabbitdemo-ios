import SwiftUI
import Observation

// MARK: - Questionnaire Coordinator
@MainActor
@Observable
final class OnboardingQuestionnaireCoordinator {
    var navigationPath = NavigationPath()

    var onComplete: (() -> Void)?

    func questionnaireCompleted() {
        onComplete?()
    }
}

// MARK: - Questionnaire Coordinator View
struct QuestionnaireCoordinatorView: View {
    @State private var coordinator = OnboardingQuestionnaireCoordinator()
    @Environment(AppCoordinator.self) private var appCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            QuestionnaireView(viewModel: OnboardingQuestionnaireViewModel(coordinator: coordinator))
                .navigationBarHidden(true)
        }
        .onAppear {
            coordinator.onComplete = { [weak appCoordinator] in
                appCoordinator?.handleQuestionnaireComplete()
            }
        }
    }
}
