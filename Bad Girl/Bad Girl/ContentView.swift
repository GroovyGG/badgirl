import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.container)
        .environment(HealthKitManager())
}
