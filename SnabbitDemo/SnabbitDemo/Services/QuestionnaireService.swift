import Foundation
import FirebaseFirestore

// MARK: - Questionnaire Service Protocol
protocol OnboardingQuestionnaireServiceProtocol {
    func submitQuestionnaire(_ response: QuestionnaireResponse) async throws
    func fetchQuestionnaire(for userId: String) async throws -> QuestionnaireResponse?
}

// MARK: - Firebase Questionnaire Service
final class FirebaseOnboardingQuestionnaireService: OnboardingQuestionnaireServiceProtocol {
    private let db = Firestore.firestore()
    private let collectionName = "questionnaire_responses"
    
    func submitQuestionnaire(_ response: QuestionnaireResponse) async throws {
        let data: [String: Any] = ["userId": response.userId,
                                   "selectedTasks": response.selectedTasks,
                                   "hasSmartphone": response.hasSmartphone as Any,
                                   "canGetPhone": response.canGetPhone as Any,
                                   "hasUsedGoogleMaps": response.hasUsedGoogleMaps as Any,
                                   "dateOfBirth": [
                                    "day": response.dateOfBirth?.day ?? "",
                                    "month": response.dateOfBirth?.month ?? "",
                                    "year": response.dateOfBirth?.year ?? ""
                                   ],
                                   "submittedAt": FieldValue.serverTimestamp()]
        
        try await db.collection(collectionName)
            .document(response.userId)
            .setData(data, merge: true)
    }
    
    func fetchQuestionnaire(for userId: String) async throws -> QuestionnaireResponse? {
        let doc = try await db.collection(collectionName).document(userId).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        
        var response = QuestionnaireResponse(userId: userId)
        response.selectedTasks = data["selectedTasks"] as? [String] ?? []
        response.hasSmartphone = data["hasSmartphone"] as? Bool
        response.canGetPhone = data["canGetPhone"] as? Bool
        response.hasUsedGoogleMaps = data["hasUsedGoogleMaps"] as? Bool
        
        if let dob = data["dateOfBirth"] as? [String: String] {
            response.dateOfBirth = DateOfBirth(day: dob["day"] ?? "",
                                               month: dob["month"] ?? "",
                                               year: dob["year"] ?? "")
        }
        return response
    }
}
