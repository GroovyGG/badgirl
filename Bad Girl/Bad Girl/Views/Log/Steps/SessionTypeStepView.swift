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
                            formData.sport = sports.first { $0.code == AppScope.supportedSportCode }
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

                // Sport: app is badminton-only; once training domain is selected, sport is fixed as 羽毛球
                let needsSport = formData.trainingDomain != nil

                if needsSport {
                    HStack(spacing: 8) {
                        Text("运动项目").font(.subheadline).fontWeight(.semibold)
                        Text("羽毛球").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}
