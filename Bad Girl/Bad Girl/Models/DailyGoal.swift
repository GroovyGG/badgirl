import Foundation
import SwiftData

/// A training intention set for a specific day.
/// sport == nil means general training goal.
@Model
final class DailyGoal {
    var id: UUID = UUID()
    var goalDate: Date = Date()
    var title: String? = nil
    /// 1–5
    var priorityLevel: Int? = nil
    var isCompleted: Bool = false
    /// 1–10
    var completionScore: Int? = nil
    var note: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil

    @Relationship(deleteRule: .cascade, inverse: \DailyGoalTarget.dailyGoal)
    var goalTargets: [DailyGoalTarget] = []

    init(goalDate: Date, trainingDomain: TrainingDomain, sport: Sport? = nil, title: String? = nil) {
        self.goalDate = goalDate
        self.trainingDomain = trainingDomain
        self.sport = sport
        self.title = title
    }
}
