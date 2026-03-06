import Foundation
import Observation

// MARK: - Login ViewModel
@MainActor
@Observable
final class LoginViewModel {
    // MARK: - Input
    var username: String = ""
    var password: String = ""
    var referralCode: String = ""
    var hasReferralCode: Bool = false

    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showReferralField: Bool = false

    // MARK: - Computed
    var canContinue: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6
    }

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private weak var coordinator: LoginCoordinator?

    init(coordinator: LoginCoordinator, authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.coordinator = coordinator
        self.authService = authService
        
        // Uncomment the below code to create a new user; later can be used to login
        /*
        Task {
            try await authService.signUp(username: "roja", password: "123456")
        }
        */
    }

    // MARK: - Actions
    func continueAction() {
        guard canContinue else { return }
        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                do {
                    _ = try await authService.signIn(username: username, password: password)
                } catch AuthError.userNotFound {
                    _ = try await authService.signUp(username: username, password: password)
                }
                coordinator?.loginSucceeded()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggleReferralCode() {
        hasReferralCode.toggle()
        showReferralField = hasReferralCode
        if !hasReferralCode { referralCode = "" }
    }

    func clearError() {
        errorMessage = nil
    }
}
