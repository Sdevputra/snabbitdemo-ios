import Foundation
import FirebaseFirestore

// MARK: - Break Service Error
enum BreakServiceError: LocalizedError {
    case noSchedulesFound
    case invalidDocument
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noSchedulesFound: return "No break schedule found."
        case .invalidDocument:  return "Break data is malformed."
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - Break Service Protocol
protocol BreakServiceProtocol {
    /// Fetch all break schedules for a user. App uses the first one as the active break.
    func fetchBreakSchedules(for userId: String) async throws -> [BreakSchedule]

    /// Add a new break schedule. Returns the created schedule.
    func addBreakSchedule(for userId: String, startHour: Int, startMinute: Int, durationMinutes: Int) async throws -> BreakSchedule

    /// Delete a break schedule by id.
    func deleteBreakSchedule(for userId: String, scheduleId: String) async throws
    
    /// Delete all break schedules for a user in one call.
    func deleteAllBreakSchedules(for userId: String) async throws

    /// End the active break early and move it to break_history.
    func endBreakEarly(for userId: String, schedule: BreakSchedule) async throws

    // MARK: - Dev / Demo helpers
    /// Seeds a demo break starting ~1 minute from now for quick manual testing.
    func seedMockBreak(for userId: String) async throws -> BreakSchedule
}

// MARK: - Firebase Break Service
final class FirebaseBreakService: BreakServiceProtocol {
    private let db = Firestore.firestore()

    // Firestore paths:
    //   users/{uid}/breaks/{scheduleId}        — active schedule list
    //   users/{uid}/break_history/{entryId}    — historical records
    private func breaksCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("breaks")
    }

    private func historyCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("break_history")
    }

    // MARK: - Fetch
    func fetchBreakSchedules(for userId: String) async throws -> [BreakSchedule] {
        let snapshot = try await breaksCollection(for: userId)
            .order(by: "startHour")
            .order(by: "startMinute")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            parseSchedule(from: doc.data(), id: doc.documentID)
        }
    }

    // MARK: - Add
    func addBreakSchedule(for userId: String, startHour: Int, startMinute: Int, durationMinutes: Int) async throws -> BreakSchedule {
        let ref = breaksCollection(for: userId).document()
        let data: [String: Any] = ["startHour": startHour,
                                   "startMinute": startMinute,
                                   "durationMinutes": durationMinutes,
                                   "createdAt": FieldValue.serverTimestamp()
        ]
        try await ref.setData(data)
        return BreakSchedule(id: ref.documentID,
                             startHour: startHour,
                             startMinute: startMinute,
                             durationMinutes: durationMinutes
        )
    }

    // MARK: - Delete
    func deleteBreakSchedule(for userId: String, scheduleId: String) async throws {
        try await breaksCollection(for: userId).document(scheduleId).delete()
    }
    
    // MARK: - Delete All
    func deleteAllBreakSchedules(for userId: String) async throws {
        let snapshot = try await breaksCollection(for: userId).getDocuments()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for doc in snapshot.documents {
                group.addTask { try await doc.reference.delete() }
            }
            try await group.waitForAll()
        }
    }

    // MARK: - End Early
    func endBreakEarly(for userId: String, schedule: BreakSchedule) async throws {
        // Write to history
        let historyRef = historyCollection(for: userId).document()
        let historyData: [String: Any] = ["scheduleId": schedule.id,
                                          "startHour": schedule.startHour,
                                          "startMinute": schedule.startMinute,
                                          "durationMinutes": schedule.durationMinutes,
                                          "endedEarly": true,
                                          "recordedAt": FieldValue.serverTimestamp()
        ]
        try await historyRef.setData(historyData)
        // Remove from active schedules
        try await deleteBreakSchedule(for: userId, scheduleId: schedule.id)
    }

    // MARK: - Mock Seeder
    /// Adds a break whose window opens in ~30 seconds from now — handy for testing
    /// the auto-start flow without waiting for a real scheduled time.
    @discardableResult
    func seedMockBreak(for userId: String) async throws -> BreakSchedule {
        let cal = Calendar.current
        // Schedule starts 30 seconds from now so the timer kicks off immediately
        let startDate = Date().addingTimeInterval(45)
        let hour = cal.component(.hour, from: startDate)
        let minute = cal.component(.minute, from: startDate)
        return try await addBreakSchedule(for: userId,
                                          startHour: hour,
                                          startMinute: minute,
                                          durationMinutes: 2   // 5-minute demo break
        )
    }

    // MARK: - Private Helpers
    private func parseSchedule(from data: [String: Any], id: String) -> BreakSchedule? {
        guard
            let startHour = data["startHour"] as? Int,
            let startMinute = data["startMinute"] as? Int,
            let duration = data["durationMinutes"] as? Int
        else { return nil }
        return BreakSchedule(id: id,
                             startHour: startHour,
                             startMinute: startMinute,
                             durationMinutes: duration
        )
    }
}
