import SwiftUI
import SwiftData

struct CalendarView: View {
    @State private var displayedMonth: Date = Date().startOfMonth
    @State private var selectedDate: Date? = nil
    @State private var showPlanSheet = false

    @Query(sort: \TrainingSession.sessionDate) private var allSessions: [TrainingSession]
    @Query(sort: \PlannedSession.plannedDate) private var allPlanned: [PlannedSession]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    private var monthDays: [Date?] { Calendar.current.daysInMonth(for: displayedMonth) }

    private func sessions(for date: Date) -> [TrainingSession] {
        allSessions.filter { $0.sessionDate.isSameDay(as: date) }
    }
    private func planned(for date: Date) -> [PlannedSession] {
        allPlanned.filter { $0.plannedDate.isSameDay(as: date) && $0.status == "planned" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month navigation
                MonthNavigationHeader(
                    month: displayedMonth,
                    onPrev: { displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth)!.startOfMonth },
                    onNext: { displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth)!.startOfMonth }
                )

                // Weekday header
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                Divider()

                // Month grid
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                        if let date {
                            CalendarDayCell(
                                date: date,
                                isSelected: selectedDate?.isSameDay(as: date) ?? false,
                                sessions: sessions(for: date),
                                planned: planned(for: date)
                            )
                            .onTapGesture { selectedDate = date }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
                .padding(.horizontal, 4)

                Divider()

                // Day detail
                if let date = selectedDate {
                    DayDetailView(
                        date: date,
                        sessions: sessions(for: date),
                        planned: planned(for: date),
                        onAddPlan: { showPlanSheet = true }
                    )
                } else {
                    ContentUnavailableView(
                        "选择一天",
                        systemImage: "calendar.badge.plus",
                        description: Text("点击上方日历查看或计划训练")
                    )
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("训练历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedDate = Date()
                        showPlanSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showPlanSheet) {
                PlanSessionView(
                    defaultDate: selectedDate ?? Date(),
                    isPresented: $showPlanSheet
                )
            }
        }
    }
}

// MARK: - Month Navigation

private struct MonthNavigationHeader: View {
    let month: Date
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .frame(width: 44, height: 44)

            Spacer()

            Text(month.monthYearString)
                .font(.headline)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let sessions: [TrainingSession]
    let planned: [PlannedSession]

    private var isToday: Bool { date.isToday }

    private var dots: [(color: Color, id: String)] {
        var result: [(Color, String)] = []
        for s in sessions.prefix(3) {
            result.append((Color.forSessionType(s.sessionType), s.id.uuidString + "s"))
        }
        for p in planned.prefix(2) {
            result.append((Color(.systemGray3), p.id.uuidString + "p"))
        }
        return result.prefix(4).map { $0 }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.15) : Color.clear))
                    .frame(width: 32, height: 32)

                Text("\(date.dayNumber)")
                    .font(.subheadline)
                    .fontWeight(isToday || isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))
            }

            HStack(spacing: 2) {
                ForEach(dots.prefix(4), id: \.id) { dot in
                    Circle()
                        .fill(dot.color)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 52)
    }
}
