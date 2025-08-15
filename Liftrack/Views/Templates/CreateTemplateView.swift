import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var templateName = ""
    @State private var exercises: [TempExercise] = []
    @State private var showingExercisePicker = false
    
    struct TempExercise: Identifiable {
        let id = UUID()
        let exercise: Exercise
        var sets: Int = 3
        var reps: Int = 10
        var weight: Double = 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("Enter template name", text: $templateName)
                }
                
                Section("Exercises") {
                    ForEach(exercises) { tempExercise in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tempExercise.exercise.name)
                                .font(.headline)
                            
                            HStack {
                                Label("\(tempExercise.sets) sets", systemImage: "number")
                                    .font(.caption)
                                Spacer()
                                Label("\(tempExercise.reps) reps", systemImage: "repeat")
                                    .font(.caption)
                                if tempExercise.weight > 0 {
                                    Label("\(Int(tempExercise.weight)) lbs", systemImage: "scalemass")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteExercise)
                    .onMove(perform: moveExercise)
                    
                    Button(action: { showingExercisePicker = true }) {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty || exercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    exercises.append(TempExercise(exercise: exercise))
                    showingExercisePicker = false
                }
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveTemplate() {
        let template = WorkoutTemplate(name: templateName)
        
        for (index, tempExercise) in exercises.enumerated() {
            let workoutExercise = WorkoutExercise(
                exercise: tempExercise.exercise,
                orderIndex: index,
                targetSets: tempExercise.sets,
                targetReps: tempExercise.reps,
                targetWeight: tempExercise.weight
            )
            template.exercises.append(workoutExercise)
        }
        
        modelContext.insert(template)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CreateTemplateView()
        .modelContainer(for: [WorkoutTemplate.self, Exercise.self], inMemory: true)
}