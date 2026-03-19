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
                .accessibilityLabel("今日")
                .accessibilityHint("今日训练与建议")

            LogTabEntryView(showLogSheet: $showLogSheet)
                .tabItem {
                    Label("记录", systemImage: "plus.circle.fill")
                }
                .tag(Tab.log)
                .accessibilityLabel("记录")
                .accessibilityHint("打开记录训练表单")

            CalendarView()
                .tabItem {
                    Label("训练历", systemImage: "calendar")
                }
                .tag(Tab.calendar)
                .accessibilityLabel("训练历")
                .accessibilityHint("查看日历与计划")

            ProgressDashboardView()
                .tabItem {
                    Label("趋势", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)
                .accessibilityLabel("趋势")
                .accessibilityHint("查看训练趋势与指标")

            LibraryView()
                .tabItem {
                    Label("更多", systemImage: "square.grid.2x2")
                }
                .tag(Tab.library)
                .accessibilityLabel("更多")
                .accessibilityHint("训练库、健康权限与关于")
        }
        .sheet(isPresented: $showLogSheet) {
            LogSessionView(isPresented: $showLogSheet, isEmbedded: false)
        }
    }
}

// MARK: - Log tab placeholder (opens form in sheet to avoid loading SwiftData in tab)

private struct LogTabEntryView: View {
    @Binding var showLogSheet: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("记录训练")
                    .font(.title2).fontWeight(.semibold)
                Text("点击下方按钮开始记录本次训练")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    showLogSheet = true
                } label: {
                    Label("开始记录", systemImage: "pencil")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
