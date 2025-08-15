import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var showingAddExercise = false
    @State private var showingRestTimer = false
    @State private var restSeconds = 90
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer Header
            HStack {
                Image(systemName: "timer")
                Text(formatTime(elapsedTime))
                    .font(.system(.title3, design: .monospaced))
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
                            showingRestTimer = true
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
            
            // Bottom tools
            HStack(spacing: 20) {
                Button(action: { showingRestTimer = true }) {
                    Label("Rest Timer", systemImage: "timer")
                        .font(.footnote)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
                showingAddExercise = false
            }
        }
        .sheet(isPresented: $showingRestTimer) {
            RestTimerView(seconds: $restSeconds)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
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
        try? modelContext.save()
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
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