import Foundation
import SwiftData

/// Links a DailyGoal to specific MovementTargets it aims to train.
@Model
final class DailyGoalTarget {
    var id: UUID = UUID()
    /// 1–5
    var focusLevel: Int? = nil
    var note: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var dailyGoal: DailyGoal? = nil
    var movementTarget: MovementTarget? = nil

    init(dailyGoal: DailyGoal, movementTarget: MovementTarget, focusLevel: Int? = nil) {
        self.dailyGoal = dailyGoal
        self.movementTarget = movementTarget
        self.focusLevel = focusLevel
    }
}
