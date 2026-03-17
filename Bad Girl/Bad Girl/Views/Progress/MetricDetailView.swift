import SwiftUI
import Charts

struct MetricDetailView: View {
    let metric: MetricDefinition
    let dataPoints: [MetricDataPoint]

    private var average: Double? {
        guard !dataPoints.isEmpty else { return nil }
        return dataPoints.map { $0.value }.reduce(0, +) / Double(dataPoints.count)
    }
    private var best: Double? { dataPoints.map { $0.value }.min() }
    private var latest: Double? { dataPoints.last?.value }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary stats
                HStack(spacing: 0) {
                    StatTile(label: "最新", value: latest.map { String(format: "%.1f", $0) } ?? "--", unit: metric.unit ?? "")
                    Divider().frame(height: 50)
                    StatTile(label: "平均", value: average.map { String(format: "%.1f", $0) } ?? "--", unit: metric.unit ?? "")
                    Divider().frame(height: 50)
                    StatTile(label: "最佳", value: best.map { String(format: "%.1f", $0) } ?? "--", unit: metric.unit ?? "")
                    Divider().frame(height: 50)
                    StatTile(label: "记录次数", value: "\(dataPoints.count)", unit: "次")
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                // Full chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("趋势图").font(.headline)

                    if dataPoints.count > 1 {
                        Chart(dataPoints) { point in
                            LineMark(
                                x: .value("日期", point.date),
                                y: .value(metric.displayNameZh ?? metric.name, point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.blue.gradient)

                            AreaMark(
                                x: .value("日期", point.date),
                                y: .value(metric.displayNameZh ?? metric.name, point.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.blue.opacity(0.1).gradient)

                            PointMark(
                                x: .value("日期", point.date),
                                y: .value(metric.displayNameZh ?? metric.name, point.value)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(40)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 6)) {
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxisLabel(metric.unit ?? "")
                        .frame(height: 200)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("需要至少 2 条数据才能显示趋势图")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }

                // Data table
                if !dataPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("历史数据").font(.headline)
                        ForEach(dataPoints.reversed()) { point in
                            HStack {
                                Text(point.date.shortDateString)
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.1f", point.value))
                                    .font(.subheadline).fontWeight(.semibold).monospacedDigit()
                                Text(metric.unit ?? "")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(metric.displayNameZh ?? metric.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3).fontWeight(.bold).monospacedDigit()
            Text(unit.isEmpty ? " " : unit)
                .font(.caption2).foregroundStyle(.secondary)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
