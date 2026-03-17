import Foundation
import SwiftData

/// Records which MovementTargets were actually trained in a session, and how well.
@Model
final class SessionTarget {
    var id: UUID = UUID()
    /// 1–5: how much focus was placed on this target
    var focusLevel: Int? = nil
    /// 1–5: how well the target was completed
    var completionLevel: Int? = nil
    /// 1–10: quality of execution
    var qualityScore: Int? = nil
    /// 1–10: fatigue felt in this target
    var fatigueScore: Int? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingSession: TrainingSession? = nil
    var movementTarget: MovementTarget? = nil

    init(trainingSession: TrainingSession, movementTarget: MovementTarget) {
        self.trainingSession = trainingSession
        self.movementTarget = movementTarget
    }
}
