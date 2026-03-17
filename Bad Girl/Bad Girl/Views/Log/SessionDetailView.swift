import SwiftUI

struct SessionDetailView: View {
    let session: TrainingSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private var accentColor: Color { Color.forSport(session.sport?.code) }

    var body: some View {
        List {
            // Header section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: session.sport?.iconName ?? "figure.run")
                        .font(.largeTitle)
                        .foregroundStyle(accentColor)
                        .frame(width: 56, height: 56)
                        .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.sport?.displayNameZh ?? session.trainingDomain?.displayNameZh ?? "训练")
                            .font(.title3).fontWeight(.bold)
                        Text(session.sessionDate.shortDateString)
                            .font(.subheadline).foregroundStyle(.secondary)
                        if let domain = session.trainingDomain {
                            Text(domain.displayNameZh ?? domain.name)
                                .font(.caption)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(.tertiarySystemBackground), in: Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Scores
            Section("训练评分") {
                if let rpe = session.intensityRPE {
                    ScoreRow(label: "RPE 强度", value: rpe, outOf: 10)
                }
                if let energy = session.energyLevel {
                    ScoreRow(label: "体能状态", value: energy, outOf: 10)
                }
                if let completion = session.completionScore {
                    ScoreRow(label: "完成度", value: completion, outOf: 10)
                }
                if let duration = session.durationMinutes {
                    HStack {
                        Text("时长")
                        Spacer()
                        Text("\(duration) 分钟")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Movement targets
            if !session.sessionTargets.isEmpty {
                Section("训练目标") {
                    ForEach(session.sessionTargets) { st in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(st.movementTarget?.displayNameZh ?? st.movementTarget?.name ?? "目标")
                                .font(.subheadline).fontWeight(.medium)
                            HStack(spacing: 12) {
                                if let q = st.qualityScore {
                                    Label("质量 \(q)", systemImage: "star.fill")
                                        .font(.caption).foregroundStyle(.yellow)
                                }
                                if let f = st.fatigueScore {
                                    Label("疲劳 \(f)", systemImage: "bolt.fill")
                                        .font(.caption).foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Metrics
            if !session.sessionMetricEntries.isEmpty {
                Section("记录指标") {
                    ForEach(session.sessionMetricEntries) { entry in
                        HStack {
                            Text(entry.metricDefinition?.displayNameZh ?? entry.metricDefinition?.name ?? "指标")
                                .font(.subheadline)
                            Spacer()
                            if let v = entry.valueNumber {
                                Text(String(format: "%.1f", v))
                                    .fontWeight(.semibold).monospacedDigit()
                                + Text(" \(entry.metricDefinition?.unit ?? "")")
                                    .font(.caption).foregroundStyle(.secondary)
                            } else if let t = entry.valueText {
                                Text(t).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Health snapshot
            if let health = session.healthSnapshots.first {
                Section("健康数据") {
                    if let hr = health.avgHeartRate { DataRow(label: "平均心率", value: "\(Int(hr)) bpm") }
                    if let energy = health.activeEnergyKcal { DataRow(label: "主动消耗", value: "\(Int(energy)) kcal") }
                    if let sleep = health.sleepHours { DataRow(label: "睡眠", value: String(format: "%.1f hr", sleep)) }
                }
            }

            // Reflection
            if let reflection = session.reflection {
                Section("训练复盘") {
                    if let text = reflection.whatImproved, !text.isEmpty {
                        ReflectionRow(icon: "arrow.up.circle.fill", color: .green, label: "进步了什么", text: text)
                    }
                    if let text = reflection.whatFeltWrong, !text.isEmpty {
                        ReflectionRow(icon: "exclamationmark.triangle.fill", color: .orange, label: "哪里出了问题", text: text)
                    }
                    if let text = reflection.bodyFeedback, !text.isEmpty {
                        ReflectionRow(icon: "figure.walk", color: .blue, label: "身体反馈", text: text)
                    }
                    if let text = reflection.tomorrowFocus, !text.isEmpty {
                        ReflectionRow(icon: "target", color: .red, label: "明天的重点", text: text)
                    }
                    if let text = reflection.freeNote, !text.isEmpty {
                        ReflectionRow(icon: "note.text", color: .purple, label: "自由备注", text: text)
                    }
                }
            }

            // Notes
            if let notes = session.notes, !notes.isEmpty {
                Section("备注") {
                    Text(notes).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("训练详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ScoreRow: View {
    let label: String
    let value: Int
    let outOf: Int
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .fontWeight(.bold).monospacedDigit()
                .foregroundStyle(Color.forRPE(value))
            Text("/\(outOf)")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct DataRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary).monospacedDigit()
        }
    }
}

private struct ReflectionRow: View {
    let icon: String
    let color: Color
    let label: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
