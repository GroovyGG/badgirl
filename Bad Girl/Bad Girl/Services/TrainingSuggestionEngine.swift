import Foundation

struct MovementTargetSuggestion: Identifiable {
    let id = UUID()
    let target: MovementTarget
    let score: Double       // 0.0 – 1.0, higher = more urgent to train
    let reasons: [String]   // plain-language Chinese explanations
}

enum TrainingSuggestionEngine {

    /// Generate up to 3 prioritized training suggestions for today.
    ///
    /// Scoring rules:
    /// - Low quality score in recent sessions  → +0.4
    /// - Days since last trained this target   → +0.05/day, capped at +0.3
    /// - Target never appeared in recent logs  → +0.3
    /// - High fatigue last time                → −0.2
    /// - Sleep < 6h and target is recovery     → +0.5 override
    static func generate(
        recentSessions: [TrainingSession],
        allTargets: [MovementTarget],
        latestHealth: HealthSnapshot?
    ) -> [MovementTargetSuggestion] {
        let now = Date()
        let lowSleep = (latestHealth?.sleepHours ?? 8) < 6

        var results: [MovementTargetSuggestion] = []

        for target in allTargets where target.isActive {
            var score: Double = 0.2
            var reasons: [String] = []

            let relatedSessionTargets = recentSessions
                .flatMap { $0.sessionTargets }
                .filter { $0.movementTarget?.id == target.id }

            if relatedSessionTargets.isEmpty {
                score += 0.3
                reasons.append("近期未训练该目标")
            } else {
                let qualityScores = relatedSessionTargets.compactMap { $0.qualityScore }
                let fatigueScores = relatedSessionTargets.compactMap { $0.fatigueScore }

                if !qualityScores.isEmpty {
                    let avgQuality = Double(qualityScores.reduce(0, +)) / Double(qualityScores.count)
                    if avgQuality < 6 {
                        score += 0.4
                        reasons.append(String(format: "最近质量评分偏低（%.1f/10）", avgQuality))
                    } else if avgQuality >= 8 {
                        score -= 0.1
                    }
                }

                if !fatigueScores.isEmpty {
                    let avgFatigue = Double(fatigueScores.reduce(0, +)) / Double(fatigueScores.count)
                    if avgFatigue > 7 {
                        score -= 0.2
                        reasons.append("上次训练疲劳度较高，建议稍作休息")
                    }
                }

                let sessionsWithTarget = relatedSessionTargets.compactMap { $0.trainingSession }
                if let lastSession = sessionsWithTarget.max(by: { $0.sessionDate < $1.sessionDate }) {
                    let daysSince = Calendar.current.dateComponents([.day], from: lastSession.sessionDate, to: now).day ?? 0
                    if daysSince >= 3 {
                        let bonus = min(Double(daysSince) * 0.05, 0.3)
                        score += bonus
                        reasons.append("\(daysSince) 天未专项训练该目标")
                    }
                }
            }

            if lowSleep && target.category == "recovery" {
                score += 0.5
                reasons.insert("睡眠不足，建议以恢复训练为主", at: 0)
            }

            if !reasons.isEmpty {
                results.append(MovementTargetSuggestion(target: target, score: min(score, 1.0), reasons: reasons))
            }
        }

        return results
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0 }
    }
}
