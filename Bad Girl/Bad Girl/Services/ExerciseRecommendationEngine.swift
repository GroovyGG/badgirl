import Foundation
import SwiftData

enum ExerciseRecommendationEngine {

    /// Generate and persist recommendation rows from recent context.
    /// This keeps the legacy target-suggestion engine, while writing a durable recommendation layer.
    @MainActor
    static func generateAndPersist(
        context: ModelContext,
        recentSessions: [TrainingSession],
        allTargets: [MovementTarget],
        latestHealth: HealthSnapshot?
    ) {
        let targetSuggestions = TrainingSuggestionEngine.generate(
            recentSessions: recentSessions,
            allTargets: allTargets,
            latestHealth: latestHealth
        )

        guard !targetSuggestions.isEmpty else { return }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existing = (try? context.fetch(FetchDescriptor<ExerciseRecommendation>())) ?? []
        let sourceSession = recentSessions.first
        let sourceReflection = sourceSession?.reflection

        for suggestion in targetSuggestions {
            // Avoid creating duplicate suggested recommendations for the same target in recent period.
            let hasRecentDuplicate = existing.contains {
                $0.status == "suggested"
                && $0.movementTarget?.id == suggestion.target.id
                && abs($0.recommendedDate.timeIntervalSinceNow) < 86400
            }
            if hasRecentDuplicate { continue }

            let exercise = exercises.first { ex in
                ex.isActive && ex.movementTarget?.id == suggestion.target.id
            }

            let recommendation = ExerciseRecommendation(
                recommendedDate: Date(),
                status: "suggested",
                sourceSession: sourceSession,
                sourceReflection: sourceReflection,
                exercise: exercise,
                movementTarget: suggestion.target
            )
            recommendation.exerciseType = exercise?.category ?? suggestion.target.category ?? "general"
            recommendation.targetProblem = suggestion.target.displayNameZh ?? suggestion.target.name
            recommendation.intensity = recommendationIntensity(from: suggestion.score)
            recommendation.durationMinutes = exercise?.defaultDurationMinutes ?? defaultDuration(for: suggestion.target.category)
            recommendation.reason = suggestion.reasons.joined(separator: "；")
            context.insert(recommendation)
        }

        try? context.save()
    }

    private static func recommendationIntensity(from score: Double) -> String {
        switch score {
        case ..<0.45: "low"
        case ..<0.75: "medium"
        default: "high"
        }
    }

    private static func defaultDuration(for category: String?) -> Int {
        switch category {
        case "recovery", "mobility": return 15
        case "endurance": return 20
        case "explosiveness": return 10
        default: return 12
        }
    }
}
