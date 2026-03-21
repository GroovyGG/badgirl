import SwiftUI
import SwiftData

struct ExerciseLogEntryView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context

    @Query(sort: \Exercise.sortOrder) private var exercises: [Exercise]
    @Query(sort: \ExerciseRecommendation.recommendedDate, order: .reverse) private var recommendations: [ExerciseRecommendation]

    @State private var selectedExerciseID: UUID? = nil
    @State private var selectedRecommendationID: UUID? = nil
    @State private var completedDate: Date = Date()
    @State private var durationMinutes: Int = 12
    @State private var intensity: String = "medium"
    @State private var userFeedback: String = ""
    @State private var weight: Double = 0
    @State private var reps: Int = 10
    @State private var sets: Int = 3
    @State private var durationSeconds: Int = 60
    @State private var count: Int = 10
    @State private var maxReps: Int = 0
    @State private var toFailure: Bool = false

    private let intensityOptions = ["low", "medium", "high"]

    private var selectedExercise: Exercise? {
        exercises.first { $0.id == selectedExerciseID }
    }

    private var pendingRecommendations: [ExerciseRecommendation] {
        recommendations.filter { $0.status == "suggested" || $0.status == "accepted" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("执行信息") {
                    DatePicker("完成时间", selection: $completedDate, displayedComponents: [.date, .hourAndMinute])
                    Picker("强度", selection: $intensity) {
                        ForEach(intensityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    Stepper("时长（分钟）: \(durationMinutes)", value: $durationMinutes, in: 1...180)
                }

                Section("选择项目") {
                    Picker("Exercise", selection: $selectedExerciseID) {
                        Text("请选择").tag(Optional<UUID>.none)
                        ForEach(exercises) { exercise in
                            Text(exercise.displayNameZh ?? exercise.name).tag(Optional(exercise.id))
                        }
                    }

                    Picker("关联 Recommendation（可选）", selection: $selectedRecommendationID) {
                        Text("不关联").tag(Optional<UUID>.none)
                        ForEach(pendingRecommendations) { rec in
                            Text(rec.targetProblem ?? rec.exercise?.displayNameZh ?? "推荐").tag(Optional(rec.id))
                        }
                    }
                }

                if let exercise = selectedExercise {
                    Section("执行字段") {
                        recordFields(for: exercise.recordType)
                    }
                }

                Section("反馈") {
                    TextField("执行后感受 / 备注", text: $userFeedback, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("记录 Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveExerciseLog()
                    }
                    .disabled(selectedExercise == nil)
                }
            }
            .onChange(of: selectedRecommendationID) { _, newValue in
                guard
                    let newValue,
                    let recommendation = recommendations.first(where: { $0.id == newValue })
                else { return }
                if selectedExerciseID == nil {
                    selectedExerciseID = recommendation.exercise?.id
                }
            }
        }
    }

    @ViewBuilder
    private func recordFields(for recordType: String) -> some View {
        switch recordType {
        case "weight_reps":
            Stepper("重量（kg）: \(Int(weight.rounded()))", value: $weight, in: 0...300, step: 1)
            Stepper("次数（reps）: \(reps)", value: $reps, in: 1...200)
            Stepper("组数（sets）: \(sets)", value: $sets, in: 1...20)
        case "time_count":
            Stepper("持续秒数: \(durationSeconds)", value: $durationSeconds, in: 5...7200, step: 5)
            Stepper("次数（count）: \(count)", value: $count, in: 1...500)
        case "max_reps":
            Stepper("最大次数: \(maxReps)", value: $maxReps, in: 0...500)
            Toggle("做到力竭", isOn: $toFailure)
        default:
            Stepper("持续秒数: \(durationSeconds)", value: $durationSeconds, in: 5...7200, step: 5)
        }
    }

    private func saveExerciseLog() {
        guard let exercise = selectedExercise else { return }
        let linkedRecommendation = recommendations.first { $0.id == selectedRecommendationID }

        let log = ExerciseLog(
            completedDate: completedDate,
            recommendation: linkedRecommendation,
            trainingSession: nil,
            exercise: exercise
        )
        log.durationMinutes = durationMinutes
        log.intensity = intensity
        log.userFeedback = userFeedback.isEmpty ? nil : userFeedback
        log.weight = (exercise.recordType == "weight_reps") ? weight : nil
        log.reps = (exercise.recordType == "weight_reps") ? reps : nil
        log.sets = (exercise.recordType == "weight_reps") ? sets : nil
        log.durationSeconds = (exercise.recordType == "time_count" || exercise.recordType == "duration") ? durationSeconds : nil
        log.count = (exercise.recordType == "time_count") ? count : nil
        log.maxReps = (exercise.recordType == "max_reps") ? maxReps : nil
        log.toFailure = (exercise.recordType == "max_reps") ? toFailure : nil
        log.updatedAt = Date()
        context.insert(log)

        if let linkedRecommendation {
            linkedRecommendation.status = "completed"
            linkedRecommendation.completedAt = completedDate
            linkedRecommendation.updatedAt = Date()
        }

        try? context.save()
        ExerciseRecommendationAnalytics.evaluateOutcomeSignals(context: context)
        isPresented = false
    }
}
