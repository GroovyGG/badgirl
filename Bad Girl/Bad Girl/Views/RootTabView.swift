import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showLogSheet = false

    enum Tab: Int {
        case home, log, calendar, progress, library
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showLogSheet: $showLogSheet)
                .tabItem {
                    Label("今日", systemImage: selectedTab == .home ? "house.fill" : "house")
                }
                .tag(Tab.home)

            LogSessionView(isPresented: .constant(true), isEmbedded: true)
                .tabItem {
                    Label("记录", systemImage: "plus.circle.fill")
                }
                .tag(Tab.log)

            CalendarView()
                .tabItem {
                    Label("训练历", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            ProgressDashboardView()
                .tabItem {
                    Label("趋势", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)

            LibraryView()
                .tabItem {
                    Label("更多", systemImage: "square.grid.2x2")
                }
                .tag(Tab.library)
        }
        .sheet(isPresented: $showLogSheet) {
            LogSessionView(isPresented: $showLogSheet, isEmbedded: false)
        }
    }
}
