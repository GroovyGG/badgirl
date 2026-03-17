import SwiftUI

struct BodyScoresStepView: View {
    @Bindable var formData: LogFormData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("训练评分").font(.headline)
                    Text("主观感受评分，帮助系统更好地理解你的训练状态")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                RPESliderView(
                    label: "RPE 强度",
                    sublabel: "Rate of Perceived Exertion",
                    value: $formData.intensityRPE
                )

                RPESliderView(
                    label: "体能状态",
                    sublabel: "训练开始时的精力水平",
                    value: $formData.energyLevel
                )

                RPESliderView(
                    label: "完成度",
                    sublabel: "今日计划完成的比例",
                    value: $formData.completionScore
                )

                // Visual summary
                HStack(spacing: 0) {
                    ScoreSummaryTile(label: "强度", value: Int(formData.intensityRPE.rounded()), color: Color.forRPE(Int(formData.intensityRPE.rounded())))
                    Divider().frame(height: 50)
                    ScoreSummaryTile(label: "体能", value: Int(formData.energyLevel.rounded()), color: Color.forRPE(Int(formData.energyLevel.rounded())))
                    Divider().frame(height: 50)
                    ScoreSummaryTile(label: "完成", value: Int(formData.completionScore.rounded()), color: Color.forRPE(Int(formData.completionScore.rounded())))
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
    }
}

private struct ScoreSummaryTile: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2).fontWeight(.bold).monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
