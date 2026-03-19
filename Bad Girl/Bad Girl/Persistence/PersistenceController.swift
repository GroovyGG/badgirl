import Foundation
import SwiftData

/// Manages the SwiftData ModelContainer.
///
/// Three modes:
/// - `.shared`  — production: persistent on-disk store, CloudKit-ready when entitlement is added
/// - `.debug`   — persistent on-disk store, verbose, no CloudKit (used in DEBUG builds)
/// - `.preview` — in-memory, pre-seeded with sample data for SwiftUI Previews and unit tests
@MainActor
final class PersistenceController {

    static let shared: PersistenceController = PersistenceController(inMemory: false)
    static let preview: PersistenceController = PersistenceController(inMemory: true)

    let container: ModelContainer

    private init(inMemory: Bool) {
        let schema = Schema([
            Sport.self,
            TrainingDomain.self,
            MuscleGroup.self,
            MovementTarget.self,
            MovementTargetMuscle.self,
            TrainingSession.self,
            SessionTarget.self,
            MetricDefinition.self,
            SessionMetricEntry.self,
            HealthSnapshot.self,
            SessionReflection.self,
            DailyGoal.self,
            DailyGoalTarget.self,
            PlannedSession.self,
            PlannedSessionTarget.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        if inMemory {
            seedPreviewData()
        } else {
            seedProductionDataIfNeeded()
        }
    }

    // MARK: - Seeding

    private func seedProductionDataIfNeeded() {
        let context = container.mainContext
        let sportCount = (try? context.fetchCount(FetchDescriptor<Sport>())) ?? 0
        guard sportCount == 0 else { return }
        insertSeedData(into: context)
    }

    private func seedPreviewData() {
        insertSeedData(into: container.mainContext)
    }

    private func insertSeedData(into context: ModelContext) {
        // Sports — app scope: general + badminton only (no other sports)
        let badminton = Sport(code: "badminton", name: "Badminton", displayNameZh: "羽毛球", iconName: "figure.badminton", colorToken: "blue", sortOrder: 0)
        context.insert(badminton)

        // Training domains
        let general    = TrainingDomain(code: "general_training",          name: "General Training",          displayNameZh: "基础训练",   sortOrder: 0)
        let specific   = TrainingDomain(code: "sport_specific_training",   name: "Sport-Specific Training",   displayNameZh: "专项训练",   sortOrder: 1)
        let matchPlay  = TrainingDomain(code: "match_play",                name: "Match Play",                displayNameZh: "比赛",       sortOrder: 2)
        let recovery   = TrainingDomain(code: "recovery",                  name: "Recovery",                  displayNameZh: "恢复训练",   sortOrder: 3)

        [general, specific, matchPlay, recovery].forEach { context.insert($0) }

        // Sample general movement targets
        let lowerBodyExp  = MovementTarget(code: "lower_body_explosiveness", name: "Lower Body Explosiveness", trainingDomain: general, category: "explosiveness", bodySystem: "lower_body", displayNameZh: "下肢爆发力")
        let ankleStab     = MovementTarget(code: "ankle_stability",          name: "Ankle Stability",          trainingDomain: general, category: "stability",     bodySystem: "lower_body", displayNameZh: "踝关节稳定")
        let shoulderStab  = MovementTarget(code: "shoulder_stability",       name: "Shoulder Stability",       trainingDomain: general, category: "stability",     bodySystem: "upper_body", displayNameZh: "肩部稳定")
        let trunkRotation = MovementTarget(code: "trunk_rotation_power",     name: "Trunk Rotation Power",     trainingDomain: general, category: "strength",      bodySystem: "core",       displayNameZh: "躯干旋转力")

        [lowerBodyExp, ankleStab, shoulderStab, trunkRotation].forEach { context.insert($0) }

        // Sample badminton-specific movement targets
        let splitStep     = MovementTarget(code: "badminton_split_step",         name: "Split Step",              trainingDomain: specific, sport: badminton, category: "skill",         bodySystem: "lower_body", displayNameZh: "垫步启动")
        let rearCourt     = MovementTarget(code: "badminton_rear_court_recovery", name: "Rear Court Recovery",    trainingDomain: specific, sport: badminton, category: "endurance",     bodySystem: "full_body",  displayNameZh: "后场回位")
        let swingCont     = MovementTarget(code: "badminton_swing_continuity",   name: "Swing Continuity",        trainingDomain: specific, sport: badminton, category: "skill",         bodySystem: "upper_body", displayNameZh: "挥拍连贯性")

        [splitStep, rearCourt, swingCont].forEach { context.insert($0) }

        // Sample metric definitions — general
        let lbeScore      = MetricDefinition(code: "lower_body_explosiveness_score", name: "Lower Body Explosiveness Score", trainingDomain: general, valueType: "score", unit: "score", displayNameZh: "下肢爆发力评分")
        let ankleScore    = MetricDefinition(code: "ankle_stability_score",          name: "Ankle Stability Score",          trainingDomain: general, valueType: "score", unit: "score", displayNameZh: "踝关节稳定评分")
        let fatigueScore  = MetricDefinition(code: "fatigue_score",                  name: "Fatigue Score",                  trainingDomain: general, valueType: "score", unit: "score", displayNameZh: "疲劳度评分")

        // Sample metric definitions — badminton
        let sixPointTime  = MetricDefinition(code: "badminton_six_point_time",       name: "Six-Point Footwork Time",        trainingDomain: specific, sport: badminton, valueType: "duration_seconds", unit: "sec",   displayNameZh: "六点步时间")
        let unforcedErr   = MetricDefinition(code: "badminton_unforced_errors",      name: "Unforced Errors",                trainingDomain: specific, sport: badminton, valueType: "integer",          unit: "count", displayNameZh: "非受迫失误")
        let avgRally      = MetricDefinition(code: "badminton_avg_rally_count",      name: "Avg Rally Count",                trainingDomain: specific, sport: badminton, valueType: "decimal",          unit: "count", displayNameZh: "平均回合数")

        [lbeScore, ankleScore, fatigueScore, sixPointTime, unforcedErr, avgRally].forEach { context.insert($0) }

        try? context.save()
    }
}
