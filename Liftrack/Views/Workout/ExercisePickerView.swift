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
                            Text(exercise.name)
                                .foregroundColor(.primary)
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
    let onCreate: (Exercise) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise Name", text: $exerciseName)
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