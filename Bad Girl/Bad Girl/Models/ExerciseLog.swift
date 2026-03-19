import Foundation
import SwiftData

/// Actual user execution record for an exercise.
/// Can be linked to a recommendation, but does not require one.
@Model
final class ExerciseLog {
    var id: UUID = UUID()
    var completedDate: Date = Date()
    var durationMinutes: Int? = nil
    /// low, medium, high
    var intensity: String? = nil
    var userFeedback: String? = nil

    // Type-dependent fields
    var weight: Double? = nil
    var reps: Int? = nil
    var sets: Int? = nil
    var durationSeconds: Int? = nil
    var count: Int? = nil
    var maxReps: Int? = nil
    var toFailure: Bool? = nil

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var recommendation: ExerciseRecommendation? = nil
    var trainingSession: TrainingSession? = nil
    var exercise: Exercise? = nil

    init(
        completedDate: Date = Date(),
        recommendation: ExerciseRecommendation? = nil,
        trainingSession: TrainingSession? = nil,
        exercise: Exercise? = nil
    ) {
        self.completedDate = completedDate
        self.recommendation = recommendation
        self.trainingSession = trainingSession
        self.exercise = exercise
    }
}
