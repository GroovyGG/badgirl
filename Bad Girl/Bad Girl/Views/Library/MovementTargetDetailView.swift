import SwiftUI
import SwiftData
import Charts

struct MovementTargetDetailView: View {
    let target: MovementTarget
    @Query(sort: \TrainingSession.sessionDate) private var allSessions: [TrainingSession]

    private var sessionTargets: [SessionTarget] {
        allSessions.flatMap { $0.sessionTargets }.filter { $0.movementTarget?.id == target.id }
    }

    private var qualityTrend: [MetricDataPoint] {
        sessionTargets.compactMap { st -> MetricDataPoint? in
            guard let q = st.qualityScore, let s = st.trainingSession else { return nil }
            return MetricDataPoint(date: s.sessionDate, value: Double(q))
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(target.displayNameZh ?? target.name)
                            .font(.title2).fontWeight(.bold)
                        Spacer()
                        if let sport = target.sport {
                            Text(sport.displayNameZh ?? sport.name)
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.forSport(sport.code).opacity(0.12), in: Capsule())
                                .foregroundStyle(Color.forSport(sport.code))
                        } else {
                            Text("基础训练")
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color(.tertiarySystemBackground), in: Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(target.name).font(.subheadline).foregroundStyle(.secondary)
                    if let desc = target.targetDescription {
                        Text(desc).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            // Properties
            Section("属性") {
                if let cat = target.category {
                    LabeledContent("类别", value: cat)
                }
                if let body = target.bodySystem {
                    LabeledContent("身体区域", value: body)
                }
                LabeledContent("侧向区分", value: target.sideSpecific ? "是" : "否")
                LabeledContent("可测试", value: target.isTestable ? "是" : "否")
                LabeledContent("训练次数", value: "\(sessionTargets.count) 次")
            }

            // Muscle groups
            if !target.muscles.isEmpty {
                Section("相关肌群") {
                    ForEach(target.muscles) { link in
                        HStack {
                            Text(link.muscleGroup?.displayNameZh ?? link.muscleGroup?.name ?? "—")
                                .font(.subheadline)
                            Spacer()
                            Text(link.role)
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Lv\(link.contributionLevel)")
                                .font(.caption2)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color(.tertiarySystemBackground), in: Capsule())
                        }
                    }
                }
            }

            // Quality trend
            if qualityTrend.count > 1 {
                Section("质量趋势") {
                    Chart(qualityTrend) { point in
                        LineMark(
                            x: .value("日期", point.date),
                            y: .value("质量", point.value)
                        )
                        .foregroundStyle(Color.green.gradient)
                        PointMark(
                            x: .value("日期", point.date),
                            y: .value("质量", point.value)
                        )
                        .foregroundStyle(.green)
                    }
                    .chartYScale(domain: 1...10)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .frame(height: 120)
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(target.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
