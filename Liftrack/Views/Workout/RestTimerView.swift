import SwiftUI

struct RestTimerView: View {
    @Binding var seconds: Int
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @Environment(\.dismiss) private var dismiss
    
    let presetTimes = [30, 60, 90, 120, 180]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Timer Display
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: isRunning ? CGFloat(remainingSeconds) / CGFloat(seconds) : 1)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: remainingSeconds)
                    
                    VStack {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: 60, weight: .thin, design: .monospaced))
                        
                        if !isRunning && remainingSeconds == 0 {
                            Text("Select time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Preset Times
                if !isRunning {
                    HStack(spacing: 12) {
                        ForEach(presetTimes, id: \.self) { time in
                            Button(action: {
                                seconds = time
                                remainingSeconds = time
                            }) {
                                Text("\(time)s")
                                    .font(.footnote)
                                    .fontWeight(seconds == time ? .bold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(seconds == time ? Color.purple : Color(.systemGray5))
                                    .foregroundColor(seconds == time ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
                
                // Control Buttons
                HStack(spacing: 32) {
                    if isRunning {
                        Button(action: stopTimer) {
                            Image(systemName: "stop.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    } else {
                        Button(action: startTimer) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        .disabled(remainingSeconds == 0)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            remainingSeconds = seconds
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stopTimer()
                // Play completion sound/haptic
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        remainingSeconds = seconds
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RestTimerView(seconds: .constant(90))
}