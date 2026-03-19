import XCTest
@testable import Bad_Girl

final class Bad_GirlTests: XCTestCase {

    // MARK: - PersistenceController

    func testPreviewContainerLoads() {
        let controller = PersistenceController.preview
        let context = controller.container.mainContext
        let descriptor = FetchDescriptor<Sport>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        XCTAssertGreaterThan(count, 0, "Preview should have seeded sports")
    }

    func testPreviewContainsBadminton() {
        let context = PersistenceController.preview.container.mainContext
        var descriptor = FetchDescriptor<Sport>(predicate: #Predicate { $0.code == "badminton" })
        descriptor.fetchLimit = 1
        let results = (try? context.fetch(descriptor)) ?? []
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.displayNameZh, "羽毛球")
    }

    // MARK: - TrainingSuggestionEngine

    func testSuggestionEngineReturnsAtMostThree() {
        let controller = PersistenceController.preview
        let context = controller.container.mainContext
        var sessionsDescriptor = FetchDescriptor<TrainingSession>(sortBy: [SortDescriptor(\.sessionDate, order: .reverse)])
        var targetsDescriptor = FetchDescriptor<MovementTarget>()
        let sessions = (try? context.fetch(sessionsDescriptor)) ?? []
        let targets = (try? context.fetch(targetsDescriptor)) ?? []
        let suggestions = TrainingSuggestionEngine.generate(
            recentSessions: Array(sessions.prefix(30)),
            allTargets: targets.filter { $0.isActive },
            latestHealth: nil
        )
        XCTAssertLessThanOrEqual(suggestions.count, 3)
    }

    func testSuggestionEngineSortsByScoreDescending() {
        let controller = PersistenceController.preview
        let context = controller.container.mainContext
        var targetsDescriptor = FetchDescriptor<MovementTarget>()
        let targets = (try? context.fetch(targetsDescriptor)) ?? []
        let suggestions = TrainingSuggestionEngine.generate(
            recentSessions: [],
            allTargets: targets.filter { $0.isActive },
            latestHealth: nil
        )
        for i in 1..<suggestions.count {
            XCTAssertGreaterThanOrEqual(suggestions[i - 1].score, suggestions[i].score)
        }
    }

    // MARK: - Four-layer model integrity

    func testExerciseModelsInsertAndFetch() {
        let context = PersistenceController.preview.container.mainContext
        let domain = (try? context.fetch(FetchDescriptor<TrainingDomain>()).first)
        let session = (try? context.fetch(FetchDescriptor<TrainingSession>()).first)
        XCTAssertNotNil(domain)
        XCTAssertNotNil(session)

        let exercise = Exercise(
            code: "test_exercise",
            name: "Test Exercise",
            recordType: "duration",
            trainingDomain: domain,
            displayNameZh: "测试动作"
        )
        context.insert(exercise)

        let recommendation = ExerciseRecommendation(
            recommendedDate: Date(),
            status: "suggested",
            sourceSession: session,
            exercise: exercise
        )
        recommendation.targetProblem = "测试问题"
        context.insert(recommendation)

        let log = ExerciseLog(
            completedDate: Date(),
            recommendation: recommendation,
            trainingSession: session,
            exercise: exercise
        )
        log.durationMinutes = 10
        context.insert(log)
        try? context.save()

        let exerciseCount = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        let recommendationCount = (try? context.fetchCount(FetchDescriptor<ExerciseRecommendation>())) ?? 0
        let logCount = (try? context.fetchCount(FetchDescriptor<ExerciseLog>())) ?? 0

        XCTAssertGreaterThan(exerciseCount, 0)
        XCTAssertGreaterThan(recommendationCount, 0)
        XCTAssertGreaterThan(logCount, 0)
    }

    func testRecommendationCompletionCreatesLogLinkage() {
        let context = PersistenceController.preview.container.mainContext
        guard let session = (try? context.fetch(FetchDescriptor<TrainingSession>()).first),
              let exercise = (try? context.fetch(FetchDescriptor<Exercise>()).first) else {
            XCTFail("Missing seed session or exercise")
            return
        }

        let recommendation = ExerciseRecommendation(
            recommendedDate: Date(),
            status: "suggested",
            sourceSession: session,
            exercise: exercise
        )
        recommendation.status = "completed"
        context.insert(recommendation)

        let log = ExerciseLog(
            completedDate: Date(),
            recommendation: recommendation,
            trainingSession: session,
            exercise: exercise
        )
        log.userFeedback = "test completion"
        context.insert(log)
        try? context.save()

        var descriptor = FetchDescriptor<ExerciseLog>(predicate: #Predicate { $0.recommendation?.id == recommendation.id })
        descriptor.fetchLimit = 1
        let result = (try? context.fetch(descriptor)) ?? []
        XCTAssertEqual(result.count, 1)
    }

    func testAcceptedRateAndOutcomeSummary() {
        let context = PersistenceController.preview.container.mainContext
        let recommendationA = ExerciseRecommendation(status: "accepted")
        let recommendationB = ExerciseRecommendation(status: "completed")
        let recommendationC = ExerciseRecommendation(status: "suggested")
        recommendationA.outcomeSignal = "improved"
        recommendationB.outcomeSignal = "persisted"
        recommendationC.outcomeSignal = "unknown"
        context.insert(recommendationA)
        context.insert(recommendationB)
        context.insert(recommendationC)
        try? context.save()

        let acceptedRate = ExerciseRecommendationAnalytics.acceptedRate(context: context)
        XCTAssertGreaterThan(acceptedRate, 0)

        let summary = ExerciseRecommendationAnalytics.outcomeSignalSummary(context: context)
        XCTAssertNotNil(summary["improved"])
        XCTAssertNotNil(summary["persisted"])
        XCTAssertNotNil(summary["unknown"])
    }
}
