import Foundation
import SwiftData

@Model
final class TrainingDomain {
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var displayNameZh: String? = nil
    var domainDescription: String? = nil
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \MovementTarget.trainingDomain)
    var movementTargets: [MovementTarget] = []

    @Relationship(deleteRule: .nullify, inverse: \TrainingSession.trainingDomain)
    var trainingSessions: [TrainingSession] = []

    @Relationship(deleteRule: .nullify, inverse: \MetricDefinition.trainingDomain)
    var metricDefinitions: [MetricDefinition] = []

    @Relationship(deleteRule: .nullify, inverse: \DailyGoal.trainingDomain)
    var dailyGoals: [DailyGoal] = []

    @Relationship(deleteRule: .nullify, inverse: \Exercise.trainingDomain)
    var exercises: [Exercise] = []

    init(code: String, name: String, displayNameZh: String? = nil, description: String? = nil, sortOrder: Int = 0) {
        self.code = code
        self.name = name
        self.displayNameZh = displayNameZh
        self.domainDescription = description
        self.sortOrder = sortOrder
    }
}
