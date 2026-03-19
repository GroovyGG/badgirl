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
}
