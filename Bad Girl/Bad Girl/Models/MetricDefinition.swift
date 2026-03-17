import Foundation
import SwiftData

/// Defines a measurable metric that can be recorded in a session.
/// sport == nil means general metric; sport != nil means sport-specific.
@Model
final class MetricDefinition {
    var id: UUID = UUID()
    var code: String = ""
    var name: String = ""
    var displayNameZh: String? = nil
    /// footwork, striking, endurance, stability, readiness, match_performance
    var category: String? = nil
    /// integer, decimal, percentage, score, duration_seconds, text
    var valueType: String = "score"
    /// sec, count, %, score, bpm, min
    var unit: String? = nil
    var bodySystem: String? = nil
    var isActive: Bool = true
    var isRequiredDefault: Bool = false
    var sortOrder: Int = 0
    var metricDescription: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil

    @Relationship(deleteRule: .cascade, inverse: \SessionMetricEntry.metricDefinition)
    var sessionEntries: [SessionMetricEntry] = []

    init(code: String, name: String, trainingDomain: TrainingDomain, sport: Sport? = nil, valueType: String = "score", unit: String? = nil, displayNameZh: String? = nil, sortOrder: Int = 0) {
        self.code = code
        self.name = name
        self.trainingDomain = trainingDomain
        self.sport = sport
        self.valueType = valueType
        self.unit = unit
        self.displayNameZh = displayNameZh
        self.sortOrder = sortOrder
    }
}
