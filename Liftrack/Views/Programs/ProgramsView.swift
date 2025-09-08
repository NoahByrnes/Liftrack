import SwiftUI
import SwiftData

struct ProgramsView: View {
    @Query(sort: \Program.createdAt, order: .reverse) private var programs: [Program]
    @State private var showingCreateProgram = false
    @StateObject private var settings = SettingsManager.shared
    
    var activeProgram: Program? {
        programs.first { $0.isActive }
    }
    
    var inactivePrograms: [Program] {
        programs.filter { !$0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Programs")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("\(programs.count) programs created")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button(action: { showingCreateProgram = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(settings.accentColor.color)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Active Program Section
                    if let active = activeProgram {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACTIVE PROGRAM")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            NavigationLink(destination: ProgramDetailView(program: active)) {
                                ActiveProgramCard(program: active)
                            }
                        }
                    }
                    
                    // All Programs Section
                    if !inactivePrograms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ALL PROGRAMS")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(inactivePrograms) { program in
                                NavigationLink(destination: ProgramDetailView(program: program)) {
                                    ProgramCard(program: program)
                                }
                            }
                        }
                    }
                    
                    // Empty State
                    if programs.isEmpty {
                        EmptyProgramsView(onCreateTap: { showingCreateProgram = true })
                            .padding(.top, 60)
                    }
                    
                    Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingCreateProgram) {
                CreateProgramView()
            }
        }
    }
}

struct ActiveProgramCard: View {
    let program: Program
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Week \(program.currentWeek) of \(program.durationWeeks)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: program.progressPercentage / 100)
                        .stroke(settings.accentColor.color, lineWidth: 4)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(program.progressPercentage))%")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            
            Divider()
            
            // Next Workout
            if let nextWorkout = program.nextScheduledWorkout,
               let template = nextWorkout.template {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(settings.accentColor.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next: \(nextWorkout.dayName)")
                            .font(.system(size: 14, weight: .medium))
                        Text("\(template.exercises.count) exercises")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Start")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(settings.accentColor.color)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    settings.accentColor.color.opacity(0.1),
                    settings.accentColor.color.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(settings.accentColor.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ProgramCard: View {
    let program: Program
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(program.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Label("\(program.workoutTemplates.count) workouts", systemImage: "dumbbell")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                if program.completedAt != nil {
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptyProgramsView: View {
    let onCreateTap: () -> Void
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(settings.accentColor.color.opacity(0.5))
            
            Text("No Programs Yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            
            Text("Create a structured training program\nto track your progress over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateTap) {
                Text("Create Your First Program")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(settings.accentColor.color)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
    }
}

#Preview {
    ProgramsView()
        .modelContainer(for: [Program.self, WorkoutTemplate.self], inMemory: true)
}