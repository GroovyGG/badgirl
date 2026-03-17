import Foundation
import SwiftData

/// A trainable physical quality or skill — e.g. lower_body_explosiveness, badminton_split_step.
/// sport == nil means general (non-sport-specific) training target.
@Model
final class MovementTarget {
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var displayNameZh: String? = nil
    /// strength, explosiveness, endurance, stability, mobility, skill, coordination
    var category: String? = nil
    /// lower_body, upper_body, core, full_body, movement, recovery
    var bodySystem: String? = nil
    var sideSpecific: Bool = false
    var isTestable: Bool = true
    var targetDescription: String? = nil
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil

    @Relationship(deleteRule: .cascade, inverse: \MovementTargetMuscle.movementTarget)
    var muscles: [MovementTargetMuscle] = []

    @Relationship(deleteRule: .nullify, inverse: \SessionTarget.movementTarget)
    var sessionTargets: [SessionTarget] = []

    @Relationship(deleteRule: .nullify, inverse: \DailyGoalTarget.movementTarget)
    var dailyGoalTargets: [DailyGoalTarget] = []

    init(code: String, name: String, trainingDomain: TrainingDomain, sport: Sport? = nil, category: String? = nil, bodySystem: String? = nil, displayNameZh: String? = nil, sortOrder: Int = 0) {
        self.code = code
        self.name = name
        self.trainingDomain = trainingDomain
        self.sport = sport
        self.category = category
        self.bodySystem = bodySystem
        self.displayNameZh = displayNameZh
        self.sortOrder = sortOrder
    }
}
