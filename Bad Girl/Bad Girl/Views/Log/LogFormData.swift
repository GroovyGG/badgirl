import Foundation
import Observation
import SwiftUI

/// Subjective scores for one training domain (感受步骤).
struct DomainFeelings: Equatable {
    var intensityRPE: Double = 5
    var energyLevel: Double = 5
    var completionScore: Double = 5
}

/// How this session's activity data was captured.
enum LogDataSource: String {
    /// Apple Watch recorded activity; we will sync heart rate, calories, etc. User still inputs exercise details.
    case appleWatch
    /// No watch data (forgot to wear, etc.). Everything entered manually.
    case manual
}

/// Shared mutable state for the multi-step log session form.
/// Passed as a reference type so all step views see the same data.
@Observable
final class LogFormData {
    var dataSource: LogDataSource = .appleWatch
    var sessionType: String = "training"
    /// Multi-select training domains (类型步骤).
    var selectedTrainingDomains: [TrainingDomain] = []
    var sport: Sport? = nil

    /// First selected domain — for legacy filters (e.g. metrics / targets steps) and primary FK.
    var trainingDomain: TrainingDomain? { selectedTrainingDomains.first }

    func toggleTrainingDomain(_ domain: TrainingDomain) {
        if let i = selectedTrainingDomains.firstIndex(where: { $0.id == domain.id }) {
            selectedTrainingDomains.remove(at: i)
            feelingsByDomainId[domain.id] = nil
        } else {
            selectedTrainingDomains.append(domain)
            if feelingsByDomainId[domain.id] == nil {
                feelingsByDomainId[domain.id] = DomainFeelings()
            }
        }
    }

    func isTrainingDomainSelected(_ domain: TrainingDomain) -> Bool {
        selectedTrainingDomains.contains(where: { $0.id == domain.id })
    }

    /// Ensure feelings entries exist / drop orphans when selection changes (e.g. before 感受 step).
    func syncFeelingsWithSelection() {
        let ids = Set(selectedTrainingDomains.map(\.id))
        feelingsByDomainId = feelingsByDomainId.filter { ids.contains($0.key) }
        for d in selectedTrainingDomains where feelingsByDomainId[d.id] == nil {
            feelingsByDomainId[d.id] = DomainFeelings()
        }
    }

    func bindingIntensityRPE(for domainId: UUID) -> Binding<Double> {
        Binding(
            get: { self.feelingsByDomainId[domainId]?.intensityRPE ?? 5 },
            set: { newValue in
                var f = self.feelingsByDomainId[domainId] ?? DomainFeelings()
                f.intensityRPE = newValue
                self.feelingsByDomainId[domainId] = f
            }
        )
    }

    func bindingEnergyLevel(for domainId: UUID) -> Binding<Double> {
        Binding(
            get: { self.feelingsByDomainId[domainId]?.energyLevel ?? 5 },
            set: { newValue in
                var f = self.feelingsByDomainId[domainId] ?? DomainFeelings()
                f.energyLevel = newValue
                self.feelingsByDomainId[domainId] = f
            }
        )
    }

    func bindingCompletionScore(for domainId: UUID) -> Binding<Double> {
        Binding(
            get: { self.feelingsByDomainId[domainId]?.completionScore ?? 5 },
            set: { newValue in
                var f = self.feelingsByDomainId[domainId] ?? DomainFeelings()
                f.completionScore = newValue
                self.feelingsByDomainId[domainId] = f
            }
        )
    }
    var sessionDate: Date = Date()
    var startTime: Date? = nil
    var endTime: Date? = nil
    var durationMinutes: Int? = nil
    var selectedTargets: [MovementTarget] = []
    var metricValues: [UUID: Double] = [:]
    var metricTextValues: [UUID: String] = [:]
    /// Keyed by `TrainingDomain.id`; one set of sliders per selected domain.
    var feelingsByDomainId: [UUID: DomainFeelings] = [:]
    var whatImproved: String = ""
    var whatFeltWrong: String = ""
    var bodyFeedback: String = ""
    var coachFeedback: String = ""
    var tomorrowFocus: String = ""
    var freeNote: String = ""

    func reset() {
        dataSource = .appleWatch
        sessionType = "training"
        selectedTrainingDomains = []
        sport = nil
        sessionDate = Date()
        startTime = nil
        endTime = nil
        durationMinutes = nil
        selectedTargets = []
        metricValues = [:]
        metricTextValues = [:]
        feelingsByDomainId = [:]
        whatImproved = ""
        whatFeltWrong = ""
        bodyFeedback = ""
        coachFeedback = ""
        tomorrowFocus = ""
        freeNote = ""
    }
}
