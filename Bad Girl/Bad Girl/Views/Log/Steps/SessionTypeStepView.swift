import SwiftUI
import SwiftData

struct SessionTypeStepView: View {
    @Bindable var formData: LogFormData

    @Query(sort: \TrainingDomain.sortOrder) private var domains: [TrainingDomain]
    @Query(sort: \Sport.sortOrder) private var sports: [Sport]

    private let sessionTypes: [(code: String, label: String, icon: String)] = [
        ("training", "训练", "figure.run"),
        ("game",     "比赛", "trophy.fill"),
        ("gym",      "健身", "dumbbell.fill"),
        ("mobility", "灵活", "figure.flexibility"),
        ("recovery", "恢复", "bed.double.fill"),
        ("mixed",    "综合", "square.grid.2x2"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Session type picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("训练类型").font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(sessionTypes, id: \.code) { type in
                            Button {
                                formData.sessionType = type.code
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: type.icon)
                                        .font(.title2)
                                    Text(type.label)
                                        .font(.caption).fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    formData.sessionType == type.code
                                        ? Color.forSessionType(type.code)
                                        : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(formData.sessionType == type.code ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Training domain
                VStack(alignment: .leading, spacing: 12) {
                    Text("训练域").font(.headline)

                    ForEach(domains) { domain in
                        Button {
                            formData.trainingDomain = domain
                            if domain.code != "sport_specific_training" && domain.code != "match_play" {
                                formData.sport = nil
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(domain.displayNameZh ?? domain.name)
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text(domain.name)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if formData.trainingDomain?.id == domain.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .background(
                                formData.trainingDomain?.id == domain.id
                                    ? Color.blue.opacity(0.08)
                                    : Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Sport picker (only for sport-specific or match_play)
                let needsSport = formData.trainingDomain?.code == "sport_specific_training"
                    || formData.trainingDomain?.code == "match_play"

                if needsSport {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("运动项目").font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(sports.filter { $0.isActive }) { sport in
                                Button {
                                    formData.sport = sport
                                } label: {
                                    HStack {
                                        Image(systemName: sport.iconName ?? "sportscourt")
                                        Text(sport.displayNameZh ?? sport.name)
                                            .font(.subheadline).fontWeight(.medium)
                                        Spacer()
                                        if formData.sport?.id == sport.id {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        formData.sport?.id == sport.id
                                            ? Color.forSport(sport.code).opacity(0.15)
                                            : Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 12)
                                    )
                                    .foregroundStyle(formData.sport?.id == sport.id ? Color.forSport(sport.code) : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
