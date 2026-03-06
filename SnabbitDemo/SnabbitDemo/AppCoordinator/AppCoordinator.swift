import SwiftUI
import Observation
import FirebaseAuth

// MARK: - App Route
enum AppRoute {
    case splash
    case login
    case questionnaire
    case breakScreen
}

// MARK: - App Coordinator
@MainActor
@Observable
final class AppCoordinator {
    var currentRoute: AppRoute = .splash

    private let authService: AuthServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    private let questionnaireService: OnboardingQuestionnaireServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService(),
         userDefaultsService: UserDefaultsServiceProtocol = UserDefaultsService(),
         questionnaireService: OnboardingQuestionnaireServiceProtocol = FirebaseOnboardingQuestionnaireService()) {
        self.authService = authService
        self.userDefaultsService = userDefaultsService
        self.questionnaireService = questionnaireService
        resolveInitialRoute()
    }

    // MARK: - Route Resolution

    /// Called on every cold launch.
    /// Step 1 — is there a logged-in Firebase session?
    ///   No  → Login screen
    ///   Yes → Step 2 — has the user completed onboarding?
    ///           No  → Questionnaire
    ///           Yes → Home (Break screen)
    ///
    /// Questionnaire completion is the single gate. Break schedules are irrelevant
    /// to routing — the break screen itself handles whether a break is active.
    private func resolveInitialRoute() {
        guard authService.isUserLoggedIn else {
            currentRoute = .login
            return
        }
        // Kick off async questionnaire check; show splash until resolved
        Task { await resolveRouteForLoggedInUser() }
    }

    private func resolveRouteForLoggedInUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            currentRoute = .login
            return
        }
        currentRoute = await questionnaireCompleted(for: uid) ? .breakScreen : .questionnaire
        print(currentRoute)
    }

    // MARK: - Navigation Actions

    func navigateTo(_ route: AppRoute) {
        currentRoute = route
    }

    /// Called immediately after successful sign-in / sign-up.
    /// Mirrors resolveRouteForLoggedInUser — same single gate.
    func handleLoginSuccess() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if await questionnaireCompleted(for: uid) {
            // Returning user who already finished onboarding
            navigateTo(.breakScreen)
        } else {
            // New user or incomplete onboarding
            navigateTo(.questionnaire)
        }
    }

    /// Called when the user taps Continue on the last questionnaire screen.
    func handleQuestionnaireComplete() {
        // UserDefaults acts as a fast-path cache so we avoid a Firestore
        // round-trip on the next cold launch for the common case.
        userDefaultsService.saveAppState(.completed)
        navigateTo(.breakScreen)
    }

    func handleLogout() {
        try? authService.signOut()
        userDefaultsService.saveAppState(.loggedOut)
        navigateTo(.login)
    }

    // MARK: - Helpers

    /// Checks questionnaire completion.
    /// Fast path: UserDefaults cache (.completed).
    /// Slow path: Firestore lookup (handles reinstalls / new devices).
    private func questionnaireCompleted(for uid: String) async -> Bool {
        // Fast path — local cache says done
        if userDefaultsService.savedAppState == .completed {
            return true
        }
        
        // Slow path — verify against Firestore (reinstall / cache cleared)
        let response = try? await questionnaireService.fetchQuestionnaire(for: uid)
        let completed = response != nil
        if completed {
            // Re-warm the local cache
            userDefaultsService.saveAppState(.completed)
        }
        return completed
    }
}

// MARK: - Coordinator View
struct CoordinatorView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Group {
            switch coordinator.currentRoute {
            case .splash:
                SplashView()
            case .login:
                LoginCoordinatorView()
            case .questionnaire:
                QuestionnaireCoordinatorView()
            case .breakScreen:
                BreakCoordinatorView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentRoute)
    }
}
