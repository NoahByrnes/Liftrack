import SwiftUI

struct RestTimerBar: View {
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var showingRestTimer = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Timer display and label
                VStack(alignment: .leading, spacing: 4) {
                    Text("REST TIMER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatRestTime(timerManager.restTimeRemaining))
                        .font(.system(size: 32, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Time adjustment buttons
                HStack(spacing: 12) {
                    adjustmentButton(systemName: "minus", adjustment: -15)
                    adjustmentButton(systemName: "plus", adjustment: 15)
                }
                
                // Expand button
                Text("Expand")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [settings.accentColor.color.opacity(0.4), settings.accentColor.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.3))
                            )
                    )
                    .onTapGesture {
                        showingRestTimer = true
                    }
                
                // End Rest button
                Text("End Rest")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.1))
                            )
                    )
                    .onTapGesture {
                        timerManager.endRestTimer()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blur(radius: 10)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
        }
        .sheet(isPresented: $showingRestTimer) {
            ExpandedRestTimerView(
                remainingTime: $timerManager.restTimeRemaining,
                totalDuration: timerManager.restTotalDuration,
                isRunning: timerManager.showRestBar,
                onDismiss: {
                    showingRestTimer = false
                },
                onStop: {
                    timerManager.endRestTimer()
                    showingRestTimer = false
                }
            )
            .presentationDetents([.medium])
        }
    }
    
    private func adjustmentButton(systemName: String, adjustment: Int) -> some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.2))
            )
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            )
            .onTapGesture {
                timerManager.adjustRestTime(by: adjustment)
            }
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}