import SwiftUI
import SwiftData

struct MinimizedWorkoutBar: View {
    let session: WorkoutSession
    @Binding var selectedTab: Int
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var showingActiveWorkout = false
    @State private var showingCancelAlert = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 12) {
            // Main expand area - takes up most of the bar
            HStack(spacing: 12) {
                // Resume button with soft circular design
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [settings.accentColor.color.opacity(0.6), settings.accentColor.color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(settings.accentColor.color.opacity(0.1))
                    )
                    .overlay(
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    )
                
                // Workout info
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.templateName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text(formatTime(timerManager.elapsedTime))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Sets completed indicator with soft design
                if let completedSets = completedSetsCount() {
                    Text("\(completedSets.completed)/\(completedSets.total)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
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
                                        .fill(settings.accentColor.color.opacity(0.1))
                                )
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                timerManager.isMinimized = false
                selectedTab = 1 // Switch to workout tab
                showingActiveWorkout = true
            }
            
            // Cancel button with soft circular design
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.red.opacity(0.3), .red.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.05))
                )
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                )
                .contentShape(Circle())
                .onTapGesture {
                    showingCancelAlert = true
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            NavigationStack {
                ActiveWorkoutView(session: session)
            }
        }
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func completedSetsCount() -> (completed: Int, total: Int)? {
        let allSets = session.exercises.flatMap { $0.sets }
        guard !allSets.isEmpty else { return nil }
        let completed = allSets.filter { $0.isCompleted }.count
        return (completed, allSets.count)
    }
    
    private func cancelWorkout() {
        timerManager.cleanup()
        
        // Clear all relationships first to avoid SwiftData crash
        session.exercises.removeAll()
        
        // Delete the session
        modelContext.delete(session)
        
        // Save changes
        try? modelContext.save()
    }
}

#Preview {
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let session = WorkoutSession()
    container.mainContext.insert(session)
    
    return VStack {
        Spacer()
        MinimizedWorkoutBar(session: session, selectedTab: .constant(1))
    }
    .modelContainer(container)
}