import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
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
                        ExerciseCard(
                            exercise: exercise,
                            onSetComplete: {
                                if !hasStartedWorkout {
                                    hasStartedWorkout = true
                                    startWorkoutTimer()
                                }
                                startRestTimer(seconds: exercise.restSeconds)
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
                    .background(Color(.secondarySystemGroupedBackground))
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
        timer?.invalidate()
        restTimer?.invalidate()
        
        session.completedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error finishing workout: \(error)")
        }
        
        dismiss()
    }
    
    private func cancelWorkout() {
        timer?.invalidate()
        restTimer?.invalidate()
        
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
    @State private var expandedSets = true
    @State private var offset: CGFloat = 0
    @State private var showDeleteConfirm = false
    @Environment(\.modelContext) private var modelContext
    
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
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                Button(action: {
                    if showDeleteConfirm {
                        withAnimation(.spring()) {
                            onDelete()
                        }
                    } else {
                        withAnimation(.spring()) {
                            showDeleteConfirm = true
                        }
                        // Reset after 3 seconds if not confirmed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showDeleteConfirm = false
                                offset = 0
                            }
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: showDeleteConfirm ? "trash.fill" : "trash")
                            .font(.system(size: 20))
                        Text(showDeleteConfirm ? "Confirm" : "Delete")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(showDeleteConfirm ? Color.red : Color.orange)
                }
            }
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exerciseName)
                            .font(.headline)
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                            Text("Rest: \(formatRestTime(exercise.restSeconds))")
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
                            SwipeableSetRow(
                                set: set,
                                onComplete: onSetComplete,
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
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < -20 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -50 {
                                offset = -80
                            } else {
                                offset = 0
                                showDeleteConfirm = false
                            }
                        }
                    }
            )
        }
    }
}

struct SwipeableSetRow: View {
    let set: WorkoutSet
    let onComplete: () -> Void
    let onDelete: () -> Void
    @State private var weight = ""
    @State private var reps = ""
    @State private var offset: CGFloat = 0
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack {
            // Delete background
            HStack {
                Spacer()
                
                Button(action: {
                    if showDeleteConfirm {
                        withAnimation(.spring()) {
                            onDelete()
                        }
                    } else {
                        withAnimation(.spring()) {
                            showDeleteConfirm = true
                        }
                        // Reset after 2 seconds if not confirmed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showDeleteConfirm = false
                                offset = 0
                            }
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showDeleteConfirm ? "trash.fill" : "trash")
                            .font(.system(size: 14))
                        Text(showDeleteConfirm ? "Confirm" : "Delete")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                    .background(showDeleteConfirm ? Color.red : Color.orange)
                    .cornerRadius(8)
                }
            }
            
            // Main content
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
            .padding(.vertical, 4)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < -20 {
                            offset = max(value.translation.width, -70)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -40 {
                                offset = -70
                            } else {
                                offset = 0
                                showDeleteConfirm = false
                            }
                        }
                    }
            )
        }
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