import SwiftUI
import Observation

// MARK: - Login Coordinator
@MainActor
@Observable
final class LoginCoordinator {
    var navigationPath = NavigationPath()

    // Async so AppCoordinator can await the Firestore questionnaire check
    var onLoginSuccess: (() async -> Void)?

    func loginSucceeded() {
        Task { await onLoginSuccess?() }
    }
}

// MARK: - Login Coordinator View
struct LoginCoordinatorView: View {
    @State private var coordinator = LoginCoordinator()
    @Environment(AppCoordinator.self) private var appCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            LoginView(viewModel: LoginViewModel(coordinator: coordinator))
                .navigationBarHidden(true)
        }
        .onAppear {
            coordinator.onLoginSuccess = { [weak appCoordinator] in
                await appCoordinator?.handleLoginSuccess()
            }
        }
    }
}
