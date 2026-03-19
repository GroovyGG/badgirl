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
}
