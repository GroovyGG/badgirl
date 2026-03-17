import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var showLogSheet: Bool

    @Environment(HealthKitManager.self) private var healthKit
    @Query(sort: \TrainingSession.sessionDate, order: .reverse) private var allSessions: [TrainingSession]
    @Query(sort: \MovementTarget.sortOrder) private var allTargets: [MovementTarget]
    @Query(sort: \HealthSnapshot.snapshotDate, order: .reverse) private var healthSnapshots: [HealthSnapshot]
    @Query(sort: \DailyGoal.goalDate, order: .reverse) private var allGoals: [DailyGoal]

    private var recentSessions: [TrainingSession] { Array(allSessions.prefix(5)) }
    private var latestHealth: HealthSnapshot? { healthSnapshots.first }

    private var todayGoals: [DailyGoal] {
        allGoals.filter { Calendar.current.isDateInToday($0.goalDate) }
    }

    private var suggestions: [MovementTargetSuggestion] {
        TrainingSuggestionEngine.generate(
            recentSessions: recentSessions,
            allTargets: allTargets.filter { $0.isActive },
            latestHealth: latestHealth
        )
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · M月d日"
        return formatter.string(from: Date())
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

                    // Today's goals
                    if !todayGoals.isEmpty {
                        TodayGoalsSection(goals: todayGoals)
                            .padding(.horizontal)
                    }

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
        }
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
