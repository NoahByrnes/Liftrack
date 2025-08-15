import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var showingAddExercise = false
    @State private var showingRestTimer = false
    @State private var restSeconds = 90
    @State private var showingCancelAlert = false
    @State private var hasStartedWorkout = false
    @State private var currentRestTime = 0
    @State private var restTimer: Timer?
    @State private var showRestBar = false
    @State private var restTimeRemaining = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer Header
            HStack {
                Button(action: { showingCancelAlert = true }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text(formatTime(elapsedTime))
                        .font(.system(.title3, design: .monospaced))
                }
                
                Spacer()
                
                Button("Finish") {
                    finishWorkout()
                }
                .foregroundColor(.purple)
                .fontWeight(.semibold)
            }
            .padding()
            .background(Color(.systemGray6))
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                        ExerciseCard(exercise: exercise, onSetComplete: {
                            if !hasStartedWorkout {
                                hasStartedWorkout = true
                                startWorkoutTimer()
                            }
                            startRestTimer(seconds: exercise.exercise.defaultRestSeconds)
                        })
                    }
                    
                    Button(action: { showingAddExercise = true }) {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            
            // Rest timer bar
            if showRestBar {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.purple)
                        
                        Text("Rest: \(formatRestTime(restTimeRemaining))")
                            .font(.system(.body, design: .monospaced))
                        
                        Spacer()
                        
                        // Quick time adjustment buttons
                        Button(action: { 
                            restTimeRemaining = max(0, restTimeRemaining - 15)
                        }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.purple)
                        }
                        
                        Button(action: { 
                            restTimeRemaining += 15
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.purple)
                        }
                        
                        Button(action: { 
                            showingRestTimer = true 
                        }) {
                            Text("Expand")
                                .font(.footnote)
                                .foregroundColor(.purple)
                        }
                        
                        Button(action: { 
                            endRestTimer()
                        }) {
                            Text("Skip")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
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
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(isPresented: $showingRestTimer) {
            ExpandedRestTimerView(
                remainingTime: $restTimeRemaining,
                isRunning: showRestBar,
                onDismiss: {
                    showingRestTimer = false
                },
                onStop: {
                    endRestTimer()
                    showingRestTimer = false
                }
            )
        }
    }
    
    private func startWorkoutTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func startRestTimer(seconds: Int? = nil) {
        restTimeRemaining = seconds ?? restSeconds
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestBar = true
        }
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                endRestTimer()
            }
        }
    }
    
    private func endRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestBar = false
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
        session.completedAt = Date()
        timer?.invalidate()
        restTimer?.invalidate()
        try? modelContext.save()
        dismiss()
    }
    
    private func cancelWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()
        // Delete the session without saving completion
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
    
    private func addExercise(_ exercise: Exercise) {
        let newIndex = (session.exercises.map { $0.orderIndex }.max() ?? -1) + 1
        let sessionExercise = SessionExercise(exercise: exercise, orderIndex: newIndex)
        
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
    @State private var expandedSets = true
    
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                        Text("Rest: \(formatRestTime(exercise.exercise.defaultRestSeconds))")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { expandedSets.toggle() }) {
                    Image(systemName: expandedSets ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if expandedSets {
                VStack(spacing: 8) {
                    HStack {
                        Text("Set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)
                        Text("Previous")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        Text("lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60)
                        Text("Reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60)
                        Text("")
                            .frame(width: 30)
                    }
                    
                    ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                        SetRow(set: set, onComplete: onSetComplete)
                    }
                    
                    Button(action: {
                        let newSetNumber = (exercise.sets.map { $0.setNumber }.max() ?? 0) + 1
                        let newSet = WorkoutSet(setNumber: newSetNumber)
                        exercise.sets.append(newSet)
                    }) {
                        Label("Add Set", systemImage: "plus")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SetRow: View {
    let set: WorkoutSet
    let onComplete: () -> Void
    @State private var weight = ""
    @State private var reps = ""
    
    var body: some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Text("-")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            TextField("0", text: $weight)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .onChange(of: weight) { newValue in
                    if let value = Double(newValue) {
                        set.weight = value
                    }
                }
            
            TextField("0", text: $reps)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .frame(width: 60)
                .onChange(of: reps) { newValue in
                    if let value = Int(newValue) {
                        set.reps = value
                    }
                }
            
            Button(action: {
                set.toggleCompleted()
                if set.isCompleted {
                    onComplete()
                }
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.isCompleted ? .green : .secondary)
            }
            .frame(width: 30)
        }
        .onAppear {
            weight = set.weight > 0 ? "\(Int(set.weight))" : ""
            reps = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

#Preview {
    ActiveWorkoutView(session: WorkoutSession())
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}