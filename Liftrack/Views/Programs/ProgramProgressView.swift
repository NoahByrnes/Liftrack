import SwiftUI
import SwiftData

struct ProgramProgressView: View {
    let program: Program
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @Query private var sessions: [WorkoutSession]
    
    var programSessions: [WorkoutSession] {
        sessions.filter { $0.programId == program.id }
            .sorted { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) }
    }
    
    var completedWeeks: Set<Int> {
        Set(programSessions.compactMap { $0.programWeek })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall Progress
                    overallProgressCard
                    
                    // Weekly Progress Grid
                    weeklyProgressSection
                    
                    // Workout History
                    if !programSessions.isEmpty {
                        workoutHistorySection
                    }
                    
                    // Statistics
                    statisticsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Program Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var overallProgressCard: some View {
        VStack(spacing: 20) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: program.progressPercentage / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                settings.accentColor.color,
                                settings.accentColor.color.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: program.progressPercentage)
                
                VStack(spacing: 4) {
                    Text("\(Int(program.progressPercentage))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Complete")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats Row
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(programSessions.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(settings.accentColor.color)
                    Text("Workouts")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(program.currentWeek)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(settings.accentColor.color)
                    Text("Current Week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    let remaining = max(0, program.durationWeeks - program.currentWeek)
                    Text("\(remaining)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(settings.accentColor.color)
                    Text("Weeks Left")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WEEKLY PROGRESS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(1...program.durationWeeks, id: \.self) { weekNum in
                    WeekProgressTile(
                        weekNumber: weekNum,
                        isCompleted: isWeekCompleted(weekNum),
                        isCurrent: weekNum == program.currentWeek,
                        isDeload: program.deloadWeek == weekNum
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECENT WORKOUTS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink(destination: ProgramHistoryView(program: program)) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(programSessions.prefix(3)) { session in
                    ProgramSessionRow(session: session)
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STATISTICS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Total Volume
                StatRow(
                    icon: "scalemass",
                    title: "Total Volume",
                    value: formatVolume(calculateTotalVolume()),
                    color: .blue
                )
                
                // Average Workout Duration
                StatRow(
                    icon: "timer",
                    title: "Avg. Duration",
                    value: formatAverageDuration(),
                    color: .orange
                )
                
                // Consistency
                StatRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Consistency",
                    value: "\(calculateConsistency())%",
                    color: .green
                )
                
                // Personal Records
                StatRow(
                    icon: "trophy",
                    title: "Personal Records",
                    value: "\(countPRs())",
                    color: .purple
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // Helper functions
    private func isWeekCompleted(_ weekNumber: Int) -> Bool {
        guard let week = program.programWeeks.first(where: { $0.weekNumber == weekNumber }) else { return false }
        let workouts = week.scheduledWorkouts.filter { !$0.isRestDay }
        return !workouts.isEmpty && workouts.allSatisfy { $0.isCompleted }
    }
    
    private func calculateTotalVolume() -> Double {
        programSessions.flatMap { session in
            session.exercises.flatMap { $0.sets }
                .filter { $0.isCompleted }
                .map { $0.weight * Double($0.reps) }
        }.reduce(0, +)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume > 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }
    
    private func formatAverageDuration() -> String {
        let completedSessions = programSessions.filter { $0.completedAt != nil }
        guard !completedSessions.isEmpty else { return "—" }
        
        let totalDuration = completedSessions.compactMap { $0.duration }.reduce(0, +)
        let avgSeconds = totalDuration / Double(completedSessions.count)
        let minutes = Int(avgSeconds) / 60
        
        return "\(minutes) min"
    }
    
    private func calculateConsistency() -> Int {
        let expectedWorkouts = program.programWeeks
            .prefix(program.currentWeek)
            .flatMap { $0.scheduledWorkouts }
            .filter { !$0.isRestDay }
            .count
        
        guard expectedWorkouts > 0 else { return 100 }
        
        let completedWorkouts = programSessions.count
        return min(100, Int(Double(completedWorkouts) / Double(expectedWorkouts) * 100))
    }
    
    private func countPRs() -> Int {
        // This would need more sophisticated PR tracking
        // For now, return a placeholder
        return programSessions.count / 3
    }
}

struct WeekProgressTile: View {
    let weekNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let isDeload: Bool
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .frame(height: 60)
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                } else {
                    Text("W\(weekNumber)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textColor)
                }
                
                if isDeload {
                    Text("D")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .offset(x: 20, y: -20)
                }
            }
            
            if isCurrent {
                Text("Current")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(settings.accentColor.color)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return settings.accentColor.color.opacity(0.3)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var textColor: Color {
        if isCurrent {
            return settings.accentColor.color
        } else {
            return .secondary
        }
    }
}

struct ProgramSessionRow: View {
    let session: WorkoutSession
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.templateName)
                    .font(.system(size: 16, weight: .medium))
                
                HStack(spacing: 12) {
                    if let week = session.programWeek {
                        Label("Week \(week)", systemImage: "calendar")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    if let completedAt = session.completedAt {
                        Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let duration = session.duration {
                Text("\(Int(duration / 60)) min")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(settings.accentColor.color)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 15))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct ProgramHistoryView: View {
    let program: Program
    @Query private var sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    
    var programSessions: [WorkoutSession] {
        sessions.filter { $0.programId == program.id }
            .sorted { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) }
    }
    
    var body: some View {
        List {
            ForEach(programSessions) { session in
                NavigationLink(destination: Text("Workout Details")) {
                    ProgramSessionRow(session: session)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.inline)
    }
}