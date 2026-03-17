import SwiftUI
import SwiftData

struct MetricDefinitionListView: View {
    @Query(sort: \MetricDefinition.sortOrder) private var metrics: [MetricDefinition]
    @State private var searchText = ""

    private var filtered: [MetricDefinition] {
        guard !searchText.isEmpty else { return metrics }
        return metrics.filter {
            ($0.displayNameZh ?? $0.name).localizedCaseInsensitiveContains(searchText)
            || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var grouped: [(key: String, metrics: [MetricDefinition])] {
        let g = Dictionary(grouping: filtered) { $0.sport?.code ?? "general" }
        var result: [(String, [MetricDefinition])] = [("general", g["general"] ?? [])]
        for key in g.keys where key != "general" {
            result.append((key, g[key] ?? []))
        }
        return result.filter { !$0.1.isEmpty }
    }

    private func groupLabel(_ code: String) -> String {
        switch code {
        case "general":     return "通用"
        case "badminton":   return "羽毛球"
        case "climbing":    return "攀岩"
        case "tennis":      return "网球"
        default:            return code
        }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.key) { group in
                Section(groupLabel(group.key)) {
                    ForEach(group.metrics) { metric in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(metric.displayNameZh ?? metric.name)
                                    .font(.subheadline).fontWeight(.medium)
                                Spacer()
                                if let unit = metric.unit {
                                    Text(unit)
                                        .font(.caption)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(Color(.tertiarySystemBackground), in: Capsule())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            HStack(spacing: 6) {
                                Text(metric.valueType)
                                    .font(.caption).foregroundStyle(.secondary)
                                if !metric.isActive {
                                    Text("已停用")
                                        .font(.caption).foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索指标")
        .navigationTitle("指标定义")
    }
}
