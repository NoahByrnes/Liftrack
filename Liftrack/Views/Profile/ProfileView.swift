import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var allSessions: [WorkoutSession]
    @Query private var allTemplates: [WorkoutTemplate]
    
    var completedWorkouts: Int {
        allSessions.filter { $0.completedAt != nil }.count
    }
    
    var totalWorkoutTime: TimeInterval {
        allSessions.compactMap { $0.duration }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Statistics") {
                    StatRow(title: "Total Workouts", value: "\(completedWorkouts)")
                    StatRow(title: "Total Time", value: formatDuration(totalWorkoutTime))
                    StatRow(title: "Templates Created", value: "\(allTemplates.count)")
                }
                
                Section("Settings") {
                    NavigationLink(destination: Text("Coming Soon")) {
                        Label("Preferences", systemImage: "gearshape")
                    }
                    NavigationLink(destination: Text("Coming Soon")) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.purple)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self], inMemory: true)
}