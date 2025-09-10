import SwiftUI
import SwiftData

struct WorkoutHubView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    
    // Active workout
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    
    // Templates
    @Query(sort: \WorkoutTemplate.name) 
    private var templates: [WorkoutTemplate]
    
    // Programs
    @Query(sort: \Program.createdAt, order: .reverse) 
    private var programs: [Program]
    
    @State private var showingCreateTemplate = false
    @State private var showingCreateProgram = false
    @State private var showingActiveWorkout = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var selectedProgram: Program?
    
    var activeProgram: Program? {
        programs.first { $0.isActive }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Active workout card (if exists)
                if let activeSession = activeSessions.first {
                    ActiveWorkoutCard(session: activeSession) {
                        showingActiveWorkout = true
                    }
                }
                
                // Quick Start Section
                quickStartSection
                
                // Active Program (if exists)
                if let program = activeProgram {
                    activeProgramSection(program)
                }
                
                // Templates Section
                templatesSection
                
                // Programs Section  
                programsSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView()
        }
        .sheet(isPresented: $showingCreateProgram) {
            ProgramCreationRouter()
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
        .sheet(item: $selectedProgram) { program in
            ProgramDetailView(program: program)
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let session = activeSessions.first {
                ActiveWorkoutView(session: session)
            }
        }
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // Empty workout button
                Button(action: startEmptyWorkout) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                        Text("Empty Workout")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Template quick access
                if let recentTemplate = templates.first {
                    Button(action: { startWorkoutFromTemplate(recentTemplate) }) {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 32))
                            Text(recentTemplate.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(settings.accentColor.color.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Active Program Section
    private func activeProgramSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Program")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(program.currentWeek) of \(program.durationWeeks)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { selectedProgram = program }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("\(program.durationWeeks) weeks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 3)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(program.currentWeek) / CGFloat(program.durationWeeks))
                            .stroke(settings.accentColor.color, lineWidth: 3)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((CGFloat(program.currentWeek) / CGFloat(program.durationWeeks)) * 100))%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Templates")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingCreateTemplate = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            
            if templates.isEmpty {
                Text("No templates yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(templates) { template in
                            WorkoutTemplateCard(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Programs Section
    private var programsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Programs")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingCreateProgram = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            
            if programs.filter({ !$0.isActive }).isEmpty {
                Text("No programs yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(programs.filter { !$0.isActive }) { program in
                    WorkoutProgramRow(program: program) {
                        selectedProgram = program
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func startEmptyWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)
        try? modelContext.save()
        // Start timer for session
        timerManager.startWorkoutTimer()
        showingActiveWorkout = true
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let session = WorkoutSession()
        session.templateId = template.id
        // Copy exercises from template
        for (index, templateExercise) in template.exercises.enumerated() {
            let sessionExercise = SessionExercise(exercise: templateExercise.exercise, orderIndex: index)
            for setNumber in 1...templateExercise.targetSets {
                let set = WorkoutSet(setNumber: setNumber)
                sessionExercise.sets.append(set)
            }
            session.exercises.append(sessionExercise)
        }
        modelContext.insert(session)
        try? modelContext.save()
        // Start timer for session
        timerManager.startWorkoutTimer()
        showingActiveWorkout = true
    }
}

// MARK: - Helpers

private func formatTime(_ interval: TimeInterval) -> String {
    let minutes = Int(interval) / 60
    let seconds = Int(interval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// MARK: - Supporting Views

private struct ActiveWorkoutCard: View {
    let session: WorkoutSession
    let action: () -> Void
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Workout in Progress")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("In Progress")
                        .font(.subheadline)
                        .foregroundColor(SettingsManager.shared.accentColor.color)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(SettingsManager.shared.accentColor.color)
            }
            .padding()
            .background(SettingsManager.shared.accentColor.color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(template.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 140)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct WorkoutProgramRow: View {
    let program: Program
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(program.durationWeeks) weeks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WorkoutHubView()
        .modelContainer(for: [
            WorkoutSession.self,
            WorkoutTemplate.self,
            Program.self
        ], inMemory: true)
}