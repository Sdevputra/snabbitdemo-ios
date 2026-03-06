import SwiftUI
import Observation

// MARK: - Break Coordinator
@MainActor
@Observable
final class BreakCoordinator {
    var navigationPath = NavigationPath()

    var onLogout: (() -> Void)?

    func logout() {
        onLogout?()
    }
}

// MARK: - Break Coordinator View
struct BreakCoordinatorView: View {
    @State private var coordinator = BreakCoordinator()
    @Environment(AppCoordinator.self) private var appCoordinator
    @State private var viewModel: BreakViewModel?

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            if let viewModel {
                BreakView(viewModel: viewModel)
                    .navigationBarHidden(true)
            }
        }
        .onAppear {
            coordinator.onLogout = { [weak appCoordinator] in
                appCoordinator?.handleLogout()
            }
            // Create BreakViewModel only on first appear
            if viewModel == nil {
                viewModel = BreakViewModel(coordinator: coordinator)
            }
        }
    }
}
