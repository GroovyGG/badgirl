import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(HealthKitManager.self) private var healthKit
    @Query(sort: \TrainingDomain.sortOrder) private var trainingDomains: [TrainingDomain]
    @State private var showDomainDebugSheet = false

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

#if DEBUG
                Section("调试") {
                    Button("查看当前 TrainingDomain（数据库实际值）") {
                        showDomainDebugSheet = true
                    }
                }
#endif
            }
            .navigationTitle("更多")
            .sheet(isPresented: $showDomainDebugSheet) {
                NavigationStack {
                    List(trainingDomains) { domain in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(domain.displayNameZh ?? domain.name)
                                .font(.headline)
                            Text("code: \(domain.code)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("name: \(domain.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("sortOrder: \(domain.sortOrder)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                    .navigationTitle("TrainingDomain")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") { showDomainDebugSheet = false }
                        }
                    }
                }
            }
        }
    }
}
