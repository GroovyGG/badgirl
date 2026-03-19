import SwiftUI
import Combine

/// Count-down interval timer: work → rest → work … with optional rounds.
/// Used during training for work/rest intervals (e.g. 45s work, 15s rest).
struct IntervalTimerView: View {
    enum Phase: String {
        case work = "训练中"
        case rest = "休息"
    }

    // Config (editable when idle)
    @State private var workSeconds: Int = 45
    @State private var restSeconds: Int = 15
    @State private var rounds: Int? = 8  // nil = unlimited

    // Run state
    @State private var currentPhase: Phase = .work
    @State private var phaseEndDate: Date?
    @State private var currentRound: Int = 1
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var isCompleted: Bool = false
    @State private var timerCancellable: AnyCancellable?

    private let timerTick = Timer.publish(every: 1, on: .main, in: .common)
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    private var remainingSeconds: Int {
        guard let end = phaseEndDate else {
            return currentPhase == .work ? workSeconds : restSeconds
        }
        return max(0, Int(end.timeIntervalSinceNow))
    }

    private var displayTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var roundsLabel: String {
        if let total = rounds {
            return "第 \(currentRound) / \(total) 轮"
        }
        return "第 \(currentRound) 轮"
    }

    private var canEditSettings: Bool {
        !isRunning && !isCompleted
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Countdown + phase + round
                VStack(spacing: 12) {
                    Text(displayTime)
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .contentTransition(.numericText())
                        .accessibilityLabel("剩余时间 \(displayTime)")
                        .accessibilityValue(displayTime)

                    Text(currentPhase.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(currentPhase == .work ? .orange : .green)
                        .accessibilityLabel("当前阶段 \(currentPhase.rawValue)")

                    if isRunning || isPaused || (isCompleted && (rounds == nil || currentRound > 1)) {
                        Text(roundsLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(roundsLabel)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

                // Start / Pause / Reset
                HStack(spacing: 20) {
                    if !isRunning && !isCompleted {
                        Button {
                            startTimer()
                        } label: {
                            Label("开始", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .disabled(workSeconds <= 0 && restSeconds <= 0)
                        .accessibilityLabel("开始计时")
                        .accessibilityHint("按设定的训练与休息时间开始倒计时")
                    }

                    if isRunning || isPaused {
                        Button {
                            if isPaused {
                                resumeTimer()
                            } else {
                                pauseTimer()
                            }
                        } label: {
                            Label(isPaused ? "继续" : "暂停", systemImage: isPaused ? "play.fill" : "pause.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel(isPaused ? "继续" : "暂停")
                        .accessibilityHint(isPaused ? "继续倒计时" : "暂停倒计时")

                        Button {
                            resetTimer()
                        } label: {
                            Label("重置", systemImage: "arrow.counterclockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("重置")
                        .accessibilityHint("重置计时器并恢复设定")
                    }

                    if isCompleted {
                        Text("完成")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Button {
                            resetTimer()
                        } label: {
                            Label("再来一轮", systemImage: "arrow.counterclockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("再来一轮")
                        .accessibilityHint("重置并重新开始")
                    }
                }
                .padding(.horizontal, 24)

                // Settings: work / rest / rounds (when idle)
                if canEditSettings || isCompleted {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("计时设置")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        HStack(spacing: 16) {
                            DurationStepper(title: "训练", seconds: $workSeconds, range: 5...600, step: 5)
                                .disabled(!canEditSettings)
                            DurationStepper(title: "休息", seconds: $restSeconds, range: 5...300, step: 5)
                                .disabled(!canEditSettings)
                        }

                        HStack {
                            Text("轮数")
                                .font(.subheadline)
                                .frame(width: 60, alignment: .leading)
                            Picker("轮数", selection: $rounds) {
                                Text("无限").tag(Optional<Int>.none)
                                ForEach([3, 5, 8, 10, 12, 15, 20], id: \.self) { n in
                                    Text("\(n) 轮").tag(Optional(n))
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(!canEditSettings)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 20)
            .navigationTitle("训练计时器")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timerTick) { _ in
                tick()
            }
            .onDisappear {
                timerCancellable?.cancel()
                timerCancellable = nil
            }
        }
        .onAppear {
            haptic.prepare()
        }
    }

    private func startTimer() {
        isCompleted = false
        isPaused = false
        isRunning = true
        currentPhase = .work
        currentRound = 1
        let duration = currentPhase == .work ? workSeconds : restSeconds
        phaseEndDate = Date().addingTimeInterval(TimeInterval(duration))
        timerCancellable = AnyCancellable(timerTick.connect())
    }

    private func pauseTimer() {
        isPaused = true
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
        // phaseEndDate stays; we'll adjust on resume
    }

    private func resumeTimer() {
        isPaused = false
        isRunning = true
        // Re-anchor end date from current remaining
        phaseEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timerCancellable = AnyCancellable(timerTick.connect())
    }

    private func resetTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isRunning = false
        isPaused = false
        isCompleted = false
        currentPhase = .work
        currentRound = 1
        phaseEndDate = nil
    }

    private func tick() {
        guard isRunning, !isPaused else { return }
        if remainingSeconds <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        if currentPhase == .work {
            currentPhase = .rest
            phaseEndDate = Date().addingTimeInterval(TimeInterval(restSeconds))
            haptic.impactOccurred()
        } else {
            currentPhase = .work
            if let total = rounds, currentRound >= total {
                isRunning = false
                isCompleted = true
                timerCancellable?.cancel()
                timerCancellable = nil
                phaseEndDate = nil
                haptic.impactOccurred(intensity: 1.0)
                return
            }
            currentRound += 1
            phaseEndDate = Date().addingTimeInterval(TimeInterval(workSeconds))
            haptic.impactOccurred()
        }
    }
}

// MARK: - Duration stepper

private struct DurationStepper: View {
    let title: String
    @Binding var seconds: Int
    let range: ClosedRange<Int>
    let step: Int

    private var displayValue: String {
        if seconds < 60 {
            return "\(seconds) 秒"
        }
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 {
            return "\(m) 分钟"
        }
        return "\(m) 分 \(s) 秒"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    seconds = max(range.lowerBound, seconds - step)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text(displayValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(minWidth: 70)

                Button {
                    seconds = min(range.upperBound, seconds + step)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    IntervalTimerView()
}
