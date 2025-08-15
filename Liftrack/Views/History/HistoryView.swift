import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
           sort: \WorkoutSession.completedAt, order: .reverse)
    private var completedSessions: [WorkoutSession]
    @State private var selectedTimeRange = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("History")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("\(completedSessions.count) workouts completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Stats Overview
                    if !completedSessions.isEmpty {
                        StatsOverview(sessions: completedSessions)
                            .padding(.horizontal)
                    }
                    
                    // Workout History
                    if completedSessions.isEmpty {
                        EmptyHistoryView()
                            .padding(.top, 60)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Workouts")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(completedSessions) { session in
                                    SessionCard(session: session)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct StatsOverview: View {
    let sessions: [WorkoutSession]
    
    var totalWorkouts: Int { sessions.count }
    var thisWeekWorkouts: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { ($0.completedAt ?? Date()) > weekAgo }.count
    }
    var totalTime: String {
        let total = sessions.compactMap { $0.duration }.reduce(0, +)
        let hours = Int(total) / 3600
        return "\(hours)h"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "calendar",
                value: "\(totalWorkouts)",
                label: "Total",
                color: .purple
            )
            
            StatCard(
                icon: "flame.fill",
                value: "\(thisWeekWorkouts)",
                label: "This Week",
                color: .orange
            )
            
            StatCard(
                icon: "clock.fill",
                value: totalTime,
                label: "Total Time",
                color: .blue
            )
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

struct SessionCard: View {
    let session: WorkoutSession
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: SessionDetailView(session: session)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.templateName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            if let completedAt = session.completedAt {
                                Label(completedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            if let duration = session.duration {
                                Label(formatDuration(duration), systemImage: "timer")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(session.exercises.count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Text("exercises")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Exercise summary
                if !session.exercises.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(session.exercises.prefix(4).sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Text(String(exercise.exerciseName.prefix(2)).uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            .offset(x: CGFloat(exercise.orderIndex * -8))
                        }
                        
                        Spacer()
                        
                        // Total volume
                        if let totalVolume = calculateTotalVolume(session) {
                            Text("\(Int(totalVolume)) lbs")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    private func calculateTotalVolume(_ session: WorkoutSession) -> Double? {
        let volume = session.exercises.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .map { $0.weight * Double($0.reps) }
            .reduce(0, +)
        return volume > 0 ? volume : nil
    }
}

struct SessionDetailView: View {
    let session: WorkoutSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session Info Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.completedAt?.formatted(date: .complete, time: .shortened) ?? "")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDuration(session.duration ?? 0))
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        StatBadge(label: "Exercises", value: "\(session.exercises.count)")
                        StatBadge(label: "Sets", value: "\(session.exercises.flatMap { $0.sets }.count)")
                        StatBadge(label: "Volume", value: "\(Int(calculateTotalVolume(session))) lbs")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                
                // Exercises
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    
                    ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                        ExerciseDetailCard(exercise: exercise)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.templateName)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    private func calculateTotalVolume(_ session: WorkoutSession) -> Double {
        session.exercises.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .map { $0.weight * Double($0.reps) }
            .reduce(0, +)
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExerciseDetailCard: View {
    let exercise: SessionExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.system(size: 18, weight: .semibold))
            
            VStack(spacing: 8) {
                HStack {
                    Text("Set")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    
                    Text("Weight")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    
                    Text("Reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                    
                    Text("Status")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                }
                
                ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .font(.system(size: 15, design: .rounded))
                            .frame(width: 40, alignment: .leading)
                        
                        Text("\(Int(set.weight)) lbs")
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity)
                        
                        Text("\(set.reps)")
                            .font(.system(size: 15))
                            .frame(width: 50)
                        
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set.isCompleted ? .green : .secondary)
                            .frame(width: 50)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("No Workout History")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            
            Text("Complete your first workout\nto start tracking progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}