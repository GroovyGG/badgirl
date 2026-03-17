import Foundation
import SwiftData

/// A health data snapshot imported from Apple Health / Apple Watch.
/// Can be tied to a specific session or be a standalone daily snapshot.
@Model
final class HealthSnapshot {
    var id: UUID = UUID()
    var snapshotDate: Date = Date()
    /// apple_health, apple_watch
    var source: String? = nil
    var avgHeartRate: Double? = nil
    var maxHeartRate: Double? = nil
    var restingHeartRate: Double? = nil
    var activeEnergyKcal: Double? = nil
    var steps: Int? = nil
    var exerciseMinutes: Double? = nil
    var sleepHours: Double? = nil
    var workoutDurationMin: Double? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var trainingSession: TrainingSession? = nil

    init(snapshotDate: Date, source: String? = nil, trainingSession: TrainingSession? = nil) {
        self.snapshotDate = snapshotDate
        self.source = source
        self.trainingSession = trainingSession
    }
}
