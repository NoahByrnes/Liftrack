import SwiftUI

struct ExpandedRestTimerView: View {
    @Binding var remainingTime: Int
    let isRunning: Bool
    let onDismiss: () -> Void
    let onStop: () -> Void
    @State private var totalTime: Int = 90
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Timer Display
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: isRunning && totalTime > 0 ? CGFloat(remainingTime) / CGFloat(totalTime) : 1)
                        .stroke(settings.accentColor.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: remainingTime)
                    
                    VStack(spacing: 8) {
                        Text(formatTime(remainingTime))
                            .font(.system(size: 60, weight: .thin, design: .monospaced))
                        
                        if isRunning {
                            Text("Rest Timer Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Quick adjustment buttons
                if isRunning {
                    HStack(spacing: 32) {
                        Button(action: {
                            remainingTime = max(0, remainingTime - 15)
                        }) {
                            VStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(settings.accentColor.color)
                                Text("-15s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: {
                            remainingTime += 15
                            // Update total time if we're adding beyond the original
                            if remainingTime > totalTime {
                                totalTime = remainingTime
                            }
                        }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(settings.accentColor.color)
                                Text("+15s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Control Buttons
                HStack(spacing: 32) {
                    if isRunning {
                        Button(action: {
                            onStop()
                        }) {
                            VStack {
                                Image(systemName: "stop.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.red)
                                    .frame(width: 80, height: 80)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                Text("End Rest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
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
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            // Capture the initial total time for progress calculation
            totalTime = max(remainingTime, 90)
        }
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ExpandedRestTimerView(
        remainingTime: .constant(45),
        isRunning: true,
        onDismiss: {},
        onStop: {}
    )
}