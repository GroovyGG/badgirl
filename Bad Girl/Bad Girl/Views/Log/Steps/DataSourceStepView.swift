import SwiftUI

/// Step 0: Choose whether Apple Watch recorded this activity or everything is manual.
struct DataSourceStepView: View {
    @Bindable var formData: LogFormData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("数据来源")
                    .font(.headline)
                Text("这次训练有没有用 Apple Watch 记录？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    // Type 1: Watch recorded — we sync health data, user inputs exercise
                    Button {
                        formData.dataSource = .appleWatch
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "applewatch")
                                .font(.title)
                                .foregroundStyle(formData.dataSource == .appleWatch ? .white : .primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    formData.dataSource == .appleWatch ? Color.green : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Watch 已记录")
                                    .font(.headline)
                                    .foregroundStyle(formData.dataSource == .appleWatch ? .white : .primary)
                                Text("同步心率、消耗等；训练内容（练了什么、指标、复盘）需手动填写")
                                    .font(.caption)
                                    .foregroundStyle(formData.dataSource == .appleWatch ? .white.opacity(0.9) : .secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if formData.dataSource == .appleWatch {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(
                            formData.dataSource == .appleWatch ? Color.green : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)

                    // Type 2: Fully manual
                    Button {
                        formData.dataSource = .manual
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "hand.draw")
                                .font(.title)
                                .foregroundStyle(formData.dataSource == .manual ? .white : .primary)
                                .frame(width: 48, height: 48)
                                .background(
                                    formData.dataSource == .manual ? Color.orange : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("完全手动记录")
                                    .font(.headline)
                                    .foregroundStyle(formData.dataSource == .manual ? .white : .primary)
                                Text("未佩戴手表或未记录；全部在本 app 内手动填写")
                                    .font(.caption)
                                    .foregroundStyle(formData.dataSource == .manual ? .white.opacity(0.9) : .secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if formData.dataSource == .manual {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(
                            formData.dataSource == .manual ? Color.orange : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}
