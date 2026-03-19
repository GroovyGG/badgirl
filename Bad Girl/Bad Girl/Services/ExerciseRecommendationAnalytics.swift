import Foundation
import SwiftData

enum ExerciseRecommendationAnalytics {
    @MainActor
    static func pendingRecommendations(context: ModelContext) -> [ExerciseRecommendation] {
        let descriptor = FetchDescriptor<ExerciseRecommendation>(
            predicate: #Predicate { $0.status == "suggested" || $0.status == "accepted" },
            sortBy: [SortDescriptor(\.recommendedDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    @MainActor
    static func completionRate(context: ModelContext) -> Double {
        let all = (try? context.fetch(FetchDescriptor<ExerciseRecommendation>())) ?? []
        guard !all.isEmpty else { return 0 }
        let completed = all.filter { $0.status == "completed" }.count
        return Double(completed) / Double(all.count)
    }

    @MainActor
    static func acceptedRate(context: ModelContext) -> Double {
        let all = (try? context.fetch(FetchDescriptor<ExerciseRecommendation>())) ?? []
        guard !all.isEmpty else { return 0 }
        let accepted = all.filter { $0.status == "accepted" || $0.status == "completed" }.count
        return Double(accepted) / Double(all.count)
    }

    @MainActor
    static func completionRateByType(context: ModelContext) -> [String: Double] {
        let all = (try? context.fetch(FetchDescriptor<ExerciseRecommendation>())) ?? []
        let grouped = Dictionary(grouping: all, by: { $0.exerciseType ?? "unknown" })
        var result: [String: Double] = [:]
        for (key, recs) in grouped {
            guard !recs.isEmpty else { continue }
            let done = recs.filter { $0.status == "completed" }.count
            result[key] = Double(done) / Double(recs.count)
        }
        return result
    }

    @MainActor
    static func lastLogs(context: ModelContext, exercise: Exercise, limit: Int = 5) -> [ExerciseLog] {
        let descriptor = FetchDescriptor<ExerciseLog>(
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )
        let logs = (try? context.fetch(descriptor)) ?? []
        return Array(logs.filter { $0.exercise?.id == exercise.id }.prefix(limit))
    }

    /// Evaluate persisted recommendation outcomes from later reflections:
    /// - persisted: targetProblem appears again in later reflections
    /// - improved: no reappearance and sufficient follow-up reflections exist
    /// - unknown: insufficient follow-up context
    @MainActor
    static func evaluateOutcomeSignals(context: ModelContext, followUpReflectionCount: Int = 2) {
        let recommendations = (try? context.fetch(FetchDescriptor<ExerciseRecommendation>())) ?? []
        let sessions = (try? context.fetch(
            FetchDescriptor<TrainingSession>(sortBy: [SortDescriptor(\.sessionDate, order: .forward)])
        )) ?? []

        for recommendation in recommendations {
            guard let sourceDate = recommendation.sourceSession?.sessionDate ?? recommendation.sourceReflection?.trainingSession?.sessionDate,
                  let targetProblem = recommendation.targetProblem,
                  !targetProblem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                recommendation.outcomeSignal = "unknown"
                recommendation.outcomeEvaluatedAt = Date()
                continue
            }

            let followUps = sessions
                .filter { $0.sessionDate > sourceDate }
                .compactMap { $0.reflection }

            if followUps.count < followUpReflectionCount {
                recommendation.outcomeSignal = "unknown"
                recommendation.outcomeEvaluatedAt = Date()
                continue
            }

            let normalizedTarget = targetProblem.lowercased()
            let persisted = followUps.contains { reflection in
                let text = [
                    reflection.whatFeltWrong,
                    reflection.bodyFeedback,
                    reflection.tomorrowFocus,
                    reflection.freeNote
                ]
                    .compactMap { $0?.lowercased() }
                    .joined(separator: " ")
                return text.contains(normalizedTarget)
            }

            recommendation.outcomeSignal = persisted ? "persisted" : "improved"
            recommendation.outcomeEvaluatedAt = Date()
        }

        try? context.save()
    }

    @MainActor
    static func outcomeSignalSummary(context: ModelContext) -> [String: Int] {
        let all = (try? context.fetch(FetchDescriptor<ExerciseRecommendation>())) ?? []
        let grouped = Dictionary(grouping: all, by: { $0.outcomeSignal })
        return [
            "improved": grouped["improved"]?.count ?? 0,
            "persisted": grouped["persisted"]?.count ?? 0,
            "unknown": grouped["unknown"]?.count ?? 0,
        ]
    }
}
