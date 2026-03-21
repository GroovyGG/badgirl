import SwiftUI
import SwiftData

struct MovementTargetStepView: View {
    @Bindable var formData: LogFormData
    @Query(sort: \MovementTarget.sortOrder) private var allTargets: [MovementTarget]

    private var filteredTargets: [MovementTarget] {
        allTargets.filter { t in
            guard t.isActive, AppScope.isSupportedSport(t.sport) else { return false }
            if let sport = formData.sport {
                return t.sport?.id == sport.id || t.sport == nil
            }
            if formData.selectedTrainingDomains.isEmpty { return false }
            return formData.selectedTrainingDomains.contains(where: { $0.id == t.trainingDomain?.id }) || t.sport == nil
        }
    }

    private var groupedTargets: [(key: String, targets: [MovementTarget])] {
        let grouped = Dictionary(grouping: filteredTargets) { $0.bodySystem ?? "other" }
        let order = ["lower_body", "upper_body", "core", "full_body", "movement", "recovery", "other"]
        return order.compactMap { key in
            guard let targets = grouped[key], !targets.isEmpty else { return nil }
            return (key: key, targets: targets)
        }
    }

    private func bodySystemLabel(_ code: String) -> String {
        switch code {
        case "lower_body": return "下肢"
        case "upper_body": return "上肢"
        case "core":       return "核心"
        case "full_body":  return "全身"
        case "movement":   return "动作"
        case "recovery":   return "恢复"
        default:           return "其他"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("选择训练目标").font(.headline)
                    Spacer()
                    Text("已选 \(formData.selectedTargets.count) 项")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if filteredTargets.isEmpty {
                    ContentUnavailableView(
                        "暂无训练目标",
                        systemImage: "target",
                        description: Text("请先在「更多」中添加训练目标")
                    )
                    .padding()
                } else {
                    ForEach(groupedTargets, id: \.key) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(bodySystemLabel(group.key))
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            ForEach(group.targets) { target in
                                TargetRow(
                                    target: target,
                                    isSelected: formData.selectedTargets.contains { $0.id == target.id }
                                ) {
                                    if let idx = formData.selectedTargets.firstIndex(where: { $0.id == target.id }) {
                                        formData.selectedTargets.remove(at: idx)
                                    } else {
                                        formData.selectedTargets.append(target)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

private struct TargetRow: View {
    let target: MovementTarget
    let isSelected: Bool
    let onTap: () -> Void

    private var categoryLabel: String {
        switch target.category {
        case "strength":        return "力量"
        case "explosiveness":   return "爆发"
        case "endurance":       return "耐力"
        case "stability":       return "稳定"
        case "mobility":        return "灵活"
        case "skill":           return "技术"
        case "coordination":    return "协调"
        case "recovery":        return "恢复"
        default:                return target.category ?? ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : Color(.systemGray3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(target.displayNameZh ?? target.name)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        if !categoryLabel.isEmpty {
                            Text(categoryLabel)
                                .font(.caption)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                        if let sport = target.sport {
                            Text(sport.displayNameZh ?? sport.name)
                                .font(.caption)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.forSport(sport.code).opacity(0.1), in: Capsule())
                                .foregroundStyle(Color.forSport(sport.code))
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                isSelected ? Color.blue.opacity(0.06) : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }
}
