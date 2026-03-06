import Foundation

// MARK: - UserDefaults Service Protocol
protocol UserDefaultsServiceProtocol {
    var savedAppState: AppState { get }
    func saveAppState(_ state: AppState)
}

// MARK: - UserDefaults Service
final class UserDefaultsService: UserDefaultsServiceProtocol {
    private let defaults = UserDefaults.standard
    private let appStateKey = "app_state"

    var savedAppState: AppState {
        guard let raw = defaults.string(forKey: appStateKey),
              let state = AppState(rawValue: raw) else {
            return .loggedOut
        }
        return state
    }

    func saveAppState(_ state: AppState) {
        defaults.set(state.rawValue, forKey: appStateKey)
    }
}
