import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var allSessions: [WorkoutSession]
    @Query private var allTemplates: [WorkoutTemplate]
    @StateObject private var settings = SettingsManager.shared
    
    var completedWorkouts: Int {
        allSessions.filter { $0.completedAt != nil }.count
    }
    
    var totalWorkoutTime: TimeInterval {
        allSessions.compactMap { $0.duration }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header - Match Templates/History style
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("\(completedWorkouts) workouts completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Profile Avatar
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(settings.accentColor.color)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Stats Cards
                    HStack(spacing: 12) {
                        StatsCard(
                            icon: "figure.strengthtraining.traditional",
                            value: "\(completedWorkouts)",
                            label: "Workouts",
                            color: settings.accentColor.color
                        )
                        
                        StatsCard(
                            icon: "clock.fill",
                            value: formatDuration(totalWorkoutTime),
                            label: "Total Time",
                            color: .blue
                        )
                        
                        StatsCard(
                            icon: "square.stack.3d.up",
                            value: "\(allTemplates.count)",
                            label: "Templates",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        NavigationLink(destination: PreferencesView()) {
                            SettingsRow(
                                icon: "paintbrush.fill",
                                title: "Appearance",
                                subtitle: "Theme, colors, and display",
                                color: settings.accentColor.color
                            )
                        }
                        
                        NavigationLink(destination: WorkoutSettingsView()) {
                            SettingsRow(
                                icon: "dumbbell.fill",
                                title: "Workout Settings",
                                subtitle: "Timers, sounds, and behavior",
                                color: .orange
                            )
                        }
                        
                        NavigationLink(destination: DataManagementView()) {
                            SettingsRow(
                                icon: "externaldrive.fill",
                                title: "Data & Backup",
                                subtitle: "Export and manage your data",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: AboutView()) {
                            SettingsRow(
                                icon: "info.circle.fill",
                                title: "About",
                                subtitle: "Version and information",
                                color: .gray
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self], inMemory: true)
}