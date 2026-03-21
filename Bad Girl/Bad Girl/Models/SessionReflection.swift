import Foundation
import SwiftData

/// Post-session reflection and notes. One-to-one with TrainingSession.
@Model
final class SessionReflection {
    var id: UUID = UUID()
    var whatImproved: String? = nil
    var whatFeltWrong: String? = nil
    var bodyFeedback: String? = nil
    var coachFeedback: String? = nil
    var tomorrowFocus: String? = nil
    var freeNote: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingSession: TrainingSession? = nil

    @Relationship(deleteRule: .nullify, inverse: \ExerciseRecommendation.sourceReflection)
    var exerciseRecommendations: [ExerciseRecommendation] = []

    init(trainingSession: TrainingSession) {
        self.trainingSession = trainingSession
    }
}
