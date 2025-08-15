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
        var sets: [TempSet] = [TempSet(), TempSet(), TempSet()]
        var customRestSeconds: Int? = nil
        
        var restSeconds: Int {
            customRestSeconds ?? exercise.defaultRestSeconds
        }
    }
    
    struct TempSet: Identifiable {
        let id = UUID()
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
                    ForEach($exercises) { $tempExercise in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tempExercise.exercise.name)
                                        .font(.system(size: 17, weight: .semibold))
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 11))
                                        Text("Rest: \(formatRestTime(tempExercise.restSeconds))")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Menu {
                                    Button("Add Set") {
                                        tempExercise.sets.append(TempSet())
                                    }
                                    if tempExercise.sets.count > 1 {
                                        Button("Remove Last Set", role: .destructive) {
                                            tempExercise.sets.removeLast()
                                        }
                                    }
                                    Divider()
                                    Menu("Rest Time: \(formatRestTime(tempExercise.restSeconds))") {
                                        Button("30 seconds") {
                                            tempExercise.customRestSeconds = 30
                                        }
                                        Button("45 seconds") {
                                            tempExercise.customRestSeconds = 45
                                        }
                                        Button("1 minute") {
                                            tempExercise.customRestSeconds = 60
                                        }
                                        Button("1m 30s") {
                                            tempExercise.customRestSeconds = 90
                                        }
                                        Button("2 minutes") {
                                            tempExercise.customRestSeconds = 120
                                        }
                                        Button("2m 30s") {
                                            tempExercise.customRestSeconds = 150
                                        }
                                        Button("3 minutes") {
                                            tempExercise.customRestSeconds = 180
                                        }
                                        Button("4 minutes") {
                                            tempExercise.customRestSeconds = 240
                                        }
                                        Button("5 minutes") {
                                            tempExercise.customRestSeconds = 300
                                        }
                                        Divider()
                                        Button("Use Default (\(formatRestTime(tempExercise.exercise.defaultRestSeconds)))") {
                                            tempExercise.customRestSeconds = nil
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                }
                            }
                            
                            VStack(spacing: 10) {
                                ForEach(Array(tempExercise.sets.enumerated()), id: \.element.id) { index, _ in
                                    HStack(spacing: 12) {
                                        Text("Set \(index + 1)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .frame(width: 50, alignment: .leading)
                                        
                                        TextField("10", value: .init(
                                            get: { tempExercise.sets[index].reps },
                                            set: { tempExercise.sets[index].reps = max(1, min(100, $0)) }
                                        ), format: .number)
                                        .font(.system(size: 16))
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        
                                        Text("reps")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("Weight:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        
                                        TextField("0", value: .init(
                                            get: { tempExercise.sets[index].weight },
                                            set: { tempExercise.sets[index].weight = max(0, $0) }
                                        ), format: .number)
                                        .font(.system(size: 16))
                                        .multilineTextAlignment(.center)
                                        .frame(width: 65)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        
                                        Text("lbs")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteExercise)
                    .onMove(perform: moveExercise)
                    
                    Button(action: { showingExercisePicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add Exercise")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
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
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveTemplate() {
        let template = WorkoutTemplate(name: templateName)
        
        for (index, tempExercise) in exercises.enumerated() {
            // Use the first set's values as defaults, or average them
            let avgReps = tempExercise.sets.isEmpty ? 10 : 
                Int(tempExercise.sets.map { $0.reps }.reduce(0, +) / tempExercise.sets.count)
            let avgWeight = tempExercise.sets.isEmpty ? 0 : 
                tempExercise.sets.map { $0.weight }.reduce(0, +) / Double(tempExercise.sets.count)
            
            let workoutExercise = WorkoutExercise(
                exercise: tempExercise.exercise,
                orderIndex: index,
                targetSets: tempExercise.sets.count,
                targetReps: avgReps,
                targetWeight: avgWeight,
                customRestSeconds: tempExercise.customRestSeconds
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