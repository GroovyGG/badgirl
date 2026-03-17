import SwiftUI
import SwiftData

struct MuscleGroupView: View {
    @Query(sort: \MuscleGroup.sortOrder) private var allMuscles: [MuscleGroup]

    private var rootMuscles: [MuscleGroup] {
        allMuscles.filter { $0.parent == nil }
    }

    private func bodyRegionLabel(_ code: String?) -> String {
        switch code {
        case "upper":    return "上肢"
        case "lower":    return "下肢"
        case "core":     return "核心"
        case "shoulder": return "肩部"
        case "hip":      return "髋部"
        case "ankle":    return "踝部"
        case "forearm":  return "前臂"
        default:         return code ?? "其他"
        }
    }

    var body: some View {
        List {
            if rootMuscles.isEmpty {
                ContentUnavailableView(
                    "暂无肌群数据",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("肌群数据需要手动配置")
                )
            } else {
                ForEach(rootMuscles) { muscle in
                    Section {
                        MuscleRow(muscle: muscle, indent: 0)
                        ForEach(muscle.children.sorted { $0.sortOrder < $1.sortOrder }) { child in
                            MuscleRow(muscle: child, indent: 1)
                        }
                    } header: {
                        Text(bodyRegionLabel(muscle.bodyRegion))
                    }
                }
            }
        }
        .navigationTitle("肌群参考")
    }
}

private struct MuscleRow: View {
    let muscle: MuscleGroup
    let indent: Int

    var body: some View {
        HStack(spacing: 8) {
            if indent > 0 {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2).foregroundStyle(.secondary)
                    .padding(.leading, CGFloat(indent) * 12)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(muscle.displayNameZh ?? muscle.name)
                    .font(.subheadline)
                    .fontWeight(indent == 0 ? .semibold : .regular)
                Text(muscle.name)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !muscle.children.isEmpty {
                Text("\(muscle.children.count) 个子群")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
