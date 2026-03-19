import SwiftUI

struct LibraryView: View {
    @Environment(HealthKitManager.self) private var healthKit

    var body: some View {
        NavigationStack {
            List {
                Section("训练库") {
                    NavigationLink(destination: MovementTargetListView()) {
                        Label("训练目标", systemImage: "target")
                    }
                    NavigationLink(destination: MuscleGroupView()) {
                        Label("肌群参考", systemImage: "figure.strengthtraining.traditional")
                    }
                    NavigationLink(destination: MetricDefinitionListView()) {
                        Label("指标定义", systemImage: "chart.bar.doc.horizontal")
                    }
                }

                Section("健康权限") {
                    HStack {
                        Label("HealthKit", systemImage: "heart.fill")
                        Spacer()
                        Text(healthKit.isAuthorized ? "已授权" : "未授权")
                            .foregroundStyle(healthKit.isAuthorized ? .green : .secondary)
                            .font(.caption)
                    }
                    if !healthKit.isAuthorized {
                        Button("请求 HealthKit 权限") {
                            Task { await healthKit.requestAuthorization() }
                        }
                        .foregroundStyle(.blue)
                        .accessibilityLabel("请求 HealthKit 权限")
                        .accessibilityHint("在系统弹窗中授权读取心率、活动与睡眠数据")
                    }
                    if let err = healthKit.authorizationError {
                        Text("错误：\(err.localizedDescription)")
                            .font(.caption).foregroundStyle(.red)
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("作者")
                        Spacer()
                        Text("GG")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("更多")
        }
    }
}
