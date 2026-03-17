import SwiftUI

struct DateTimeStepView: View {
    @Bindable var formData: LogFormData
    @State private var useCustomDuration = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("训练日期").font(.headline)
                    DatePicker("", selection: $formData.sessionDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }

                // Time (optional)
                VStack(alignment: .leading, spacing: 12) {
                    Text("训练时间（可选）").font(.headline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("开始").font(.caption).foregroundStyle(.secondary)
                            DatePicker("", selection: Binding(
                                get: { formData.startTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: formData.sessionDate)! },
                                set: { formData.startTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading) {
                            Text("结束").font(.caption).foregroundStyle(.secondary)
                            DatePicker("", selection: Binding(
                                get: { formData.endTime ?? Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: formData.sessionDate)! },
                                set: { formData.endTime = $0 }
                            ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        if formData.startTime != nil {
                            formData.startTime = nil
                            formData.endTime = nil
                        } else {
                            formData.startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: formData.sessionDate)
                            formData.endTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: formData.sessionDate)
                        }
                    } label: {
                        Label(formData.startTime != nil ? "清除时间" : "设置具体时间", systemImage: formData.startTime != nil ? "xmark.circle" : "clock")
                            .font(.caption)
                    }
                }

                // Duration
                VStack(alignment: .leading, spacing: 12) {
                    Text("训练时长").font(.headline)

                    if let start = formData.startTime, let end = formData.endTime {
                        let mins = Int(end.timeIntervalSince(start) / 60)
                        HStack {
                            Image(systemName: "clock.fill").foregroundStyle(.blue)
                            Text("根据开始/结束时间计算：\(mins) 分钟")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        Stepper(
                            value: Binding(
                                get: { formData.durationMinutes ?? 60 },
                                set: { formData.durationMinutes = $0 }
                            ),
                            in: 5...300, step: 5
                        ) {
                            HStack {
                                Image(systemName: "clock")
                                Text("\(formData.durationMinutes ?? 60) 分钟")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }
}
