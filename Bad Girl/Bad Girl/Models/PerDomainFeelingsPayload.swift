import Foundation

/// Persisted JSON in `TrainingSession.perDomainFeelingsJSON` (per training domain scores).
struct PerDomainFeelingsPayload: Codable, Equatable {
    var code: String
    var intensityRPE: Int
    var energyLevel: Int
    var completionScore: Int
}
