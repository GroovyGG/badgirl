import SwiftUI

struct ReflectionStepView: View {
    @Bindable var formData: LogFormData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("整体反馈").font(.headline)
                    Text("整次训练的复盘与备注；与上面「按训练域」的评分分开")
                        .font(.caption).foregroundStyle(.secondary)
                }

                ReflectionField(
                    icon: "arrow.up.circle.fill",
                    iconColor: .green,
                    title: "进步了什么",
                    placeholder: "今天比上次哪里做得更好？",
                    text: $formData.whatImproved
                )

                ReflectionField(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "哪里出了问题",
                    placeholder: "哪些动作或节奏感觉不对？",
                    text: $formData.whatFeltWrong
                )

                ReflectionField(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "身体反馈",
                    placeholder: "有没有哪里酸痛、不舒服？",
                    text: $formData.bodyFeedback
                )

                ReflectionField(
                    icon: "person.2.fill",
                    iconColor: .teal,
                    title: "教练反馈",
                    placeholder: "教练今天给了哪些建议或纠正？",
                    text: $formData.coachFeedback
                )

                ReflectionField(
                    icon: "target",
                    iconColor: .red,
                    title: "明天的重点",
                    placeholder: "下次训练想特别练什么？",
                    text: $formData.tomorrowFocus
                )

                ReflectionField(
                    icon: "note.text",
                    iconColor: .purple,
                    title: "自由备注",
                    placeholder: "其他想记录的事情...",
                    text: $formData.freeNote
                )
            }
            .padding()
        }
    }
}

private struct ReflectionField: View {
    let icon: String
    let iconColor: Color
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(iconColor)

            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundStyle(.tertiary)
                                .padding(12)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                )
        }
    }
}
