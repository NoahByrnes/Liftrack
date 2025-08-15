import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var showingCreateExercise = false
    @State private var selectedExercises: Set<Exercise> = []
    let onSelect: (Exercise) -> Void
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
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
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button(action: { 
                        if selectedExercises.contains(exercise) {
                            selectedExercises.remove(exercise)
                        } else {
                            selectedExercises.insert(exercise)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .foregroundColor(.primary)
                                Text("Rest: \(formatRestTime(exercise.defaultRestSeconds))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: selectedExercises.contains(exercise) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedExercises.contains(exercise) ? .purple : .secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedExercises.isEmpty {
                        Button("Create New") {
                            showingCreateExercise = true
                        }
                        .foregroundColor(.purple)
                    } else {
                        Button("Add (\(selectedExercises.count))") {
                            for exercise in selectedExercises {
                                onSelect(exercise)
                            }
                            dismiss()
                        }
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseView { newExercise in
                    onSelect(newExercise)
                    dismiss()
                }
            }
        }
    }
}

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName = ""
    @State private var restMinutes = 1
    @State private var restSeconds = 30
    let onCreate: (Exercise) -> Void
    
    private let minuteRange = 0...10
    private let secondRange = 0...59
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                }
                
                Section("Default Rest Time") {
                    HStack {
                        Picker("Minutes", selection: $restMinutes) {
                            ForEach(minuteRange, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Picker("Seconds", selection: $restSeconds) {
                            ForEach(secondRange, id: \.self) { second in
                                Text("\(second) sec").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    .frame(height: 100)
                    
                    Text("This rest time will be used after each set of this exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let exercise = Exercise(name: exerciseName)
                        exercise.defaultRestSeconds = (restMinutes * 60) + restSeconds
                        modelContext.insert(exercise)
                        try? modelContext.save()
                        onCreate(exercise)
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(for: Exercise.self, inMemory: true)
}