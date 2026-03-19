import Foundation
import SwiftData

@Model
final class Sport {
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var displayNameZh: String? = nil
    var iconName: String? = nil
    var colorToken: String? = nil
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \MovementTarget.sport)
    var movementTargets: [MovementTarget] = []

    @Relationship(deleteRule: .nullify, inverse: \TrainingSession.sport)
    var trainingSessions: [TrainingSession] = []

    @Relationship(deleteRule: .nullify, inverse: \MetricDefinition.sport)
    var metricDefinitions: [MetricDefinition] = []

    @Relationship(deleteRule: .nullify, inverse: \DailyGoal.sport)
    var dailyGoals: [DailyGoal] = []

    @Relationship(deleteRule: .nullify, inverse: \Exercise.sport)
    var exercises: [Exercise] = []

    init(code: String, name: String, displayNameZh: String? = nil, iconName: String? = nil, colorToken: String? = nil, sortOrder: Int = 0) {
        self.code = code
        self.name = name
        self.displayNameZh = displayNameZh
        self.iconName = iconName
        self.colorToken = colorToken
        self.sortOrder = sortOrder
    }
}
