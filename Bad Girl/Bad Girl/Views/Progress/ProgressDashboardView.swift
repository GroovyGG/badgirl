import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query(sort: \MetricDefinition.sortOrder) private var allMetrics: [MetricDefinition]
    @Query(sort: \TrainingSession.sessionDate, order: .reverse) private var allSessions: [TrainingSession]
    @Query(sort: \HealthSnapshot.snapshotDate, order: .reverse) private var healthSnapshots: [HealthSnapshot]
    @Query(sort: \MovementTarget.sortOrder) private var allTargets: [MovementTarget]
    @Query(sort: \Sport.sortOrder) private var sports: [Sport]

    @State private var selectedSportCode: String? = "badminton"
    @State private var selectedRange: DateRange = .month3

    enum DateRange: String, CaseIterable {
        case month1 = "1个月"
        case month3 = "3个月"
        case month6 = "6个月"
        case all    = "全部"

        var days: Int? {
            switch self {
            case .month1: return 30
            case .month3: return 90
            case .month6: return 180
            case .all:    return nil
            }
        }
    }

    private var cutoffDate: Date? {
        guard let days = selectedRange.days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }

    private var filteredSessions: [TrainingSession] {
        allSessions.filter { s in
            guard let cutoff = cutoffDate else { return true }
            return s.sessionDate >= cutoff
        }
    }

    private var activeMetrics: [MetricDefinition] {
        allMetrics.filter { def in
            guard def.isActive, AppScope.isSupportedSport(def.sport) else { return false }
            if let code = selectedSportCode {
                return def.sport?.code == code || def.sport == nil
            }
            return def.sport == nil
        }
    }

    private var weakTargets: [(target: MovementTarget, avgQuality: Double)] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else { return [] }
        return allTargets
            .filter { $0.isActive && AppScope.isSupportedSport($0.sport) }
            .compactMap { target -> (target: MovementTarget, avgQuality: Double)? in
                let scores = filteredSessions
                    .filter { $0.sessionDate >= cutoff }
                    .flatMap { $0.sessionTargets }
                    .filter { $0.movementTarget?.id == target.id }
                    .compactMap { $0.qualityScore }
                guard !scores.isEmpty else { return nil }
                let avg = Double(scores.reduce(0, +)) / Double(scores.count)
                return avg < 6 ? (target: target, avgQuality: avg) : nil
            }
            .sorted { $0.avgQuality < $1.avgQuality }
    }

    private func dataPoints(for metric: MetricDefinition) -> [MetricDataPoint] {
        filteredSessions
            .flatMap { s in
                s.sessionMetricEntries
                    .filter { $0.metricDefinition?.id == metric.id }
                    .compactMap { entry -> MetricDataPoint? in
                        guard let v = entry.valueNumber else { return nil }
                        return MetricDataPoint(date: s.sessionDate, value: v)
                    }
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Sport filter — app scope: 全部 + 羽毛球 only
                    SportFilterPills(sports: sports.filter { AppScope.isSupportedSport($0) }, selectedCode: $selectedSportCode)
                        .padding(.horizontal)

                    // Date range filter
                    Picker("时间范围", selection: $selectedRange) {
                        ForEach(DateRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Metric cards
                    if activeMetrics.isEmpty {
                        Text("暂无指标数据")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("指标趋势").font(.headline).padding(.horizontal)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(activeMetrics) { metric in
                                    let points = dataPoints(for: metric)
                                    NavigationLink(destination: MetricDetailView(metric: metric, dataPoints: points)) {
                                        MetricChartCardView(
                                            metricName: metric.name,
                                            metricNameZh: metric.displayNameZh ?? metric.name,
                                            unit: metric.unit ?? "",
                                            dataPoints: points,
                                            lowerIsBetter: metric.code.contains("time") || metric.code.contains("error")
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Weak areas
                    if !weakTargets.isEmpty {
                        WeakAreasSection(weakTargets: weakTargets)
                            .padding(.horizontal)
                    }

                    // Session RPE trend
                    RPETrendSection(sessions: filteredSessions)
                        .padding(.horizontal)

                    // Apple Health strip (last 7 days)
                    let last7 = healthSnapshots.prefix(7).reversed()
                    if !last7.isEmpty {
                        HealthTrendSection(snapshots: Array(last7))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("趋势")
        }
    }
}

// MARK: - Sport filter pills

private struct SportFilterPills: View {
    let sports: [Sport]
    @Binding var selectedCode: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "全部", isSelected: selectedCode == nil) { selectedCode = nil }
                ForEach(sports.filter { $0.isActive }) { sport in
                    FilterPill(
                        label: sport.displayNameZh ?? sport.name,
                        isSelected: selectedCode == sport.code,
                        color: Color.forSport(sport.code)
                    ) { selectedCode = sport.code }
                }
            }
        }
    }
}

private struct FilterPill: View {
    let label: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? color : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weak Areas

private struct WeakAreasSection: View {
    let weakTargets: [(target: MovementTarget, avgQuality: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("近30天待提升", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(weakTargets.prefix(4), id: \.target.id) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.target.displayNameZh ?? item.target.name)
                            .font(.subheadline).fontWeight(.medium)
                        if let sport = item.target.sport {
                            Text(sport.displayNameZh ?? sport.name)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(String(format: "%.1f / 10", item.avgQuality))
                        .font(.subheadline).fontWeight(.bold).monospacedDigit()
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - RPE Trend

private struct RPETrendSection: View {
    let sessions: [TrainingSession]
    private var rpeData: [MetricDataPoint] {
        sessions
            .compactMap { s -> MetricDataPoint? in
                guard let rpe = s.intensityRPE else { return nil }
                return MetricDataPoint(date: s.sessionDate, value: Double(rpe))
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("训练强度趋势").font(.headline)
            if rpeData.count > 1 {
                Chart(rpeData) { point in
                    LineMark(x: .value("日期", point.date), y: .value("RPE", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue.gradient)
                    AreaMark(x: .value("日期", point.date), y: .value("RPE", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue.opacity(0.1).gradient)
                    PointMark(x: .value("日期", point.date), y: .value("RPE", point.value))
                        .foregroundStyle(.blue)
                        .symbolSize(30)
                }
                .chartYScale(domain: 1...10)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 120)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text("暂无数据").foregroundStyle(.secondary).padding()
            }
        }
    }
}

// MARK: - Health Trend

private struct HealthTrendSection: View {
    let snapshots: [HealthSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("近7天健康", systemImage: "heart.fill")
                .font(.headline).foregroundStyle(.red)

            if !snapshots.isEmpty {
                Chart(snapshots) { s in
                    if let sleep = s.sleepHours {
                        BarMark(
                            x: .value("日期", s.snapshotDate, unit: .day),
                            y: .value("睡眠", sleep)
                        )
                        .foregroundStyle(sleep < 6 ? Color.orange.gradient : Color.indigo.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) {
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxisLabel("睡眠(h)")
                .frame(height: 100)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}
