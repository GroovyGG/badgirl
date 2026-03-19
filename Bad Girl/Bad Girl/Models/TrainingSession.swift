import Foundation
import SwiftData

/// A single training session entry.
/// sport == nil means general/non-sport-specific training.
@Model
final class TrainingSession {
    var id: UUID = UUID()
    var sessionDate: Date = Date()
    var startTime: Date? = nil
    var endTime: Date? = nil
    /// training, game, gym, mobility, recovery, mixed
    var sessionType: String = "training"
    var durationMinutes: Int? = nil
    /// Rate of perceived exertion 1–10
    var intensityRPE: Int? = nil
    var energyLevel: Int? = nil
    var completionScore: Int? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil

    @Relationship(deleteRule: .cascade, inverse: \SessionTarget.trainingSession)
    var sessionTargets: [SessionTarget] = []

    @Relationship(deleteRule: .cascade, inverse: \SessionMetricEntry.trainingSession)
    var sessionMetricEntries: [SessionMetricEntry] = []

    @Relationship(deleteRule: .nullify, inverse: \HealthSnapshot.trainingSession)
    var healthSnapshots: [HealthSnapshot] = []

    @Relationship(deleteRule: .cascade, inverse: \SessionReflection.trainingSession)
    var reflection: SessionReflection? = nil

    @Relationship(deleteRule: .nullify, inverse: \ExerciseRecommendation.sourceSession)
    var exerciseRecommendations: [ExerciseRecommendation] = []

    @Relationship(deleteRule: .nullify, inverse: \ExerciseLog.trainingSession)
    var exerciseLogs: [ExerciseLog] = []

    init(sessionDate: Date, sessionType: String = "training", trainingDomain: TrainingDomain, sport: Sport? = nil) {
        self.sessionDate = sessionDate
        self.sessionType = sessionType
        self.trainingDomain = trainingDomain
        self.sport = sport
    }
}
