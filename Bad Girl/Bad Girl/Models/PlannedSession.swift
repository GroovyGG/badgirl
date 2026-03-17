import Foundation
import SwiftData

/// A training session planned for a future date on the calendar.
/// When completed, link to the actual TrainingSession via `actualSession`.
@Model
final class PlannedSession {
    var id: UUID = UUID()
    var plannedDate: Date = Date()
    /// training, game, gym, mobility, recovery, mixed
    var sessionType: String = "training"
    var estimatedDurationMinutes: Int? = nil
    /// 1–5
    var priority: Int = 3
    var note: String? = nil
    /// planned, completed, skipped
    var status: String = "planned"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil
    var actualSession: TrainingSession? = nil

    @Relationship(deleteRule: .cascade, inverse: \PlannedSessionTarget.plannedSession)
    var plannedTargets: [PlannedSessionTarget] = []

    init(plannedDate: Date, sessionType: String = "training", trainingDomain: TrainingDomain, sport: Sport? = nil, priority: Int = 3) {
        self.plannedDate = plannedDate
        self.sessionType = sessionType
        self.trainingDomain = trainingDomain
        self.sport = sport
        self.priority = priority
    }
}
