import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case userNotFound
    case weakPassword
    case emailInUse
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid username or password."
        case .networkError: return "Network error. Please check your connection."
        case .userNotFound: return "No account found. Please sign up."
        case .weakPassword: return "Password must be at least 6 characters."
        case .emailInUse: return "This account already exists. Try logging in."
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    var isUserLoggedIn: Bool { get }
    var currentUser: AppUser? { get }
    func signIn(username: String, password: String) async throws -> AppUser
    func signUp(username: String, password: String) async throws -> AppUser
    func signOut() throws
}

// MARK: - Firebase Auth Service
final class FirebaseAuthService: AuthServiceProtocol {
    private var db :Firestore {
        Firestore.firestore()
    }

    var isUserLoggedIn: Bool {
        Auth.auth().currentUser != nil
    }

    var currentUser: AppUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AppUser(uid: user.uid, username: user.displayName ?? user.email ?? "User")
    }

    // We use email-based auth but show "username" in UI
    // Username is stored as displayName and email is username@app.local
    func signIn(username: String, password: String) async throws -> AppUser {
        let email = makeEmail(from: username)
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return AppUser(uid: result.user.uid, username: username)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }

    func signUp(username: String, password: String) async throws -> AppUser {
        let email = makeEmail(from: username)
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()

            // Store user in Firestore
            let user = AppUser(uid: result.user.uid, username: username)
            try await saveUserToFirestore(user)
            return user
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Helpers
    private func makeEmail(from username: String) -> String {
        "\(username.lowercased())@snabbitdemo.local"
    }

    private func saveUserToFirestore(_ user: AppUser) async throws {
        try await db.collection("users").document(user.uid).setData([
            "uid": user.uid,
            "username": user.username,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    private func mapFirebaseError(_ error: NSError) -> AuthError {
        let code = AuthErrorCode(rawValue: error.code)
        switch code {
        case .wrongPassword, .invalidEmail, .invalidCredential:
            return .invalidCredentials
        case .userNotFound:
            return .userNotFound
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailInUse
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
