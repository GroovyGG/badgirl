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
            Exercise.self,
            ExerciseRecommendation.self,
            ExerciseLog.self,
        ])

        if inMemory {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            do {
                container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create in-memory ModelContainer: \(error)")
            }
        } else {
            // Try CloudKit-backed store first; fall back to local-only if existing store is incompatible (e.g. created without CloudKit).
            let configWithCloudKit = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            if let c = try? ModelContainer(for: schema, configurations: [configWithCloudKit]) {
                container = c
            } else {
                let configLocalOnly = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
                do {
                    container = try ModelContainer(for: schema, configurations: [configLocalOnly])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
                }
            }
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

        // Badminton training domains (P1–P12)
        let p1MovementFootwork = TrainingDomain(code: "movement_footwork", name: "Movement / Footwork", displayNameZh: "步法与移动", sortOrder: 0)
        let p2StrokeTechnique = TrainingDomain(code: "stroke_technique", name: "Stroke Technique", displayNameZh: "击球技术", sortOrder: 1)
        let p3KineticChain = TrainingDomain(code: "kinetic_chain", name: "Kinetic Chain", displayNameZh: "发力链与挥拍动力学", sortOrder: 2)
        let p4FrontCourtTouch = TrainingDomain(code: "frontcourt_touch", name: "Front Court Touch", displayNameZh: "网前小球与拍面控制", sortOrder: 3)
        let p5PerceptionDecision = TrainingDomain(code: "perception_decision", name: "Perception / Decision", displayNameZh: "反应与决策", sortOrder: 4)
        let p6StabilityBalance = TrainingDomain(code: "stability_balance", name: "Stability / Balance", displayNameZh: "稳定性与平衡", sortOrder: 5)
        let p7PowerExplosiveness = TrainingDomain(code: "power_explosiveness", name: "Power / Explosiveness", displayNameZh: "爆发力与专项体能", sortOrder: 6)
        let p8StrengthFoundation = TrainingDomain(code: "strength_foundation", name: "Strength Foundation", displayNameZh: "力量基础", sortOrder: 7)
        let p9CoordinationRhythm = TrainingDomain(code: "coordination_rhythm", name: "Coordination / Rhythm", displayNameZh: "协调与节奏", sortOrder: 8)
        let p10MobilityROM = TrainingDomain(code: "mobility_rom", name: "Mobility / ROM", displayNameZh: "活动度与动作幅度", sortOrder: 9)
        let p11SpecificEndurance = TrainingDomain(code: "specific_endurance", name: "Specific Endurance", displayNameZh: "耐力与重复输出", sortOrder: 10)
        let p12RecoveryResilience = TrainingDomain(code: "recovery_resilience", name: "Recovery / Resilience", displayNameZh: "活动度与抗伤", sortOrder: 11)

        [
            p1MovementFootwork, p2StrokeTechnique, p3KineticChain, p4FrontCourtTouch,
            p5PerceptionDecision, p6StabilityBalance, p7PowerExplosiveness, p8StrengthFoundation,
            p9CoordinationRhythm, p10MobilityROM, p11SpecificEndurance, p12RecoveryResilience
        ].forEach { context.insert($0) }

        // Sample general movement targets
        let lowerBodyExp  = MovementTarget(code: "lower_body_explosiveness", name: "Lower Body Explosiveness", trainingDomain: p7PowerExplosiveness, category: "explosiveness", bodySystem: "lower_body", displayNameZh: "下肢爆发力")
        let ankleStab     = MovementTarget(code: "ankle_stability",          name: "Ankle Stability",          trainingDomain: p6StabilityBalance, category: "stability",     bodySystem: "lower_body", displayNameZh: "踝关节稳定")
        let shoulderStab  = MovementTarget(code: "shoulder_stability",       name: "Shoulder Stability",       trainingDomain: p6StabilityBalance, category: "stability",     bodySystem: "upper_body", displayNameZh: "肩部稳定")
        let trunkRotation = MovementTarget(code: "trunk_rotation_power",     name: "Trunk Rotation Power",     trainingDomain: p3KineticChain, category: "strength",      bodySystem: "core",       displayNameZh: "躯干旋转力")

        [lowerBodyExp, ankleStab, shoulderStab, trunkRotation].forEach { context.insert($0) }

        // Sample badminton-specific movement targets
        let splitStep     = MovementTarget(code: "badminton_split_step",         name: "Split Step",              trainingDomain: p1MovementFootwork, sport: badminton, category: "skill",         bodySystem: "lower_body", displayNameZh: "垫步启动")
        let rearCourt     = MovementTarget(code: "badminton_rear_court_recovery", name: "Rear Court Recovery",    trainingDomain: p1MovementFootwork, sport: badminton, category: "endurance",     bodySystem: "full_body",  displayNameZh: "后场回位")
        let swingCont     = MovementTarget(code: "badminton_swing_continuity",   name: "Swing Continuity",        trainingDomain: p2StrokeTechnique, sport: badminton, category: "skill",         bodySystem: "upper_body", displayNameZh: "挥拍连贯性")

        [splitStep, rearCourt, swingCont].forEach { context.insert($0) }

        // Sample metric definitions — general
        let lbeScore      = MetricDefinition(code: "lower_body_explosiveness_score", name: "Lower Body Explosiveness Score", trainingDomain: p7PowerExplosiveness, valueType: "score", unit: "score", displayNameZh: "下肢爆发力评分")
        let ankleScore    = MetricDefinition(code: "ankle_stability_score",          name: "Ankle Stability Score",          trainingDomain: p6StabilityBalance, valueType: "score", unit: "score", displayNameZh: "踝关节稳定评分")
        let fatigueScore  = MetricDefinition(code: "fatigue_score",                  name: "Fatigue Score",                  trainingDomain: p12RecoveryResilience, valueType: "score", unit: "score", displayNameZh: "疲劳度评分")

        // Sample metric definitions — badminton
        let sixPointTime  = MetricDefinition(code: "badminton_six_point_time",       name: "Six-Point Footwork Time",        trainingDomain: p1MovementFootwork, sport: badminton, valueType: "duration_seconds", unit: "sec",   displayNameZh: "六点步时间")
        let unforcedErr   = MetricDefinition(code: "badminton_unforced_errors",      name: "Unforced Errors",                trainingDomain: p2StrokeTechnique, sport: badminton, valueType: "integer",          unit: "count", displayNameZh: "非受迫失误")
        let avgRally      = MetricDefinition(code: "badminton_avg_rally_count",      name: "Avg Rally Count",                trainingDomain: p11SpecificEndurance, sport: badminton, valueType: "decimal",          unit: "count", displayNameZh: "平均回合数")

        [lbeScore, ankleScore, fatigueScore, sixPointTime, unforcedErr, avgRally].forEach { context.insert($0) }

        // Exercise catalog (seeded for recommendation/action layers)
        let recoveryMobility = Exercise(
            code: "recovery_mobility_flow",
            name: "Recovery Mobility Flow",
            recordType: "duration",
            trainingDomain: p10MobilityROM,
            displayNameZh: "恢复拉伸流程",
            sortOrder: 0
        )
        recoveryMobility.category = "mobility"
        recoveryMobility.defaultIntensity = "low"
        recoveryMobility.defaultDurationMinutes = 15
        recoveryMobility.movementTarget = ankleStab

        let sixPointFootwork = Exercise(
            code: "badminton_6_point_footwork",
            name: "6-point Footwork Drill",
            recordType: "time_count",
            trainingDomain: p1MovementFootwork,
            sport: badminton,
            movementTarget: splitStep,
            displayNameZh: "六点步法训练",
            sortOrder: 1
        )
        sixPointFootwork.category = "footwork"
        sixPointFootwork.defaultIntensity = "medium"
        sixPointFootwork.defaultDurationMinutes = 12

        let shoulderStabilityBlock = Exercise(
            code: "shoulder_stability_block",
            name: "Shoulder Stability Block",
            recordType: "weight_reps",
            trainingDomain: p6StabilityBalance,
            movementTarget: shoulderStab,
            displayNameZh: "肩部稳定训练组",
            sortOrder: 2
        )
        shoulderStabilityBlock.category = "stability"
        shoulderStabilityBlock.defaultIntensity = "medium"
        shoulderStabilityBlock.defaultDurationMinutes = 18

        let jumpExplosive = Exercise(
            code: "jump_explosiveness_block",
            name: "Jump Explosiveness Block",
            recordType: "max_reps",
            trainingDomain: p7PowerExplosiveness,
            movementTarget: lowerBodyExp,
            displayNameZh: "下肢爆发跳跃组",
            sortOrder: 3
        )
        jumpExplosive.category = "explosiveness"
        jumpExplosive.defaultIntensity = "high"
        jumpExplosive.defaultDurationMinutes = 10

        let enduranceIntervals = Exercise(
            code: "badminton_endurance_intervals",
            name: "Endurance Interval Session",
            recordType: "duration",
            trainingDomain: p11SpecificEndurance,
            sport: badminton,
            movementTarget: rearCourt,
            displayNameZh: "羽毛球耐力间歇",
            sortOrder: 4
        )
        enduranceIntervals.category = "endurance"
        enduranceIntervals.defaultIntensity = "medium"
        enduranceIntervals.defaultDurationMinutes = 20

        [recoveryMobility, sixPointFootwork, shoulderStabilityBlock, jumpExplosive, enduranceIntervals].forEach { context.insert($0) }

        try? context.save()
    }
}
