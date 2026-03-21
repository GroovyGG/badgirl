import SwiftUI
import SwiftData

/// Multi-step session logging form.
/// Can be embedded as a tab (isEmbedded: true) or shown as a sheet (isEmbedded: false).
struct LogSessionView: View {
    @Binding var isPresented: Bool
    let isEmbedded: Bool

    @Environment(\.modelContext) private var context

    @State private var formData = LogFormData()
    @State private var currentStep = 0
    @State private var isSaving = false
    @State private var showSuccess = false

    private let totalSteps = 4
    private let stepTitles = ["时间", "类型", "感受", "反馈"]

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
                    DateTimeStepView(formData: formData).tag(0)
                    SessionTypeStepView(formData: formData).tag(1)
                    BodyScoresStepView(formData: formData).tag(2)
                    ReflectionStepView(formData: formData).tag(3)
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
                        .disabled(currentStep == 1 && formData.selectedTrainingDomains.isEmpty)
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
        guard let primaryDomain = formData.selectedTrainingDomains.first else { return }
        isSaving = true

        let session = TrainingSession(
            sessionDate: formData.sessionDate,
            sessionType: formData.sessionType,
            trainingDomain: primaryDomain,
            sport: formData.sport
        )
        let orderedDomains = formData.selectedTrainingDomains.sorted { $0.sortOrder < $1.sortOrder }
        session.trainingDomainCodesOrdered = orderedDomains.map(\.code).joined(separator: ",")

        formData.syncFeelingsWithSelection()
        let payloads: [PerDomainFeelingsPayload] = orderedDomains.map { domain in
            let f = formData.feelingsByDomainId[domain.id] ?? DomainFeelings()
            return PerDomainFeelingsPayload(
                code: domain.code,
                intensityRPE: Int(f.intensityRPE.rounded()),
                energyLevel: Int(f.energyLevel.rounded()),
                completionScore: Int(f.completionScore.rounded())
            )
        }
        if let data = try? JSONEncoder().encode(payloads), let json = String(data: data, encoding: .utf8) {
            session.perDomainFeelingsJSON = json
        }
        let rpes = payloads.map(\.intensityRPE)
        let energies = payloads.map(\.energyLevel)
        let completions = payloads.map(\.completionScore)
        session.intensityRPE = rpes.isEmpty ? nil : rpes.reduce(0, +) / rpes.count
        session.energyLevel = energies.isEmpty ? nil : energies.reduce(0, +) / energies.count
        session.completionScore = completions.isEmpty ? nil : completions.reduce(0, +) / completions.count
        if let start = formData.startTime, let end = formData.endTime {
            session.startTime = start
            session.endTime = end
            session.durationMinutes = Int(end.timeIntervalSince(start) / 60)
        } else {
            session.durationMinutes = formData.durationMinutes
        }
        context.insert(session)

        // Reflection
        let hasReflection = !formData.whatImproved.isEmpty || !formData.whatFeltWrong.isEmpty
            || !formData.bodyFeedback.isEmpty || !formData.coachFeedback.isEmpty
            || !formData.tomorrowFocus.isEmpty || !formData.freeNote.isEmpty
        if hasReflection {
            let reflection = SessionReflection(trainingSession: session)
            reflection.whatImproved = formData.whatImproved.isEmpty ? nil : formData.whatImproved
            reflection.whatFeltWrong = formData.whatFeltWrong.isEmpty ? nil : formData.whatFeltWrong
            reflection.bodyFeedback = formData.bodyFeedback.isEmpty ? nil : formData.bodyFeedback
            reflection.coachFeedback = formData.coachFeedback.isEmpty ? nil : formData.coachFeedback
            reflection.tomorrowFocus = formData.tomorrowFocus.isEmpty ? nil : formData.tomorrowFocus
            reflection.freeNote = formData.freeNote.isEmpty ? nil : formData.freeNote
            context.insert(reflection)
        }

        try? context.save()
        let recentSessions = (try? context.fetch(FetchDescriptor<TrainingSession>())) ?? []
        let allTargets = (try? context.fetch(FetchDescriptor<MovementTarget>())) ?? []
        let latestHealth = (try? context.fetch(FetchDescriptor<HealthSnapshot>())).flatMap { snapshots in
            snapshots.sorted { $0.snapshotDate > $1.snapshotDate }.first
        }
        ExerciseRecommendationEngine.generateAndPersist(
            context: context,
            recentSessions: recentSessions,
            allTargets: allTargets,
            latestHealth: latestHealth
        )
        ExerciseRecommendationAnalytics.evaluateOutcomeSignals(context: context)
        isSaving = false
        showSuccess = true
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
