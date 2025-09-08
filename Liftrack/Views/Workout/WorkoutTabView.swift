import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Active workout
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    
    // Recent completed workouts
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.completedAt,
        order: .reverse
    ) private var recentSessions: [WorkoutSession]
    
    // All exercises for lookup
    @Query private var exercises: [Exercise]
    
    // Templates for quick access
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    
    // Active program
    @Query(filter: #Predicate<Program> { $0.isActive })
    private var activePrograms: [Program]
    
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var showingTemplatePicker = false
    @State private var showingProgramPicker = false
    
    var activeProgram: Program? { activePrograms.first }
    var hasActiveWorkout: Bool { !activeSessions.isEmpty }
    var lastWorkout: WorkoutSession? { recentSessions.first }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top padding for header
                Color.clear.frame(height: 40)
                
                // Smart Start Section - Changes based on context
                smartStartSection
                    .padding(.horizontal)
                
                // Recent Activity - Compact list
                if !recentSessions.isEmpty {
                    recentActivitySection
                        .padding(.horizontal)
                }
                
                // Quick Access Templates (optional, hidden if no templates)
                if !templates.isEmpty && !hasActiveWorkout {
                    quickTemplatesSection
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerSheet(onSelect: startWorkoutFromTemplate)
        }
        .fullScreenCover(isPresented: .constant(hasActiveWorkout && !timerManager.isMinimized)) {
            if let session = activeSessions.first {
                NavigationStack {
                    ActiveWorkoutView(session: session)
                }
            }
        }
    }
    
    // MARK: - Smart Start Section
    @State private var showActiveWorkout = false
    @State private var showProgramWorkout = false
    
    @ViewBuilder
    private var smartStartSection: some View {
        HStack(spacing: 12) {
            // Repeat button (left) - fixed height container
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray5))
                    .frame(width: showActiveWorkout || showProgramWorkout ? 0 : 70, height: 56)
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: showActiveWorkout || showProgramWorkout ? 0 : 70, height: 56)
            .onTapGesture {
                if let last = lastWorkout {
                    repeatWorkout(last)
                }
            }
            .opacity(showActiveWorkout || showProgramWorkout ? 0 : (lastWorkout == nil ? 0.3 : 1.0))
            .allowsHitTesting(lastWorkout != nil && !showActiveWorkout && !showProgramWorkout)
            .scaleEffect(showActiveWorkout || showProgramWorkout ? 0.5 : 1.0)
            
            // Center button that morphs between states
            Group {
                if let activeSession = activeSessions.first {
                    // Active workout state
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(settings.accentColor.color)
                            .frame(height: 56)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Resume Workout")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(formatWorkoutTime(timerManager.elapsedTime))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .onTapGesture {
                        timerManager.isMinimized = false
                    }
                    .transition(.identity)
                }
                else if let program = activeProgram,
                        let nextWorkout = program.nextScheduledWorkout,
                        let template = nextWorkout.template {
                    // Program workout state
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green)
                            .frame(height: 56)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.play")
                                .font(.system(size: 22))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Today: \(template.name)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .lineLimit(1)
                                Text("\(program.name)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .onTapGesture {
                        startProgramWorkout(template: template, program: program, workout: nextWorkout)
                    }
                    .transition(.identity)
                }
                else {
                    // Default state
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(settings.accentColor.color)
                            .frame(height: 56)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Start Workout")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .onTapGesture {
                        startEmptyWorkout()
                    }
                    .transition(.identity)
                }
            }
            
            // Templates button (right) - fixed height container
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray5))
                    .frame(width: showActiveWorkout || showProgramWorkout ? 0 : 70, height: 56)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: showActiveWorkout || showProgramWorkout ? 0 : 70, height: 56)
            .onTapGesture {
                showingTemplatePicker = true
            }
            .opacity(showActiveWorkout || showProgramWorkout ? 0 : 1.0)
            .allowsHitTesting(!showActiveWorkout && !showProgramWorkout)
            .scaleEffect(showActiveWorkout || showProgramWorkout ? 0.5 : 1.0)
        }
        .onAppear {
            updateButtonStates()
        }
        .onChange(of: activeSessions.first?.id) { _, _ in
            updateButtonStates()
        }
        .onChange(of: activeProgram?.id) { _, _ in
            updateButtonStates()
        }
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.8), value: showActiveWorkout)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.8), value: showProgramWorkout)
    }
    
    private func updateButtonStates() {
        withAnimation {
            showActiveWorkout = !activeSessions.isEmpty
            showProgramWorkout = activeSessions.isEmpty && activeProgram?.nextScheduledWorkout != nil
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 8) {
                ForEach(recentSessions.prefix(3)) { session in
                    CompactWorkoutRow(session: session) {
                        repeatWorkout(session)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Templates Section
    private var quickTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick Start")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button("See All") {
                    showingTemplatePicker = true
                }
                .font(.system(size: 13))
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(templates.prefix(5)) { template in
                        WorkoutTemplateChip(template: template) {
                            startWorkoutFromTemplate(template)
                        }
                    }
                }
                .padding(.horizontal)
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
    
    private func repeatWorkout(_ original: WorkoutSession) {
        let session = WorkoutSession()
        session.templateName = original.templateName
        
        // Copy exercises and sets
        for exercise in original.exercises {
            // Find the exercise object
            let exerciseData = exercises.first { $0.id == exercise.exerciseId } ?? Exercise(name: exercise.exerciseName)
            let newExercise = SessionExercise(
                exercise: exerciseData,
                orderIndex: exercise.orderIndex
            )
            
            for set in exercise.sets {
                let newSet = WorkoutSet(
                    setNumber: set.setNumber,
                    weight: set.weight,
                    reps: set.reps
                )
                newExercise.sets.append(newSet)
            }
            
            session.exercises.append(newExercise)
        }
        
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let session = WorkoutSession()
        session.templateId = template.id
        session.templateName = template.name
        
        // Copy from template
        for workoutExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: workoutExercise.exercise,
                orderIndex: workoutExercise.orderIndex
            )
            
            for templateSet in workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                let set = WorkoutSet(
                    setNumber: templateSet.setNumber,
                    weight: templateSet.weight,
                    reps: templateSet.reps
                )
                sessionExercise.sets.append(set)
            }
            
            session.exercises.append(sessionExercise)
        }
        
        template.lastUsedAt = Date()
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
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
        
        // Copy from template (same as above)
        for workoutExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: workoutExercise.exercise,
                orderIndex: workoutExercise.orderIndex
            )
            
            for templateSet in workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                let set = WorkoutSet(
                    setNumber: templateSet.setNumber,
                    weight: templateSet.weight,
                    reps: templateSet.reps
                )
                sessionExercise.sets.append(set)
            }
            
            session.exercises.append(sessionExercise)
        }
        
        template.lastUsedAt = Date()
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
    }
}

// MARK: - Compact Component Views

struct CompactWorkoutRow: View {
    let session: WorkoutSession
    let onRepeat: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.templateName ?? "Workout")
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let date = session.completedAt {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("\(session.exercises.count) exercises")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if let duration = session.duration {
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(formatDuration(duration))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onRepeat) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct WorkoutTemplateChip: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text("\(template.exercises.count) exercises")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button(action: {
                    onSelect(template)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(template.name)
                                .font(.system(size: 16, weight: .medium))
                            Text("\(template.exercises.count) exercises")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Helper Functions
private func formatWorkoutTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    WorkoutTabView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self, Program.self], inMemory: true)
}