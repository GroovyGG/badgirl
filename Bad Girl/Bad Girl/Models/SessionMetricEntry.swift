import Foundation
import SwiftData

/// A recorded value for a specific metric in a specific session.
/// Uses value_number, value_text, or value_boolean depending on the metric's valueType.
@Model
final class SessionMetricEntry {
    var id: UUID = UUID()
    var valueNumber: Double? = nil
    var valueText: String? = nil
    var valueBoolean: Bool? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingSession: TrainingSession? = nil
    var metricDefinition: MetricDefinition? = nil

    init(trainingSession: TrainingSession, metricDefinition: MetricDefinition) {
        self.trainingSession = trainingSession
        self.metricDefinition = metricDefinition
    }
}
