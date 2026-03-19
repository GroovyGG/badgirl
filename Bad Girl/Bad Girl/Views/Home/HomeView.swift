import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var showLogSheet: Bool
    @State private var showIntervalTimer = false
    @State private var hasGeneratedRecommendations = false

    @Environment(\.modelContext) private var context
    @Environment(HealthKitManager.self) private var healthKit
    @Query(sort: \TrainingSession.sessionDate, order: .reverse) private var allSessions: [TrainingSession]
    @Query(sort: \MovementTarget.sortOrder) private var allTargets: [MovementTarget]
    @Query(sort: \HealthSnapshot.snapshotDate, order: .reverse) private var healthSnapshots: [HealthSnapshot]
    @Query(sort: \DailyGoal.goalDate, order: .reverse) private var allGoals: [DailyGoal]
    @Query(sort: \ExerciseRecommendation.recommendedDate, order: .reverse) private var allRecommendations: [ExerciseRecommendation]
    @Query(sort: \Exercise.sortOrder) private var allExercises: [Exercise]

    private var recentSessions: [TrainingSession] { Array(allSessions.prefix(5)) }
    private var latestHealth: HealthSnapshot? { healthSnapshots.first }

    private var todayGoals: [DailyGoal] {
        allGoals.filter { Calendar.current.isDateInToday($0.goalDate) }
    }

    private var suggestions: [MovementTargetSuggestion] {
        TrainingSuggestionEngine.generate(
            recentSessions: recentSessions,
            allTargets: allTargets.filter { $0.isActive && AppScope.isSupportedSport($0.sport) },
            latestHealth: latestHealth
        )
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · M月d日"
        return formatter.string(from: Date())
    }

    private var pendingRecommendations: [ExerciseRecommendation] {
        allRecommendations.filter { $0.status == "suggested" || $0.status == "accepted" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date header
                    Text(dateString)
                        .font(.title2).fontWeight(.bold)
                        .padding(.horizontal)

                    // Suggestion card
                    SuggestionCard(suggestions: suggestions)
                        .padding(.horizontal)

                    if !pendingRecommendations.isEmpty {
                        ExerciseRecommendationCard(
                            recommendations: Array(pendingRecommendations.prefix(3)),
                            onAccept: acceptRecommendation,
                            onSkip: skipRecommendation,
                            onComplete: completeRecommendation,
                            onReplace: replaceRecommendation
                        )
                        .padding(.horizontal)
                    }

                    // Today's goals
                    if !todayGoals.isEmpty {
                        TodayGoalsSection(goals: todayGoals)
                            .padding(.horizontal)
                    }

                    // Interval timer card
                    Button {
                        showIntervalTimer = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "timer")
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .frame(width: 44, height: 44)
                                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("训练计时器")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("间歇训练 · 工作/休息倒计时")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Quick log button
                    Button {
                        showLogSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("记录今日训练")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal)

                    // Recent sessions
                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("最近训练")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(recentSessions.prefix(3)) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    SessionCardView(session: session)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // HealthKit strip
                    if let health = latestHealth {
                        HealthStripView(snapshot: health)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Bad Girl 🏸")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showIntervalTimer) {
                IntervalTimerView()
            }
            .task(id: allSessions.count) {
                guard !hasGeneratedRecommendations else { return }
                ExerciseRecommendationEngine.generateAndPersist(
                    context: context,
                    recentSessions: recentSessions,
                    allTargets: allTargets.filter { $0.isActive && AppScope.isSupportedSport($0.sport) },
                    latestHealth: latestHealth
                )
                hasGeneratedRecommendations = true
            }
        }
    }

    // MARK: - Recommendation actions

    private func acceptRecommendation(_ recommendation: ExerciseRecommendation) {
        recommendation.status = "accepted"
        recommendation.acceptedAt = Date()
        recommendation.updatedAt = Date()
        try? context.save()
    }

    private func skipRecommendation(_ recommendation: ExerciseRecommendation) {
        recommendation.status = "skipped"
        recommendation.skippedAt = Date()
        recommendation.updatedAt = Date()
        try? context.save()
    }

    private func completeRecommendation(_ recommendation: ExerciseRecommendation) {
        recommendation.status = "completed"
        if recommendation.acceptedAt == nil {
            recommendation.acceptedAt = Date()
        }
        recommendation.completedAt = Date()
        recommendation.updatedAt = Date()

        let log = ExerciseLog(
            completedDate: Date(),
            recommendation: recommendation,
            trainingSession: recommendation.sourceSession,
            exercise: recommendation.exercise
        )
        log.intensity = recommendation.intensity
        log.durationMinutes = recommendation.durationMinutes
        log.userFeedback = "按推荐完成"
        context.insert(log)
        try? context.save()
        ExerciseRecommendationAnalytics.evaluateOutcomeSignals(context: context)
    }

    private func replaceRecommendation(_ recommendation: ExerciseRecommendation) {
        recommendation.status = "completed"
        recommendation.completedAt = Date()
        recommendation.updatedAt = Date()

        let fallbackExercise = allExercises.first { $0.isActive }
        let log = ExerciseLog(
            completedDate: Date(),
            recommendation: nil,
            trainingSession: recommendation.sourceSession,
            exercise: fallbackExercise
        )
        log.intensity = recommendation.intensity
        log.durationMinutes = recommendation.durationMinutes
        log.userFeedback = "用户替换为其他动作"
        context.insert(log)
        try? context.save()
        ExerciseRecommendationAnalytics.evaluateOutcomeSignals(context: context)
    }
}

// MARK: - Suggestion Card

private struct SuggestionCard: View {
    let suggestions: [MovementTargetSuggestion]
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("今天练什么", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                Spacer()
                Button("查看详情") { showDetail = true }
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            if suggestions.isEmpty {
                Text("暂无建议，先记录几次训练吧")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(suggestions) { s in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.forSport(s.target.sport?.code))
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.target.displayNameZh ?? s.target.name)
                                .font(.subheadline).fontWeight(.semibold)
                            Text(s.reasons.first ?? "")
                                .font(.caption).foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(s.score * 100))%")
                            .font(.caption).monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showDetail) {
            SuggestionDetailView(suggestions: suggestions)
        }
    }
}

private struct ExerciseRecommendationCard: View {
    let recommendations: [ExerciseRecommendation]
    let onAccept: (ExerciseRecommendation) -> Void
    let onSkip: (ExerciseRecommendation) -> Void
    let onComplete: (ExerciseRecommendation) -> Void
    let onReplace: (ExerciseRecommendation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("主动补充练习建议", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
            }

            ForEach(recommendations) { recommendation in
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.exercise?.displayNameZh ?? recommendation.exercise?.name ?? recommendation.targetProblem ?? "补充训练建议")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let reason = recommendation.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if recommendation.status == "suggested" {
                            Button("采纳") { onAccept(recommendation) }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
                        Button("跳过") { onSkip(recommendation) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("完成") { onComplete(recommendation) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("替换") { onReplace(recommendation) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                .padding(10)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Today's Goals

private struct TodayGoalsSection: View {
    let goals: [DailyGoal]
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日目标")
                .font(.headline)

            ForEach(goals) { goal in
                HStack(spacing: 12) {
                    Button {
                        goal.isCompleted.toggle()
                        goal.updatedAt = Date()
                        try? context.save()
                    } label: {
                        Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(goal.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title ?? goal.trainingDomain?.displayNameZh ?? "训练目标")
                            .font(.subheadline)
                            .strikethrough(goal.isCompleted)
                        if let sport = goal.sport {
                            Text(sport.displayNameZh ?? sport.name)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Health Strip

private struct HealthStripView: View {
    let snapshot: HealthSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("健康数据", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.red)

            HStack(spacing: 0) {
                HealthMetricTile(icon: "moon.fill", value: snapshot.sleepHours.map { String(format: "%.1f", $0) } ?? "--", unit: "hr", color: .indigo)
                Divider().frame(height: 40)
                HealthMetricTile(icon: "heart.fill", value: snapshot.avgHeartRate.map { String(Int($0)) } ?? "--", unit: "bpm", color: .red)
                Divider().frame(height: 40)
                HealthMetricTile(icon: "flame.fill", value: snapshot.activeEnergyKcal.map { String(Int($0)) } ?? "--", unit: "kcal", color: .orange)
                Divider().frame(height: 40)
                HealthMetricTile(icon: "figure.walk", value: snapshot.steps.map { String($0) } ?? "--", unit: "步", color: .green)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct HealthMetricTile: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(value).font(.subheadline).fontWeight(.bold).monospacedDigit()
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
