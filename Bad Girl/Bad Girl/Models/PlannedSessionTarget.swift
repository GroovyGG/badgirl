import Foundation
import SwiftData

/// Links a PlannedSession to the MovementTargets intended for that session.
@Model
final class PlannedSessionTarget {
    var id: UUID = UUID()
    /// 1–5
    var focusLevel: Int? = nil
    var note: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var plannedSession: PlannedSession? = nil
    var movementTarget: MovementTarget? = nil

    init(plannedSession: PlannedSession, movementTarget: MovementTarget, focusLevel: Int? = nil) {
        self.plannedSession = plannedSession
        self.movementTarget = movementTarget
        self.focusLevel = focusLevel
    }
}
