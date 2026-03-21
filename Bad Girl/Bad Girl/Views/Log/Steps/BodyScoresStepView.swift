import SwiftUI

struct BodyScoresStepView: View {
    @Bindable var formData: LogFormData

    private var orderedDomains: [TrainingDomain] {
        formData.selectedTrainingDomains.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("训练评分").font(.headline)
                    Text("按每个训练域分别记录主观感受")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if orderedDomains.isEmpty {
                    ContentUnavailableView(
                        "请先选择训练域",
                        systemImage: "list.bullet.clipboard",
                        description: Text("返回「类型」一步，选择至少一个训练域")
                    )
                    .frame(minHeight: 200)
                } else {
                    ForEach(orderedDomains) { domain in
                        domainSection(domain)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            formData.syncFeelingsWithSelection()
        }
    }

    @ViewBuilder
    private func domainSection(_ domain: TrainingDomain) -> some View {
        let id = domain.id
        VStack(alignment: .leading, spacing: 14) {
            Text(domain.displayNameZh ?? domain.name)
                .font(.subheadline).fontWeight(.semibold)
            Text(domain.name)
                .font(.caption2).foregroundStyle(.tertiary)

            RPESliderView(
                label: "RPE 强度",
                sublabel: "Rate of Perceived Exertion",
                value: formData.bindingIntensityRPE(for: id)
            )

            RPESliderView(
                label: "体能状态",
                sublabel: "该项上的精力与身体状态",
                value: formData.bindingEnergyLevel(for: id)
            )

            RPESliderView(
                label: "完成度",
                sublabel: "该训练域相关计划完成比例",
                value: formData.bindingCompletionScore(for: id)
            )

            let f = formData.feelingsByDomainId[id] ?? DomainFeelings()
            HStack(spacing: 0) {
                ScoreSummaryTile(label: "强度", value: Int(f.intensityRPE.rounded()), color: Color.forRPE(Int(f.intensityRPE.rounded())))
                Divider().frame(height: 50)
                ScoreSummaryTile(label: "体能", value: Int(f.energyLevel.rounded()), color: Color.forRPE(Int(f.energyLevel.rounded())))
                Divider().frame(height: 50)
                ScoreSummaryTile(label: "完成", value: Int(f.completionScore.rounded()), color: Color.forRPE(Int(f.completionScore.rounded())))
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
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
