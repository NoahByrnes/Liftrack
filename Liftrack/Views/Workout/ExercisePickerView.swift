import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
            Group {
                if exercises.isEmpty {
                    // Empty state - no exercises in database
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No Exercises Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Create a new exercise or restore default exercises")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                showingCreateExercise = true
                            }) {
                                Label("Create New Exercise", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [settings.accentColor.color.opacity(0.8), settings.accentColor.color.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(settings.accentColor.color.opacity(0.2))
                                            )
                                    )
                            }
                            
                            Button(action: {
                                reseedExercises()
                            }) {
                                Label("Restore Default Exercises", systemImage: "arrow.clockwise")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(.ultraThinMaterial.opacity(0.3))
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(filteredExercises) { exercise in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Rest: \(formatRestTime(exercise.defaultRestSeconds))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    
                                    // Show selection indicator with soft design
                                    if let index = selectedExercises.firstIndex(of: exercise) {
                                        HStack(spacing: 8) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(
                                                    Circle()
                                                        .fill(settings.accentColor.color.opacity(0.8))
                                                )
                                            
                                            Circle()
                                                .strokeBorder(settings.accentColor.color, lineWidth: 2)
                                                .background(
                                                    Circle()
                                                        .fill(settings.accentColor.color)
                                                )
                                                .frame(width: 22, height: 22)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    } else {
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                            .frame(width: 22, height: 22)
                                            .background(
                                                Circle()
                                                    .fill(Color.white.opacity(0.05))
                                            )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: selectedExercises.contains(exercise) ?
                                                    [settings.accentColor.color.opacity(0.3), settings.accentColor.color.opacity(0.1)] :
                                                    [.white.opacity(0.15), .white.opacity(0.05)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial.opacity(0.3))
                                        )
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let index = selectedExercises.firstIndex(of: exercise) {
                                        selectedExercises.remove(at: index)
                                    } else {
                                        selectedExercises.append(exercise)
                                    }
                                    settings.impactFeedback(style: .light)
                                }
                            }
                        }
                        .padding()
                    }
                    .searchable(text: $searchText, prompt: "Search exercises")
                }
            }
            .navigationTitle("Exercises")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
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
        }
        .sheet(isPresented: $showingCreateExercise) {
            CreateExerciseView { newExercise in
                onSelect(newExercise)
                dismiss()
            }
        }
    }
    
    private func reseedExercises() {
        // Clear the UserDefaults flag to allow re-seeding
        UserDefaults.standard.set(false, forKey: "HasSeededInitialExercises")
        
        // Call the seeder
        DataSeeder.seedExercisesIfNeeded(context: modelContext)
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