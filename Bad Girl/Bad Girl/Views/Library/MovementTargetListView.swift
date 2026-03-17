import SwiftUI
import SwiftData

struct MovementTargetListView: View {
    @Query(sort: \MovementTarget.sortOrder) private var allTargets: [MovementTarget]
    @Query(sort: \Sport.sortOrder) private var sports: [Sport]

    @State private var selectedSportFilter: String? = nil
    @State private var searchText = ""

    private var filtered: [MovementTarget] {
        allTargets.filter { t in
            let sportMatch = selectedSportFilter == nil
                ? true
                : (selectedSportFilter == "general" ? t.sport == nil : t.sport?.code == selectedSportFilter)
            let searchMatch = searchText.isEmpty
                || (t.displayNameZh ?? t.name).localizedCaseInsensitiveContains(searchText)
                || t.name.localizedCaseInsensitiveContains(searchText)
            return sportMatch && searchMatch
        }
    }

    private var grouped: [(key: String, targets: [MovementTarget])] {
        let g = Dictionary(grouping: filtered) { $0.trainingDomain?.code ?? "other" }
        let order = ["general_training", "sport_specific_training", "match_play", "recovery", "other"]
        return order.compactMap { key in
            guard let targets = g[key], !targets.isEmpty else { return nil }
            return (key: key, targets: targets)
        }
    }

    private func domainLabel(_ code: String) -> String {
        switch code {
        case "general_training":        return "基础训练"
        case "sport_specific_training": return "专项训练"
        case "match_play":              return "比赛"
        case "recovery":                return "恢复"
        default:                        return "其他"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sport filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "全部", isSelected: selectedSportFilter == nil) { selectedSportFilter = nil }
                    FilterChip(label: "基础", isSelected: selectedSportFilter == "general") { selectedSportFilter = "general" }
                    ForEach(sports.filter { $0.isActive }) { sport in
                        FilterChip(
                            label: sport.displayNameZh ?? sport.name,
                            isSelected: selectedSportFilter == sport.code,
                            color: Color.forSport(sport.code)
                        ) { selectedSportFilter = sport.code }
                    }
                }
                .padding(.horizontal).padding(.vertical, 8)
            }

            List {
                ForEach(grouped, id: \.key) { group in
                    Section(domainLabel(group.key)) {
                        ForEach(group.targets) { target in
                            NavigationLink(destination: MovementTargetDetailView(target: target)) {
                                MovementTargetRow(target: target)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索训练目标")
        }
        .navigationTitle("训练目标")
    }
}

private struct MovementTargetRow: View {
    let target: MovementTarget

    private var categoryLabel: String {
        switch target.category {
        case "strength":      return "力量"
        case "explosiveness": return "爆发"
        case "endurance":     return "耐力"
        case "stability":     return "稳定"
        case "mobility":      return "灵活"
        case "skill":         return "技术"
        case "coordination":  return "协调"
        case "recovery":      return "恢复"
        default:              return target.category ?? ""
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.forSport(target.sport?.code))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(target.displayNameZh ?? target.name)
                    .font(.subheadline).fontWeight(.medium)
                HStack(spacing: 4) {
                    if !categoryLabel.isEmpty {
                        Text(categoryLabel)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let sport = target.sport {
                        Text("· \(sport.displayNameZh ?? sport.name)")
                            .font(.caption).foregroundStyle(Color.forSport(sport.code))
                    }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption).fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(isSelected ? color : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
