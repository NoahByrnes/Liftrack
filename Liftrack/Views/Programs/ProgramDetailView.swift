import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var showingStartWorkout = false
    @State private var selectedWorkout: ProgramWorkout?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Add padding for navigation bar
                Color.clear.frame(height: 20)
                
                // Program Overview Card
                programOverviewCard
                
                // Progress Section
                if program.isActive {
                    progressSection
                }
                
                // Action Buttons
                actionButtons
                
                // Weekly Schedule
                weeklyScheduleSection
                
                Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !program.isActive {
                        Button(action: activateProgram) {
                            Label("Activate Program", systemImage: "play.fill")
                        }
                    } else {
                        Button(action: deactivateProgram) {
                            Label("Pause Program", systemImage: "pause.fill")
                        }
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Program", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Program?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProgram()
            }
        } message: {
            Text("This will permanently delete the program and all its data.")
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            if let template = workout.template {
                StartProgramWorkoutView(
                    program: program,
                    programWorkout: workout,
                    template: template
                )
            }
        }
    }
    
    private var programOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    if !program.programDescription.isEmpty {
                        Text(program.programDescription)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Label("\(program.workoutTemplates.count) workouts/week", systemImage: "dumbbell")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Progression Info
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(settings.accentColor.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progression")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Manual adjustment")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("PROGRESS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Week \(program.currentWeek) of \(program.durationWeeks)")
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(Int(program.progressPercentage))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(settings.accentColor.color)
                            .frame(width: geometry.size.width * (program.progressPercentage / 100), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Stats Grid
            HStack(spacing: 12) {
                StatBox(
                    label: "Completed",
                    value: "\(program.completedSessions.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatBox(
                    label: "Remaining",
                    value: "\(program.programWeeks.flatMap { $0.scheduledWorkouts }.filter { !$0.isRestDay && !$0.isCompleted }.count)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                if let startDate = program.startedAt {
                    StatBox(
                        label: "Started",
                        value: startDate.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar.badge.clock",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if program.isActive {
                if let nextWorkout = program.nextScheduledWorkout,
                   nextWorkout.template != nil {
                    Button(action: { selectedWorkout = nextWorkout }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Next Workout")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(settings.accentColor.color)
                        .cornerRadius(12)
                    }
                }
            } else {
                Button(action: activateProgram) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Program")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(settings.accentColor.color)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var weeklyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WEEKLY SCHEDULE")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ForEach(program.programWeeks.sorted(by: { $0.weekNumber < $1.weekNumber }).prefix(program.currentWeek + 1)) { week in
                WeekCard(
                    week: week,
                    isCurrentWeek: week.weekNumber == program.currentWeek,
                    onWorkoutTap: { workout in
                        if !workout.isRestDay && !workout.isCompleted {
                            selectedWorkout = workout
                        }
                    }
                )
            }
        }
    }
    
    private func activateProgram() {
        // Deactivate any other active programs
        if let context = modelContext.container.mainContext as? ModelContext {
            let descriptor = FetchDescriptor<Program>(predicate: #Predicate { $0.isActive == true })
            if let activePrograms = try? context.fetch(descriptor) {
                for activeProgram in activePrograms {
                    activeProgram.isActive = false
                }
            }
        }
        
        program.isActive = true
        program.startedAt = Date()
        try? modelContext.save()
    }
    
    private func deactivateProgram() {
        program.isActive = false
        try? modelContext.save()
    }
    
    private func deleteProgram() {
        modelContext.delete(program)
        try? modelContext.save()
        dismiss()
    }
}

struct WeekCard: View {
    let week: ProgramWeek
    let isCurrentWeek: Bool
    let onWorkoutTap: (ProgramWorkout) -> Void
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(week.name)
                    .font(.system(size: 16, weight: .semibold))
                
                if isCurrentWeek {
                    Text("CURRENT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(settings.accentColor.color)
                        .cornerRadius(4)
                }
                
                if week.isDeload {
                    Text("DELOAD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if week.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Workout Days
            VStack(spacing: 8) {
                ForEach(week.scheduledWorkouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                    WorkoutDayRow(
                        workout: workout,
                        onTap: { onWorkoutTap(workout) }
                    )
                }
            }
        }
        .padding()
        .background(
            isCurrentWeek ? 
            settings.accentColor.color.opacity(0.05) : 
            Color(.secondarySystemGroupedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isCurrentWeek ? settings.accentColor.color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WorkoutDayRow: View {
    let workout: ProgramWorkout
    let onTap: () -> Void
    @StateObject private var settings = SettingsManager.shared
    
    private var dayName: String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[min(workout.dayNumber - 1, 6)]
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(dayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .leading)
                
                if workout.isRestDay {
                    Text("Rest Day")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    Text(workout.dayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(workout.isCompleted ? .secondary : .primary)
                    
                    if let template = workout.template {
                        Text("• \(template.exercises.count) exercises")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if workout.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                } else if !workout.isRestDay {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                workout.isCompleted ? Color.green.opacity(0.05) : 
                workout.isRestDay ? Color.clear : 
                Color(.tertiarySystemGroupedBackground)
            )
            .cornerRadius(8)
        }
        .disabled(workout.isRestDay || workout.isCompleted)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// Enhanced view to start a workout within a program with preview
struct StartProgramWorkoutView: View {
    let program: Program
    let programWorkout: ProgramWorkout
    let template: WorkoutTemplate
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var workoutSession: WorkoutSession?
    @State private var showingActiveWorkout = false
    @State private var isCreatingSession = false
    
    var body: some View {
        NavigationStack {
            if let session = workoutSession {
                // Show workout preview before starting
                ScrollView {
                    VStack(spacing: 20) {
                        // Program context
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(program.name)
                                    .font(.headline)
                                HStack {
                                    if let week = programWorkout.week {
                                        Label("Week \(week.weekNumber)", systemImage: "calendar")
                                            .font(.caption)
                                        if week.isDeload {
                                            Text("DELOAD")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // Workout info
                        VStack(alignment: .leading, spacing: 12) {
                            Text(template.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 24) {
                                Label("\(template.exercises.count) exercises", systemImage: "dumbbell")
                                Label("\(session.exercises.flatMap { $0.sets }.count) sets", systemImage: "number")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            if !template.templateDescription.isEmpty {
                                Text(template.templateDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // Exercise list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXERCISES")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                                HStack {
                                    Text(exercise.exerciseName)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(exercise.sets.count) sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Start button
                        Button(action: {
                            timerManager.startWorkoutTimer()
                            timerManager.updateWorkoutName(template.name)
                            showingActiveWorkout = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Workout")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(settings.accentColor.color)
                            .cornerRadius(10)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
                .navigationTitle("Start Workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            // Delete the created session
                            session.exercises.removeAll()
                            modelContext.delete(session)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                }
                .fullScreenCover(isPresented: $showingActiveWorkout) {
                    NavigationStack {
                        ActiveWorkoutView(session: session)
                            .onDisappear {
                                // Mark program workout as completed
                                if session.completedAt != nil {
                                    programWorkout.isCompleted = true
                                    programWorkout.completedSession = session
                                    program.completedSessions.append(session)
                                    
                                    // Check week completion
                                    if let week = programWorkout.week {
                                        let allComplete = week.scheduledWorkouts
                                            .filter { !$0.isRestDay }
                                            .allSatisfy { $0.isCompleted }
                                        if allComplete {
                                            week.isCompleted = true
                                            week.completedAt = Date()
                                        }
                                    }
                                    
                                    // Check program completion
                                    if program.programWeeks.allSatisfy({ $0.isCompleted }) {
                                        program.completedAt = Date()
                                        program.isActive = false
                                    }
                                    
                                    try? modelContext.save()
                                }
                                dismiss()
                            }
                    }
                }
            } else {
                ProgressView("Setting up workout...")
                    .onAppear {
                        createWorkoutSession()
                    }
            }
        }
    }
    
    private func createWorkoutSession() {
        let session = WorkoutSession()
        session.templateId = template.id
        session.templateName = "\(program.name) - \(template.name)"
        session.programId = program.id
        session.programName = program.name
        session.programWeek = programWorkout.week?.weekNumber
        session.programDay = programWorkout.dayNumber
        
        // Apply progression based on program settings
        let weightModifier = programWorkout.week?.weightModifier ?? 1.0
        
        for templateExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: templateExercise.exercise,
                orderIndex: templateExercise.orderIndex,
                customRestSeconds: templateExercise.customRestSeconds
            )
            
            // Create sets from template
            for templateSet in templateExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                let set = WorkoutSet(setNumber: templateSet.setNumber)
                
                // Apply deload modifier if applicable
                var targetWeight = templateSet.weight * weightModifier
                
                // Ensure weight doesn't go negative
                targetWeight = max(0, targetWeight)
                
                set.weight = targetWeight
                set.reps = templateSet.reps
                
                sessionExercise.sets.append(set)
            }
            
            session.exercises.append(sessionExercise)
        }
        
        modelContext.insert(session)
        try? modelContext.save()
        
        workoutSession = session
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(program: Program(name: "Sample Program"))
    }
    .modelContainer(for: [Program.self, WorkoutTemplate.self], inMemory: true)
}