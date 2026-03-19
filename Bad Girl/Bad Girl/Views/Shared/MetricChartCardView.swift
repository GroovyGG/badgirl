import SwiftUI
import Charts

struct MetricDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Compact Swift Charts card for a single metric's trend over recent sessions.
struct MetricChartCardView: View {
    let metricName: String
    let metricNameZh: String
    let unit: String
    let dataPoints: [MetricDataPoint]
    let lowerIsBetter: Bool

    private var latestValue: Double? { dataPoints.last?.value }
    private var trend: Double? {
        guard dataPoints.count >= 2,
              let last = dataPoints.last,
              let secondLast = dataPoints.dropLast().last else { return nil }
        return last.value - secondLast.value
    }
    private var trendColor: Color {
        guard let t = trend else { return .secondary }
        if lowerIsBetter { return t < 0 ? .green : .red }
        return t > 0 ? .green : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metricNameZh)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(metricName)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let latest = latestValue {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f", latest))
                            .font(.title2).fontWeight(.bold).monospacedDigit()
                        Text(unit)
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if let t = trend {
                    Image(systemName: t > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(trendColor)
                }
            }

            if dataPoints.count > 1 {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value(metricNameZh, point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue.gradient)

                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value(metricNameZh, point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue.opacity(0.08).gradient)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 60)
            } else {
                Text("暂无数据")
                    .font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metricNameZh) 趋势")
        .accessibilityValue(dataPoints.isEmpty ? "暂无数据" : "最新 \(String(format: "%.1f", latestValue ?? 0)) \(unit)，共 \(dataPoints.count) 个数据点")
        .accessibilityHint("展示近期 \(metricNameZh) 变化")
    }
}
