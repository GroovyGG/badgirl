import Foundation
import Observation

/// Shared mutable state for the multi-step log session form.
/// Passed as a reference type so all step views see the same data.
@Observable
final class LogFormData {
    var sessionType: String = "training"
    var trainingDomain: TrainingDomain? = nil
    var sport: Sport? = nil
    var sessionDate: Date = Date()
    var startTime: Date? = nil
    var endTime: Date? = nil
    var durationMinutes: Int? = nil
    var selectedTargets: [MovementTarget] = []
    var metricValues: [UUID: Double] = [:]
    var metricTextValues: [UUID: String] = [:]
    var intensityRPE: Double = 5
    var energyLevel: Double = 5
    var completionScore: Double = 5
    var whatImproved: String = ""
    var whatFeltWrong: String = ""
    var bodyFeedback: String = ""
    var tomorrowFocus: String = ""
    var freeNote: String = ""

    func reset() {
        sessionType = "training"
        trainingDomain = nil
        sport = nil
        sessionDate = Date()
        startTime = nil
        endTime = nil
        durationMinutes = nil
        selectedTargets = []
        metricValues = [:]
        metricTextValues = [:]
        intensityRPE = 5
        energyLevel = 5
        completionScore = 5
        whatImproved = ""
        whatFeltWrong = ""
        bodyFeedback = ""
        tomorrowFocus = ""
        freeNote = ""
    }
}
