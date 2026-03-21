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

    /// Legacy single domain; first of multi-select; used for queries and display fallback.
    var trainingDomain: TrainingDomain? = nil
    /// Comma-separated `TrainingDomain.code` values in selection order (multi-select log).
    var trainingDomainCodesOrdered: String = ""
    /// JSON array of `PerDomainFeelingsPayload` — RPE / 体能 / 完成度 per domain.
    var perDomainFeelingsJSON: String = ""
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

extension TrainingSession {
    /// Resolves multi-select codes using a catalog fetch (e.g. `@Query` all domains).
    func trainingDomainsOrdered(resolvingFrom catalog: [TrainingDomain]) -> [TrainingDomain] {
        if !trainingDomainCodesOrdered.isEmpty {
            let codes = trainingDomainCodesOrdered.split(separator: ",").map(String.init)
            return codes.compactMap { code in catalog.first { $0.code == code } }
        }
        if let d = trainingDomain { return [d] }
        return []
    }

    /// Count of selected training domains for compact UI (cards).
    var trainingDomainSelectionCount: Int {
        if !trainingDomainCodesOrdered.isEmpty {
            return trainingDomainCodesOrdered.split(separator: ",").filter { !$0.isEmpty }.count
        }
        return trainingDomain != nil ? 1 : 0
    }
}
