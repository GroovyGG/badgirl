import SwiftUI
import SwiftData

@main
struct Bad_GirlApp: App {

    @State private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitManager)
                .task {
                    await healthKitManager.requestAuthorization()
                }
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
