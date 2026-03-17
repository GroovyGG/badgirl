import SwiftUI

/// Compact card representing a single TrainingSession in lists and the home feed.
struct SessionCardView: View {
    let session: TrainingSession

    private var sportCode: String? { session.sport?.code }
    private var accentColor: Color { Color.forSport(sportCode) }
    private var typeColor: Color { Color.forSessionType(session.sessionType) }

    private var typeLabel: String {
        switch session.sessionType {
        case "game":     return "比赛"
        case "training": return "训练"
        case "gym":      return "健身"
        case "mobility": return "灵活"
        case "recovery": return "恢复"
        case "mixed":    return "综合"
        default:         return session.sessionType
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Sport color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 4)

            // Sport icon
            Image(systemName: session.sport?.iconName ?? "figure.run")
                .font(.title3)
                .foregroundStyle(accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.sport?.displayNameZh ?? session.trainingDomain?.displayNameZh ?? "训练")
                        .font(.subheadline).fontWeight(.semibold)

                    Text(typeLabel)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(typeColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(typeColor)
                }

                Text(session.sessionDate.shortDateString)
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let rpe = session.intensityRPE {
                    HStack(spacing: 3) {
                        Text("RPE")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("\(rpe)")
                            .font(.subheadline).fontWeight(.bold).monospacedDigit()
                            .foregroundStyle(Color.forRPE(rpe))
                    }
                }
                if let duration = session.durationMinutes {
                    Text("\(duration)min")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
