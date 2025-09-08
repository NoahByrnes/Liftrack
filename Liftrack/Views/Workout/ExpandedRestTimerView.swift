import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ExpandedRestTimerView: View {
    @Binding var remainingTime: Int
    let totalDuration: Int
    let isRunning: Bool
    let onDismiss: () -> Void
    let onStop: () -> Void
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @State private var animationProgress: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Timer Display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 250, height: 250)
                    
                    // Smooth animated progress circle
                    Circle()
                        .trim(from: 0, to: animationProgress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    settings.accentColor.color,
                                    settings.accentColor.color.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: animationProgress)
                    
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
                .onAppear {
                    // Set initial progress
                    animationProgress = timerManager.restProgress
                }
                .onChange(of: timerManager.restTimeRemaining) { _, newValue in
                    // Update animation when time changes
                    withAnimation(.linear(duration: 0.5)) {
                        if timerManager.restTotalDuration > 0 {
                            animationProgress = CGFloat(newValue) / CGFloat(timerManager.restTotalDuration)
                        }
                    }
                }
                .onChange(of: isRunning) { _, running in
                    if running && timerManager.restTotalDuration > 0 {
                        // Start smooth countdown animation for the entire duration
                        withAnimation(.linear(duration: Double(remainingTime))) {
                            animationProgress = 0
                        }
                    }
                }
                
                // Quick adjustment buttons
                if isRunning {
                    HStack(spacing: 32) {
                        Button(action: {
                            timerManager.adjustRestTime(by: -15)
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
                            timerManager.adjustRestTime(by: 15)
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
                                    #if os(iOS)
                                    .background(Color(UIColor.systemGray6))
                                    #else
                                    .background(Color.gray.opacity(0.1))
                                    #endif
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
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
        totalDuration: 90,
        isRunning: true,
        onDismiss: {},
        onStop: {}
    )
}