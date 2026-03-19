import SwiftUI
import SwiftData

/// Multi-step session logging form.
/// Can be embedded as a tab (isEmbedded: true) or shown as a sheet (isEmbedded: false).
struct LogSessionView: View {
    @Binding var isPresented: Bool
    let isEmbedded: Bool

    @Environment(\.modelContext) private var context
    @Environment(HealthKitManager.self) private var healthKit

    @State private var formData = LogFormData()
    @State private var currentStep = 0
    @State private var isSaving = false
    @State private var showSuccess = false

    private let totalSteps = 7
    private let stepTitles = ["数据来源", "类型", "时间", "目标", "指标", "评分", "复盘"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar + step labels
                StepProgressBar(currentStep: currentStep, totalSteps: totalSteps, titles: stepTitles)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Divider().padding(.top, 12)

                // Step content
                TabView(selection: $currentStep) {
                    DataSourceStepView(formData: formData).tag(0)
                    SessionTypeStepView(formData: formData).tag(1)
                    DateTimeStepView(formData: formData).tag(2)
                    MovementTargetStepView(formData: formData).tag(3)
                    MetricsStepView(formData: formData).tag(4)
                    BodyScoresStepView(formData: formData).tag(5)
                    ReflectionStepView(formData: formData).tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentStep)

                Divider()

                // Navigation buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button("上一步") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }

                    if currentStep < totalSteps - 1 {
                        Button("下一步") {
                            withAnimation { currentStep += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentStep == 1 && formData.trainingDomain == nil)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button {
                            saveSession()
                        } label: {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("保存训练")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("记录训练")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEmbedded {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            formData.reset()
                            isPresented = false
                        }
                    }
                }
            }
            .alert("保存成功", isPresented: $showSuccess) {
                Button("好") {
                    formData.reset()
                    currentStep = 0
                    if !isEmbedded { isPresented = false }
                }
            } message: {
                Text("训练记录已保存")
            }
        }
    }

    private func saveSession() {
        guard let domain = formData.trainingDomain else { return }
        isSaving = true

        let session = TrainingSession(
            sessionDate: formData.sessionDate,
            sessionType: formData.sessionType,
            trainingDomain: domain,
            sport: formData.sport
        )
        session.intensityRPE = Int(formData.intensityRPE.rounded())
        session.energyLevel = Int(formData.energyLevel.rounded())
        session.completionScore = Int(formData.completionScore.rounded())
        if let start = formData.startTime, let end = formData.endTime {
            session.startTime = start
            session.endTime = end
            session.durationMinutes = Int(end.timeIntervalSince(start) / 60)
        } else {
            session.durationMinutes = formData.durationMinutes
        }
        context.insert(session)

        // Session targets
        for target in formData.selectedTargets {
            let st = SessionTarget(trainingSession: session, movementTarget: target)
            context.insert(st)
        }

        // Metric entries
        for (defID, value) in formData.metricValues {
            // We need to find the MetricDefinition by id — we use a fetch
            let descriptor = FetchDescriptor<MetricDefinition>(
                predicate: #Predicate { $0.id == defID }
            )
            if let def = try? context.fetch(descriptor).first {
                let entry = SessionMetricEntry(trainingSession: session, metricDefinition: def)
                entry.valueNumber = value
                context.insert(entry)
            }
        }
        for (defID, text) in formData.metricTextValues where !text.isEmpty {
            let descriptor = FetchDescriptor<MetricDefinition>(
                predicate: #Predicate { $0.id == defID }
            )
            if let def = try? context.fetch(descriptor).first {
                let entry = SessionMetricEntry(trainingSession: session, metricDefinition: def)
                entry.valueText = text
                context.insert(entry)
            }
        }

        // Reflection
        let hasReflection = !formData.whatImproved.isEmpty || !formData.whatFeltWrong.isEmpty
            || !formData.bodyFeedback.isEmpty || !formData.tomorrowFocus.isEmpty || !formData.freeNote.isEmpty
        if hasReflection {
            let reflection = SessionReflection(trainingSession: session)
            reflection.whatImproved = formData.whatImproved.isEmpty ? nil : formData.whatImproved
            reflection.whatFeltWrong = formData.whatFeltWrong.isEmpty ? nil : formData.whatFeltWrong
            reflection.bodyFeedback = formData.bodyFeedback.isEmpty ? nil : formData.bodyFeedback
            reflection.tomorrowFocus = formData.tomorrowFocus.isEmpty ? nil : formData.tomorrowFocus
            reflection.freeNote = formData.freeNote.isEmpty ? nil : formData.freeNote
            context.insert(reflection)
        }

        try? context.save()

        if formData.dataSource == .appleWatch {
            // Sync Apple Watch / HealthKit data for this session
            Task {
                let snapshot = await healthKit.buildSnapshot(for: formData.sessionDate)
                await MainActor.run {
                    snapshot.trainingSession = session
                    context.insert(snapshot)
                    try? context.save()
                    isSaving = false
                    showSuccess = true
                }
            }
        } else {
            // Fully manual: no HealthKit import
            isSaving = false
            showSuccess = true
        }
    }
}

// MARK: - Step Progress Bar

private struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let titles: [String]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5)).frame(height: 4)
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 4)

            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Text(titles[i])
                        .font(.caption2)
                        .foregroundStyle(i == currentStep ? .blue : .secondary)
                        .fontWeight(i == currentStep ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
