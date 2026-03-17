import SwiftUI

struct SuggestionDetailView: View {
    let suggestions: [MovementTargetSuggestion]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if suggestions.isEmpty {
                    ContentUnavailableView(
                        "暂无训练建议",
                        systemImage: "lightbulb.slash",
                        description: Text("记录至少一次训练后，系统会根据数据生成建议")
                    )
                } else {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        SuggestionRow(rank: index + 1, suggestion: suggestion)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("建议逻辑说明", systemImage: "info.circle")
                                .font(.subheadline).fontWeight(.semibold)
                            Text("建议基于：近期训练质量评分、距上次训练天数、疲劳度评分、以及昨晚睡眠质量。这是规则推算，不是 AI。")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("今日训练建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

private struct SuggestionRow: View {
    let rank: Int
    let suggestion: MovementTargetSuggestion

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray2)
        case 3: return .orange
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("\(rank)")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(rankColor)
                    .frame(width: 28, height: 28)
                    .background(rankColor.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.target.displayNameZh ?? suggestion.target.name)
                        .font(.headline)
                    if let sport = suggestion.target.sport {
                        Text(sport.displayNameZh ?? sport.name)
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.forSport(sport.code).opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.forSport(sport.code))
                    } else {
                        Text("基础训练")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("紧急度")
                        .font(.caption2).foregroundStyle(.secondary)
                    Text("\(Int(suggestion.score * 100))%")
                        .font(.subheadline).fontWeight(.bold).monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(suggestion.reasons, id: \.self) { reason in
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 38)
        }
        .padding(.vertical, 4)
    }
}
