import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var showingCreateExercise = false
    @State private var selectedExercises: [Exercise] = [] // Changed to Array to preserve order
    @StateObject private var settings = SettingsManager.shared
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
                        if let index = selectedExercises.firstIndex(of: exercise) {
                            selectedExercises.remove(at: index)
                        } else {
                            selectedExercises.append(exercise)
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
                            
                            // Show order number if selected
                            if let index = selectedExercises.firstIndex(of: exercise) {
                                HStack(spacing: 4) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(settings.accentColor.color)
                                        .clipShape(Circle())
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(settings.accentColor.color)
                                }
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if selectedExercises.isEmpty {
                        Button("Create New") {
                            showingCreateExercise = true
                        }
                        .foregroundColor(settings.accentColor.color)
                    } else {
                        Button("Add (\(selectedExercises.count))") {
                            // Pass exercises in the order they were selected
                            for exercise in selectedExercises {
                                onSelect(exercise)
                            }
                            dismiss()
                        }
                        .foregroundColor(settings.accentColor.color)
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
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #else
                        .pickerStyle(.menu)
                        #endif
                        .frame(width: 100)
                        
                        Picker("Seconds", selection: $restSeconds) {
                            ForEach(secondRange, id: \.self) { second in
                                Text("\(second) sec").tag(second)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #else
                        .pickerStyle(.menu)
                        #endif
                        .frame(width: 100)
                    }
                    .frame(height: 100)
                    
                    Text("This rest time will be used after each set of this exercise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Exercise")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
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