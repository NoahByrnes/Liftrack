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
        HStack(spacing: 0) {
            // Main expand area - takes up most of the bar
            HStack(spacing: 12) {
                // Resume button
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(settings.accentColor.color)
                
                // Workout info
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.templateName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text(formatTime(timerManager.elapsedTime))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sets completed indicator
                if let completedSets = completedSetsCount() {
                    Text("\(completedSets.completed)/\(completedSets.total)")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(settings.accentColor.color.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                timerManager.isMinimized = false
                selectedTab = 1 // Switch to workout tab
                showingActiveWorkout = true
            }
            
            // Cancel button area with expanded touch target
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44) // Expanded touch area
                .contentShape(Rectangle())
                .onTapGesture {
                    showingCancelAlert = true
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
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