import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
    
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    
    @State private var showingAddExercise = false
    @State private var showingCancelAlert = false
    @State private var showingEmptyWorkoutAlert = false
    @State private var appearAnimation = false
    @State private var headerScale = 0.9
    @State private var isEditMode = false
    @State private var showingFinishConfirmation = false
    @State private var heroAnimationPhase = 0
    
    // Template-related properties
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse) private var templates: [WorkoutTemplate]
    
    private var recentTemplates: [WorkoutTemplate] {
        Array(templates.prefix(5))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WorkoutHeader(
                session: session,
                isEditMode: $isEditMode,
                showingFinishConfirmation: $showingFinishConfirmation,
                showingEmptyWorkoutAlert: $showingEmptyWorkoutAlert,
                heroAnimationPhase: heroAnimationPhase,
                onMinimize: {
                    if session.exercises.isEmpty {
                        cancelWorkout()
                    } else {
                        withAnimation {
                            timerManager.isMinimized = true
                            dismiss()
                        }
                    }
                }
            )
            
            ExercisesList(
                session: session,
                isEditMode: $isEditMode,
                showingAddExercise: $showingAddExercise,
                appearAnimation: $appearAnimation,
                recentTemplates: recentTemplates,
                onLoadTemplate: loadTemplate
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appearAnimation = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                headerScale = 1.0
            }
            
            // Hero animation sequence
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                heroAnimationPhase = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                heroAnimationPhase = 2
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? All progress will be lost.")
        }
        .alert("Empty Workout", isPresented: $showingEmptyWorkoutAlert) {
            Button("Add Exercises") {
                showingAddExercise = true
            }
            Button("Cancel Workout", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("You haven't added any exercises yet. Would you like to add some or cancel the workout?")
        }
        .confirmationDialog("Finish Workout", isPresented: $showingFinishConfirmation) {
            Button("Finish Workout") {
                finishWorkout()
            }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("Are you ready to finish this workout?")
        }
        .background(Color.black)
    }
    
    // MARK: - Helper Functions
    
    private func finishWorkout() {
        timerManager.cleanup()
        session.completedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error finishing workout: \(error)")
        }
        
        dismiss()
    }
    
    private func cancelWorkout() {
        timerManager.cleanup()
        
        // Clear all relationships first to avoid SwiftData crash
        session.exercises.removeAll()
        
        // Delete the session
        modelContext.delete(session)
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error canceling workout: \(error)")
        }
        
        dismiss()
    }
    
    private func addExercise(_ exercise: Exercise) {
        let newIndex = (session.exercises.map { $0.orderIndex }.max() ?? -1) + 1
        let defaultRest = UserDefaults.standard.integer(forKey: "defaultRestTime")
        let sessionExercise = SessionExercise(
            exercise: exercise,
            orderIndex: newIndex,
            customRestSeconds: defaultRest > 0 ? defaultRest : 90
        )
        
        for i in 1...3 {
            let set = WorkoutSet(setNumber: i)
            sessionExercise.sets.append(set)
        }
        
        session.exercises.append(sessionExercise)
        try? modelContext.save()
    }
    
    private func loadTemplate(_ template: WorkoutTemplate) {
        // Load exercises from template
        for templateExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: templateExercise.exercise,
                orderIndex: templateExercise.orderIndex,
                customRestSeconds: templateExercise.customRestSeconds
            )
            sessionExercise.supersetGroupId = templateExercise.supersetGroupId
            
            // Create sets based on template configuration
            if !templateExercise.templateSets.isEmpty {
                for templateSet in templateExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let set = WorkoutSet(setNumber: templateSet.setNumber)
                    set.reps = templateSet.reps
                    set.weight = templateSet.weight
                    sessionExercise.sets.append(set)
                }
            } else {
                for i in 1...templateExercise.targetSets {
                    let set = WorkoutSet(setNumber: i)
                    set.reps = templateExercise.targetReps
                    set.weight = templateExercise.targetWeight ?? 0
                    sessionExercise.sets.append(set)
                }
            }
            
            session.exercises.append(sessionExercise)
        }
        
        // Update template's last used date
        template.lastUsedAt = Date()
        
        // Save changes
        try? modelContext.save()
        
        // Provide feedback
        settings.impactFeedback(style: .medium)
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: WorkoutSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let session = WorkoutSession()
        container.mainContext.insert(session)
        
        return ActiveWorkoutView(session: session)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview")
    }
}