import SwiftUI
import SwiftData

struct PlanSessionView: View {
    let defaultDate: Date
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \TrainingDomain.sortOrder) private var domains: [TrainingDomain]
    @Query(sort: \Sport.sortOrder) private var sports: [Sport]
    @Query(sort: \MovementTarget.sortOrder) private var allTargets: [MovementTarget]

    @State private var plannedDate: Date
    @State private var sessionType = "training"
    @State private var selectedDomain: TrainingDomain? = nil
    @State private var selectedSport: Sport? = nil
    @State private var selectedTargets: [MovementTarget] = []
    @State private var estimatedDuration: Int = 60
    @State private var priority: Int = 3
    @State private var note = ""

    init(defaultDate: Date, isPresented: Binding<Bool>) {
        self.defaultDate = defaultDate
        self._isPresented = isPresented
        self._plannedDate = State(initialValue: defaultDate)
    }

    private let sessionTypes: [(code: String, label: String)] = [
        ("training", "训练"), ("game", "比赛"), ("gym", "健身"),
        ("mobility", "灵活"), ("recovery", "恢复"),
    ]

    private var filteredTargets: [MovementTarget] {
        allTargets.filter { t in
            guard t.isActive, AppScope.isSupportedSport(t.sport) else { return false }
            if let sport = selectedSport { return t.sport?.id == sport.id || t.sport == nil }
            return t.trainingDomain?.id == selectedDomain?.id || t.sport == nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("日期") {
                    DatePicker("训练日期", selection: $plannedDate, displayedComponents: .date)
                }

                Section("类型") {
                    Picker("训练类型", selection: $sessionType) {
                        ForEach(sessionTypes, id: \.code) { Text($0.label).tag($0.code) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("训练域") {
                    ForEach(domains) { domain in
                        HStack {
                            Text(domain.displayNameZh ?? domain.name)
                            Spacer()
                            if selectedDomain?.id == domain.id {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDomain = domain
                            selectedSport = sports.first { $0.code == AppScope.supportedSportCode }
                        }
                    }
                }

                if selectedDomain != nil {
                    Section("运动项目") {
                        ForEach(sports.filter { $0.isActive && AppScope.isSupportedSport($0) }) { sport in
                            HStack {
                                Label(sport.displayNameZh ?? sport.name, systemImage: sport.iconName ?? "sportscourt")
                                Spacer()
                                if selectedSport?.id == sport.id {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedSport = sport }
                        }
                    }
                }

                Section("计划目标（可选）") {
                    ForEach(filteredTargets.prefix(10)) { target in
                        HStack {
                            Text(target.displayNameZh ?? target.name)
                            Spacer()
                            if selectedTargets.contains(where: { $0.id == target.id }) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let idx = selectedTargets.firstIndex(where: { $0.id == target.id }) {
                                selectedTargets.remove(at: idx)
                            } else {
                                selectedTargets.append(target)
                            }
                        }
                    }
                }

                Section("预估时长") {
                    Stepper("\(estimatedDuration) 分钟", value: $estimatedDuration, in: 15...300, step: 15)
                }

                Section("优先级") {
                    Picker("优先级", selection: $priority) {
                        ForEach(1...5, id: \.self) { i in Text("P\(i)").tag(i) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("备注") {
                    TextField("可选备注", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("计划训练")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedDomain == nil)
                }
            }
        }
    }

    private func save() {
        guard let domain = selectedDomain else { return }
        let plan = PlannedSession(
            plannedDate: plannedDate,
            sessionType: sessionType,
            trainingDomain: domain,
            sport: selectedSport,
            priority: priority
        )
        plan.estimatedDurationMinutes = estimatedDuration
        plan.note = note.isEmpty ? nil : note
        context.insert(plan)

        for target in selectedTargets {
            let pt = PlannedSessionTarget(plannedSession: plan, movementTarget: target)
            context.insert(pt)
        }

        try? context.save()
        isPresented = false
    }
}
