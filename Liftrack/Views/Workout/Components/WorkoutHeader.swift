import SwiftUI
import SwiftData

struct WorkoutHeader: View {
    @Bindable var session: WorkoutSession
    @Binding var isEditMode: Bool
    @Binding var showingFinishConfirmation: Bool
    @Binding var showingEmptyWorkoutAlert: Bool
    let heroAnimationPhase: Int
    let onMinimize: () -> Void
    
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // Top row with minimize and menu
                HStack {
                    // Minimize button
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.3))
                        )
                        .overlay(
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 18, weight: .medium))
                        )
                        .onTapGesture {
                            onMinimize()
                        }
                    
                    Spacer()
                    
                    // Edit/Done toggle
                    Text(isEditMode ? "Done" : "Edit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial.opacity(0.3))
                                )
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isEditMode.toggle()
                            }
                            settings.impactFeedback(style: .light)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                // Central timer display
                VStack(spacing: 8) {
                    Text(formatTime(timerManager.elapsedTime))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .scaleEffect(heroAnimationPhase >= 1 ? 1 : 0.5)
                        .opacity(heroAnimationPhase >= 1 ? 1 : 0)
                        .blur(radius: heroAnimationPhase >= 1 ? 0 : 10)
                    
                    if !session.templateName.isEmpty {
                        Text(session.templateName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(heroAnimationPhase >= 2 ? 1 : 0)
                            .offset(y: heroAnimationPhase >= 2 ? 0 : 20)
                    }
                }
                
                // Action buttons row
                HStack(spacing: 12) {
                    // Rest timer button
                    Menu {
                        ForEach([30, 60, 90, 120], id: \.self) { seconds in
                            Button(action: {
                                timerManager.startRestTimer(seconds: seconds)
                            }) {
                                Label(formatPresetTime(seconds), systemImage: "timer")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "timer")
                            Text("Rest")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial.opacity(0.3))
                                )
                        )
                    }
                    
                    // Finish workout button
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Finish")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.6), Color.green.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.green.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial.opacity(0.3))
                                    )
                            )
                    )
                    .onTapGesture {
                        if session.exercises.isEmpty {
                            showingEmptyWorkoutAlert = true
                        } else {
                            showingFinishConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func formatPresetTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds % 60 == 0 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
        }
    }
}