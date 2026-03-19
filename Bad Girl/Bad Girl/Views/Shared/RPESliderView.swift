import SwiftUI

/// Reusable 1–10 labeled slider with color feedback.
struct RPESliderView: View {
    let label: String
    let sublabel: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline).fontWeight(.medium)
                    Text(sublabel)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(value.rounded()))")
                    .font(.title2).fontWeight(.bold).monospacedDigit()
                    .foregroundStyle(Color.forRPE(Int(value.rounded())))
                    .frame(width: 36)
            }

            Slider(value: $value, in: 1...10, step: 1)
                .tint(Color.forRPE(Int(value.rounded())))
                .accessibilityLabel(label)
                .accessibilityValue("\(Int(value.rounded()))，满分 10")
                .accessibilityHint("左右滑动调整强度")

            HStack {
                Text("轻松").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("极限").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
