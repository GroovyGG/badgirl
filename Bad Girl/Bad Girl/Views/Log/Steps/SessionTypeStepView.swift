import SwiftUI
import SwiftData

struct SessionTypeStepView: View {
    @Bindable var formData: LogFormData

    @Query(sort: \TrainingDomain.sortOrder) private var domains: [TrainingDomain]
    @Query(sort: \Sport.sortOrder) private var sports: [Sport]

    private let sessionTypes: [(code: String, label: String, icon: String)] = [
        ("training", "跟教练训练", "figure.run"),
        ("game",     "比赛", "trophy.fill"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Session type picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("训练类型").font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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

                // Training domain — 12 canonical rows, flat list
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("训练域").font(.headline)
                        Text("羽毛球专项；可多选训练域")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(domains) { domain in
                        Button {
                            formData.toggleTrainingDomain(domain)
                            if !formData.selectedTrainingDomains.isEmpty {
                                formData.sport = sports.first { $0.code == AppScope.supportedSportCode }
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
                                if formData.isTrainingDomainSelected(domain) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .background(
                                formData.isTrainingDomainSelected(domain)
                                    ? Color.blue.opacity(0.08)
                                    : Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
}
