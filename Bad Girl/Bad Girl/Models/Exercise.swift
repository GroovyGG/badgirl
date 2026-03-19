import Foundation
import SwiftData

/// Catalog definition for exercises that can be recommended or logged.
@Model
final class Exercise {
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var displayNameZh: String? = nil
    /// mobility, stability, footwork, explosiveness, endurance, recovery, etc.
    var category: String? = nil
    /// weight_reps, time_count, max_reps, duration
    var recordType: String = "duration"
    /// low, medium, high
    var defaultIntensity: String? = nil
    var defaultDurationMinutes: Int? = nil
    var instructions: String? = nil
    var isActive: Bool = true
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil
    var movementTarget: MovementTarget? = nil

    @Relationship(deleteRule: .nullify, inverse: \ExerciseRecommendation.exercise)
    var recommendations: [ExerciseRecommendation] = []

    @Relationship(deleteRule: .nullify, inverse: \ExerciseLog.exercise)
    var logs: [ExerciseLog] = []

    init(
        code: String,
        name: String,
        recordType: String = "duration",
        trainingDomain: TrainingDomain? = nil,
        sport: Sport? = nil,
        movementTarget: MovementTarget? = nil,
        displayNameZh: String? = nil,
        sortOrder: Int = 0
    ) {
        self.code = code
        self.name = name
        self.recordType = recordType
        self.trainingDomain = trainingDomain
        self.sport = sport
        self.movementTarget = movementTarget
        self.displayNameZh = displayNameZh
        self.sortOrder = sortOrder
    }
}
