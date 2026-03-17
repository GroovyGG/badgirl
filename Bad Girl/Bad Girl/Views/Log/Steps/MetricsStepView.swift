import SwiftUI
import SwiftData

struct MetricsStepView: View {
    @Bindable var formData: LogFormData
    @Query(sort: \MetricDefinition.sortOrder) private var allDefinitions: [MetricDefinition]

    private var relevantMetrics: [MetricDefinition] {
        allDefinitions.filter { def in
            guard def.isActive else { return false }
            let domainMatch = def.trainingDomain?.id == formData.trainingDomain?.id
            let sportMatch = formData.sport == nil ? def.sport == nil : def.sport?.id == formData.sport?.id
            return domainMatch && (def.sport == nil || sportMatch)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("记录指标").font(.headline)
                    Spacer()
                    Text("全部可选").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if relevantMetrics.isEmpty {
                    ContentUnavailableView(
                        "暂无相关指标",
                        systemImage: "chart.bar",
                        description: Text("该训练域尚未配置指标定义")
                    )
                    .padding()
                } else {
                    ForEach(relevantMetrics) { metric in
                        MetricInputRow(metric: metric, formData: formData)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

private struct MetricInputRow: View {
    let metric: MetricDefinition
    @Bindable var formData: LogFormData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.displayNameZh ?? metric.name)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(metric.name)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let unit = metric.unit {
                    Text(unit)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }

            switch metric.valueType {
            case "score":
                ScoreInput(
                    value: Binding(
                        get: { formData.metricValues[metric.id] ?? 5 },
                        set: { formData.metricValues[metric.id] = $0 }
                    ),
                    range: 1...10
                )

            case "integer":
                Stepper(
                    "\(Int(formData.metricValues[metric.id] ?? 0)) \(metric.unit ?? "")",
                    value: Binding(
                        get: { formData.metricValues[metric.id] ?? 0 },
                        set: { formData.metricValues[metric.id] = $0 }
                    ),
                    in: 0...999,
                    step: 1
                )

            case "decimal", "duration_seconds":
                HStack {
                    TextField("0.0", value: Binding(
                        get: { formData.metricValues[metric.id] },
                        set: { formData.metricValues[metric.id] = $0 }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    if let unit = metric.unit {
                        Text(unit).foregroundStyle(.secondary)
                    }
                }

            case "text":
                TextField("填写备注", text: Binding(
                    get: { formData.metricTextValues[metric.id] ?? "" },
                    set: { formData.metricTextValues[metric.id] = $0 }
                ))
                .textFieldStyle(.roundedBorder)

            default:
                ScoreInput(
                    value: Binding(
                        get: { formData.metricValues[metric.id] ?? 5 },
                        set: { formData.metricValues[metric.id] = $0 }
                    ),
                    range: 1...10
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ScoreInput: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Slider(value: $value, in: range, step: 1)
                .tint(Color.forRPE(Int(value.rounded())))
            Text("\(Int(value.rounded()))")
                .font(.headline).monospacedDigit()
                .frame(width: 28)
                .foregroundStyle(Color.forRPE(Int(value.rounded())))
        }
    }
}
