import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = WorkoutTimerManager.shared
    @State private var showingAddExercise = false
    @State private var showingRestTimer = false
    @State private var showingCancelAlert = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Timer Header
                HStack {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                        .contentShape(Circle())
                        .onTapGesture {
                            showingCancelAlert = true
                        }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text(formatTime(timerManager.elapsedTime))
                            .font(.system(.title3, design: .monospaced))
                    }
                    
                    Spacer()
                    
                    Text("Finish")
                        .foregroundColor(settings.accentColor.color)
                        .fontWeight(.semibold)
                        .onTapGesture {
                            finishWorkout()
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .onTapGesture {
                    // Dismiss keyboard when tapping header
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Invisible background for keyboard dismissal
                        Color.clear
                            .frame(height: 0)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        
                        ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                            ExerciseCard(
                                exercise: exercise,
                                onSetComplete: {
                                    // Dismiss keyboard when completing a set
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    if !timerManager.isRunning {
                                        timerManager.startWorkoutTimer()
                                    }
                                    timerManager.startRestTimer(seconds: exercise.restSeconds)
                                },
                                onDelete: {
                                    withAnimation {
                                        session.exercises.removeAll { $0.id == exercise.id }
                                        // Renumber remaining exercises
                                        let sortedExercises = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                                        for (index, remainingExercise) in sortedExercises.enumerated() {
                                            remainingExercise.orderIndex = index
                                        }
                                        try? modelContext.save()
                                    }
                                }
                            )
                            .padding(.vertical, 8)
                        }
                        
                        // Add Exercise Button - Match CreateTemplateView style
                        Button(action: {
                            showingAddExercise = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add Exercise")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundColor(settings.accentColor.color)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(settings.accentColor.color.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Add padding at bottom to account for tab bar and rest timer
                        Color.clear.frame(height: timerManager.showRestBar ? 180 : DesignConstants.Spacing.tabBarClearance)
                    }
                    .padding(.vertical)
                }
            }
            
            // Rest timer bar - positioned as floating element above tab bar
            if timerManager.showRestBar {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(settings.accentColor.color)
                            
                            Text("Rest: \(formatRestTime(timerManager.restTimeRemaining))")
                                .font(.system(.body, design: .monospaced))
                            
                            Spacer()
                            
                            // Quick time adjustment buttons
                            Image(systemName: "minus.circle")
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    timerManager.adjustRestTime(by: -15)
                                }
                            
                            Image(systemName: "plus.circle")
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    timerManager.adjustRestTime(by: 15)
                                }
                            
                            Text("Expand")
                                .font(.footnote)
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    showingRestTimer = true
                                }
                            
                            Text("Skip")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    timerManager.endRestTimer()
                                }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Position above tab bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(isPresented: $showingRestTimer) {
            ExpandedRestTimerView(
                remainingTime: $timerManager.restTimeRemaining,
                isRunning: timerManager.showRestBar,
                onDismiss: {
                    showingRestTimer = false
                },
                onStop: {
                    timerManager.endRestTimer()
                    showingRestTimer = false
                }
            )
        }
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
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
        let sessionExercise = SessionExercise(
            exercise: exercise, 
            orderIndex: newIndex,
            customRestSeconds: nil  // Use default from exercise
        )
        
        for i in 1...3 {
            let set = WorkoutSet(setNumber: i)
            sessionExercise.sets.append(set)
        }
        
        session.exercises.append(sessionExercise)
        try? modelContext.save()
    }
}

struct ExerciseCard: View {
    let exercise: SessionExercise
    let onSetComplete: () -> Void
    let onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @State private var isProcessingAction = false
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 {
            return "\(mins)m \(secs)s"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(secs)s"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header - Match CreateTemplateView style
            HStack {
                Text(exercise.exerciseName)
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Image(systemName: DesignConstants.Icons.delete)
                    .font(.system(size: 20))
                    .foregroundColor(DesignConstants.Colors.deleteRed())
                    .contentShape(Circle())
                    .onTapGesture {
                        SettingsManager.shared.impactFeedback(style: .medium)
                        onDelete()
                    }
            }
            
            // Rest Timer - Match CreateTemplateView style
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("Rest: \(formatRestTime(exercise.restSeconds))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Sets Section - Match CreateTemplateView style
            VStack(spacing: 8) {
                // Sets Header
                HStack {
                    Text("Set")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    
                    Text("Previous")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    
                    Text("lbs")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 70)
                    
                    Text("Reps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 60)
                    
                    Color.clear
                        .frame(width: 44)
                }
                .padding(.horizontal, 8)
                
                // Set Rows
                ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    WorkoutSetRow(
                        set: set,
                        onComplete: onSetComplete,
                        canDelete: exercise.sets.count > 1,
                        onDelete: {
                            withAnimation {
                                exercise.sets.removeAll { $0.id == set.id }
                                // Renumber remaining sets
                                let sortedSets = exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })
                                for (index, remainingSet) in sortedSets.enumerated() {
                                    remainingSet.setNumber = index + 1
                                }
                                try? modelContext.save()
                            }
                        }
                    )
                }
                
                // Add Set Button - Match CreateTemplateView style
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Set")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(settings.accentColor.color.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isProcessingAction else { return }
                    isProcessingAction = true
                    let newSetNumber = (exercise.sets.map { $0.setNumber }.max() ?? 0) + 1
                    let newSet = WorkoutSet(setNumber: newSetNumber)
                    exercise.sets.append(newSet)
                    try? modelContext.save()
                    isProcessingAction = false
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

struct WorkoutSetRow: View {
    let set: WorkoutSet
    let onComplete: () -> Void
    let canDelete: Bool
    let onDelete: () -> Void
    
    @State private var weight = ""
    @State private var reps = ""
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
                .padding(.leading, 8)
            
            Text("-")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            // Weight Field
            TextField("0", text: $weight)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .keyboardType(.decimalPad)
                .onChange(of: weight) { _, newValue in
                    if let value = Double(newValue) {
                        set.weight = value
                    }
                }
            
            Text("lbs")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Reps Field
            TextField("0", text: $reps)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .keyboardType(.numberPad)
                .onChange(of: reps) { _, newValue in
                    if let value = Int(newValue) {
                        set.reps = value
                    }
                }
            
            // Complete/Delete Button
            if canDelete {
                Menu {
                    Button(action: {
                        set.toggleCompleted()
                        if set.isCompleted {
                            onComplete()
                        }
                    }) {
                        Label(set.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                              systemImage: set.isCompleted ? "circle" : "checkmark.circle")
                    }
                    
                    Button(role: .destructive, action: {
                        SettingsManager.shared.impactFeedback(style: .medium)
                        onDelete()
                    }) {
                        Label("Delete Set", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: set.isCompleted ? DesignConstants.Icons.check : DesignConstants.Icons.uncheck)
                        .font(.system(size: 22))
                        .foregroundColor(set.isCompleted ? DesignConstants.Colors.completedGreen() : .secondary)
                        .frame(width: 44)
                        .contentShape(Circle())
                }
            } else {
                Image(systemName: set.isCompleted ? DesignConstants.Icons.check : DesignConstants.Icons.uncheck)
                    .font(.system(size: 22))
                    .foregroundColor(set.isCompleted ? DesignConstants.Colors.completedGreen() : .secondary)
                    .frame(width: 44)
                    .contentShape(Circle())
                    .onTapGesture {
                        set.toggleCompleted()
                        if set.isCompleted {
                            onComplete()
                        }
                    }
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            weight = set.weight > 0 ? "\(Int(set.weight))" : ""
            reps = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let session = WorkoutSession()
    container.mainContext.insert(session)
    
    return ActiveWorkoutView(session: session)
        .modelContainer(container)
}