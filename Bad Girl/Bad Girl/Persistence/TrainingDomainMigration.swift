import Foundation
import SwiftData

/// Migrates legacy `TrainingDomain` rows (e.g. 基础训练 / 专项训练 / 比赛 / 恢复训练) to the
/// current 12 badminton domain codes. Safe to run multiple times.
enum TrainingDomainMigration {

    /// Canonical domains (must match seed in `PersistenceController.insertSeedData`).
    static let specs: [(code: String, name: String, displayNameZh: String?, sortOrder: Int)] = [
        ("movement_footwork", "Movement / Footwork", "步法与移动", 0),
        ("stroke_technique", "Stroke Technique", "击球技术", 1),
        ("kinetic_chain", "Kinetic Chain", "发力链与挥拍动力学", 2),
        ("frontcourt_touch", "Front Court Touch", "网前小球与拍面控制", 3),
        ("perception_decision", "Perception / Decision", "反应与决策", 4),
        ("stability_balance", "Stability / Balance", "稳定性与平衡", 5),
        ("power_explosiveness", "Power / Explosiveness", "爆发力与专项体能", 6),
        ("strength_foundation", "Strength Foundation", "力量基础", 7),
        ("coordination_rhythm", "Coordination / Rhythm", "协调与节奏", 8),
        ("mobility_rom", "Mobility / ROM", "活动度与动作幅度", 9),
        ("specific_endurance", "Specific Endurance", "耐力与重复输出", 10),
        ("recovery_resilience", "Recovery / Resilience", "活动度与抗伤", 11),
    ]

    static let expectedCodes: Set<String> = Set(specs.map(\.code))

    @MainActor
    static func runIfNeeded(context: ModelContext) {
        let domains = (try? context.fetch(FetchDescriptor<TrainingDomain>())) ?? []
        let currentCodes = Set(domains.map(\.code))

        // Fully migrated: DB only contains the 12 canonical codes (no legacy rows).
        if currentCodes == expectedCodes {
            return
        }

        var byCode: [String: TrainingDomain] = [:]
        for d in domains {
            if byCode[d.code] == nil { byCode[d.code] = d }
        }

        // Insert any missing canonical rows (Sport already exists → full seed did not run).
        for spec in specs {
            if byCode[spec.code] == nil {
                let inserted = TrainingDomain(
                    code: spec.code,
                    name: spec.name,
                    displayNameZh: spec.displayNameZh,
                    description: nil,
                    sortOrder: spec.sortOrder
                )
                context.insert(inserted)
                byCode[spec.code] = inserted
            }
        }
        try? context.save()

        let refreshed = (try? context.fetch(FetchDescriptor<TrainingDomain>())) ?? []
        byCode = [:]
        for d in refreshed {
            if byCode[d.code] == nil { byCode[d.code] = d }
        }

        let obsolete = refreshed.filter { !expectedCodes.contains($0.code) }
        guard !obsolete.isEmpty else { return }

        let plannedSessions = (try? context.fetch(FetchDescriptor<PlannedSession>())) ?? []

        for old in obsolete {
            let targetCode = resolveTargetCode(for: old)
            guard let replacement = byCode[targetCode] else { continue }

            for s in old.trainingSessions {
                s.trainingDomain = replacement
                if s.trainingDomainCodesOrdered.isEmpty {
                    s.trainingDomainCodesOrdered = replacement.code
                }
            }
            for mt in old.movementTargets {
                mt.trainingDomain = replacement
            }
            for m in old.metricDefinitions {
                m.trainingDomain = replacement
            }
            for g in old.dailyGoals {
                g.trainingDomain = replacement
            }
            for e in old.exercises {
                e.trainingDomain = replacement
            }
            for p in plannedSessions where p.trainingDomain?.id == old.id {
                p.trainingDomain = replacement
            }

            context.delete(old)
        }

        try? context.save()
    }

    /// Maps legacy domain rows (by `code` and/or Chinese label) to a canonical `expectedCodes` value.
    private static func resolveTargetCode(for old: TrainingDomain) -> String {
        let c = old.code.lowercased()
        let zh = (old.displayNameZh ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if expectedCodes.contains(old.code) {
            return old.code
        }

        switch c {
        case "general_training", "general", "basic_training":
            return "movement_footwork"
        case "sport_specific_training", "sport_specific":
            return "stroke_technique"
        case "match_play", "match_session", "competition":
            return "perception_decision"
        case "recovery", "recovery_training":
            return "recovery_resilience"
        default:
            break
        }

        if zh == "基础训练" || zh.hasPrefix("基础") {
            return "movement_footwork"
        }
        if zh == "专项训练" || zh.contains("专项训练") {
            return "stroke_technique"
        }
        if zh == "比赛" {
            return "perception_decision"
        }
        if zh.contains("恢复") {
            return "recovery_resilience"
        }

        return "movement_footwork"
    }
}
