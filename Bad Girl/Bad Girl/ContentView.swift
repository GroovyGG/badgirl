import SwiftUI
import SwiftData

/// Placeholder root view — confirms SwiftData and HealthKit are wired up correctly.
/// Replace with real tab navigation once the foundation build passes.
struct ContentView: View {

    @Environment(HealthKitManager.self) private var healthKit
    @Query(sort: \Sport.sortOrder) private var sports: [Sport]
    @Query(sort: \TrainingDomain.sortOrder) private var domains: [TrainingDomain]

    var body: some View {
        NavigationStack {
            List {
                Section("Sports") {
                    if sports.isEmpty {
                        Text("No sports found — seed data may not have run.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sports) { sport in
                            Label(
                                sport.displayNameZh ?? sport.name,
                                systemImage: sport.iconName ?? "sportscourt"
                            )
                        }
                    }
                }

                Section("Training Domains") {
                    ForEach(domains) { domain in
                        Text(domain.displayNameZh ?? domain.name)
                    }
                }

                Section("HealthKit") {
                    Label(
                        healthKit.isAuthorized ? "Authorized" : "Not authorized",
                        systemImage: healthKit.isAuthorized ? "heart.fill" : "heart.slash"
                    )
                    .foregroundStyle(healthKit.isAuthorized ? .green : .secondary)
                }
            }
            .navigationTitle("Bad Girl")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.container)
        .environment(HealthKitManager())
}
