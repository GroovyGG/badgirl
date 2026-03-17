import SwiftUI

struct DayDetailView: View {
    let date: Date
    let sessions: [TrainingSession]
    let planned: [PlannedSession]
    let onAddPlan: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(date.shortDateString)
                        .font(.headline)
                    if date.isToday {
                        Text("今天")
                            .font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Button(action: onAddPlan) {
                        Label("计划训练", systemImage: "plus.circle")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if sessions.isEmpty && planned.isEmpty {
                    Text("这天没有训练记录或计划")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    // Logged sessions
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("已完成", systemImage: "checkmark.circle.fill")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(.green)
                                .padding(.horizontal)

                            ForEach(sessions) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    SessionCardView(session: session)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Planned sessions
                    if !planned.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("计划中", systemImage: "calendar.badge.clock")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            ForEach(planned) { plan in
                                PlannedSessionCard(plan: plan)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
}

private struct PlannedSessionCard: View {
    let plan: PlannedSession
    @Environment(\.modelContext) private var context

    private var typeLabel: String {
        switch plan.sessionType {
        case "game":     return "比赛"
        case "training": return "训练"
        case "gym":      return "健身"
        case "mobility": return "灵活"
        case "recovery": return "恢复"
        default:         return plan.sessionType
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray3))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(plan.sport?.displayNameZh ?? plan.trainingDomain?.displayNameZh ?? "训练")
                        .font(.subheadline).fontWeight(.semibold)
                    Text(typeLabel)
                        .font(.caption)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                        .foregroundStyle(.secondary)
                }
                if !plan.plannedTargets.isEmpty {
                    Text(plan.plannedTargets.compactMap { $0.movementTarget?.displayNameZh }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Mark as skipped
            Menu {
                Button("标记为已跳过", role: .destructive) {
                    plan.status = "skipped"
                    plan.updatedAt = Date()
                    try? context.save()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
