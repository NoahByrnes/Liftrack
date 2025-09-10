import SwiftUI
import SwiftData

struct UnifiedWorkoutHub: View {
    @Binding var showingProfile: Bool
    @Environment(\.modelContext) private var modelContext
    
    // Active workout
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    
    // Programs
    @Query(sort: \Program.createdAt, order: .reverse) 
    private var programs: [Program]
    
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @StateObject private var settings = SettingsManager.shared
    
    @State private var showingCreateProgram = false
    @State private var selectedProgram: Program? = nil
    
    var activeProgram: Program? {
        programs.first { $0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Add top padding to account for fixed header
                    Color.clear.frame(height: 90)
                    
                    // Quick Start Section - Always visible at top
                    quickStartSection
                    
                    // Active Program Card (if exists)
                    if let program = activeProgram {
                        activeProgramSection(program)
                    }
                    
                    // Programs Section
                    programsSection
                    
                    Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
                }
                .padding(.bottom)
            }
            .background(Color.clear)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateProgram) {
            CreateProgramView()
        }
        .fullScreenCover(item: $selectedProgram) { program in
            NavigationStack {
                ProgramDetailView(program: program)
            }
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .fullScreenCover(isPresented: .constant(activeSessions.first != nil && !timerManager.isMinimized)) {
            if let activeSession = activeSessions.first {
                NavigationStack {
                    ActiveWorkoutView(session: activeSession)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Everything you need to train")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // Profile button
            Button(action: { showingProfile = true }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(settings.accentColor.color)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(spacing: 12) {
            // Empty Workout Button
            Button(action: startEmptyWorkout) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Empty Workout")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Build your workout as you go")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [settings.accentColor.color, settings.accentColor.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Active Program Section
    private func activeProgramSection(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACTIVE PROGRAM")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            if let nextWorkout = program.nextScheduledWorkout,
               let template = nextWorkout.template {
                HStack(spacing: 16) {
                    // Left side - Program info (tap to view details)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(program.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text("Week \(nextWorkout.week?.weekNumber ?? 1), Day \(nextWorkout.dayNumber)")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                        Text(template.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProgram = program
                    }
                    
                    // Right side - Play button (tap to start workout)
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                    }
                    .frame(width: 60, height: 60)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startProgramWorkout(template: template, program: program, workout: nextWorkout)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Programs Section
    private var programsSection: some View {
        VStack(spacing: 16) {
            // Header with create button
            HStack {
                Text("Programs")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: { showingCreateProgram = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .padding(.horizontal)
            
            if programs.isEmpty {
                UnifiedEmptyProgramsView {
                    showingCreateProgram = true
                }
                .padding(.horizontal)
            } else {
                ForEach(programs) { program in
                    ProgramRow(program: program)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture {
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
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
    }
    
    private func startWorkout(with template: WorkoutTemplate) {
        let session = WorkoutSession()
        session.templateId = template.id
        session.templateName = template.name
        
        // Copy exercises from template
        let sortedExercises = template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        for (index, workoutExercise) in sortedExercises.enumerated() {
            let sessionExercise = SessionExercise(
                exercise: workoutExercise.exercise,
                orderIndex: index,
                customRestSeconds: workoutExercise.customRestSeconds
            )
            
            // Copy sets
            if !workoutExercise.templateSets.isEmpty {
                for templateSet in workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let set = WorkoutSet(
                        setNumber: templateSet.setNumber,
                        weight: templateSet.weight,
                        reps: templateSet.reps
                    )
                    sessionExercise.sets.append(set)
                }
            }
            
            session.exercises.append(sessionExercise)
        }
        
        template.lastUsedAt = Date()
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        timerManager.updateWorkoutName(template.name)
        settings.impactFeedback(style: .medium)
    }
    
    private func startProgramWorkout(template: WorkoutTemplate, program: Program, workout: ProgramWorkout) {
        let session = WorkoutSession()
        session.templateId = template.id
        session.templateName = template.name
        session.programId = program.id
        session.programName = program.name
        session.programWeek = workout.week?.weekNumber
        session.programDay = workout.dayNumber
        
        // Copy exercises from template
        let sortedExercises = template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        for (index, workoutExercise) in sortedExercises.enumerated() {
            let sessionExercise = SessionExercise(
                exercise: workoutExercise.exercise,
                orderIndex: index,
                customRestSeconds: workoutExercise.customRestSeconds
            )
            
            // Copy sets
            if !workoutExercise.templateSets.isEmpty {
                for templateSet in workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let set = WorkoutSet(
                        setNumber: templateSet.setNumber,
                        weight: templateSet.weight,
                        reps: templateSet.reps
                    )
                    sessionExercise.sets.append(set)
                }
            }
            
            session.exercises.append(sessionExercise)
        }
        
        // Mark workout as started (ProgramWorkout doesn't have completedAt)
        template.lastUsedAt = Date()
        
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        timerManager.updateWorkoutName("\(program.name): \(template.name)")
        settings.impactFeedback(style: .medium)
    }
}

// MARK: - Supporting Views
struct TemplateQuickCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 11))
                    Text("\(template.exercises.count) exercises")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 140)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TemplateRow: View {
    let template: WorkoutTemplate
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Label("\(template.exercises.count) exercises", systemImage: "dumbbell")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if let lastUsed = template.lastUsedAt {
                        Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ProgramRow: View {
    let program: Program
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(program.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if program.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 12) {
                    Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if program.isActive {
                        Label("Week \(program.currentWeek)", systemImage: "checkmark.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

struct UnifiedEmptyTemplatesView: View {
    let onCreateTap: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(SettingsManager.shared.accentColor.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 36))
                    .foregroundColor(SettingsManager.shared.accentColor.color)
                    .rotationEffect(.degrees(animate ? 5 : -5))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
            
            VStack(spacing: 8) {
                Text("Your Templates Library")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Save your favorite workouts\nand reuse them anytime")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreateTap) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create First Template")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [SettingsManager.shared.accentColor.color, SettingsManager.shared.accentColor.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: SettingsManager.shared.accentColor.color.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .onAppear { animate = true }
    }
}

struct UnifiedEmptyProgramsView: View {
    let onCreateTap: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(animate ? 5 : -5))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
            
            VStack(spacing: 8) {
                Text("Structured Training")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Create multi-week programs\nwith progressive overload")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreateTap) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                    Text("Build Your Program")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .onAppear { animate = true }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    UnifiedWorkoutHub(showingProfile: .constant(false))
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self, Program.self], inMemory: true)
}
