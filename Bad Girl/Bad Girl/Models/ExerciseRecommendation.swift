import Foundation
import SwiftData

/// System-generated recommendation based on recent sessions/reflections/context.
@Model
final class ExerciseRecommendation {
    var id: UUID = UUID()
    var recommendedDate: Date = Date()
    var exerciseType: String? = nil
    var targetProblem: String? = nil
    /// low, medium, high
    var intensity: String? = nil
    var durationMinutes: Int? = nil
    var reason: String? = nil
    /// suggested | accepted | skipped | completed
    var status: String = "suggested"
    var acceptedAt: Date? = nil
    var skippedAt: Date? = nil
    var completedAt: Date? = nil
    /// unknown | improved | persisted
    var outcomeSignal: String = "unknown"
    var outcomeEvaluatedAt: Date? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var sourceSession: TrainingSession? = nil
    var sourceReflection: SessionReflection? = nil
    var exercise: Exercise? = nil
    var movementTarget: MovementTarget? = nil

    @Relationship(deleteRule: .nullify, inverse: \ExerciseLog.recommendation)
    var logs: [ExerciseLog] = []

    init(
        recommendedDate: Date = Date(),
        status: String = "suggested",
        sourceSession: TrainingSession? = nil,
        sourceReflection: SessionReflection? = nil,
        exercise: Exercise? = nil,
        movementTarget: MovementTarget? = nil
    ) {
        self.recommendedDate = recommendedDate
        self.status = status
        self.sourceSession = sourceSession
        self.sourceReflection = sourceReflection
        self.exercise = exercise
        self.movementTarget = movementTarget
    }
}
