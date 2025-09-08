import SwiftUI
import SwiftData

struct EditTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: WorkoutTemplate
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var exercises: [TempExercise] = []
    @State private var showingExercisePicker = false
    @StateObject private var settings = SettingsManager.shared
    
    struct TempExercise: Identifiable {
        let id = UUID()
        let exercise: Exercise
        var sets: [TempSet] = []
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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Invisible background for keyboard dismissal
                        Color.clear
                            .frame(height: 0)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        
                        VStack(spacing: 24) {
                            templateInfoSection
                            exercisesSection
                        }
                        .padding()
                        .padding(.bottom, DesignConstants.Spacing.tabBarClearance)
                    }
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $showingExercisePicker, content: exercisePickerSheet)
            .onAppear {
                loadTemplateData()
            }
        }
    }
    
    private func loadTemplateData() {
        templateName = template.name
        templateDescription = template.templateDescription
        
        // Convert template exercises to temp exercises
        exercises = template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).map { workoutExercise in
            var tempExercise = TempExercise(
                exercise: workoutExercise.exercise,
                customRestSeconds: workoutExercise.customRestSeconds
            )
            
            // Load template sets if available, otherwise use defaults
            if !workoutExercise.templateSets.isEmpty {
                tempExercise.sets = workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }).map { templateSet in
                    TempSet(reps: templateSet.reps, weight: templateSet.weight)
                }
            } else {
                // Fall back to target values
                for _ in 0..<workoutExercise.targetSets {
                    tempExercise.sets.append(TempSet(
                        reps: workoutExercise.targetReps,
                        weight: workoutExercise.targetWeight ?? 0
                    ))
                }
            }
            
            return tempExercise
        }
    }
    
    private var templateInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Template Name
            VStack(alignment: .leading, spacing: 8) {
                Text("TEMPLATE NAME")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Enter template name", text: $templateName)
                    .font(.system(size: 17))
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("DESCRIPTION")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Add a description (optional)", text: $templateDescription, axis: .vertical)
                    .font(.system(size: 17))
                    .padding()
                    .lineLimit(2...4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
            }
        }
    }
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISES")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            exercisesList
            addExerciseButton
        }
    }
    
    private var exercisesList: some View {
        VStack(spacing: 20) {
            ForEach(exercises, id: \.id) { exercise in
                if let exerciseIndex = exercises.firstIndex(where: { $0.id == exercise.id }) {
                    ExerciseRow(
                        exercise: exercise,
                        exerciseIndex: exerciseIndex,
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                    exercises.remove(at: index)
                                }
                            }
                        },
                        onRestChange: { seconds in
                            if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                exercises[index].customRestSeconds = seconds
                            }
                        },
                        exercises: $exercises
                    )
                }
            }
        }
    }
    
    private var addExerciseButton: some View {
        Button(action: { showingExercisePicker = true }) {
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
    }
    
    private var saveButton: some View {
        Button("Save") { saveTemplate() }
            .disabled(templateName.isEmpty || exercises.isEmpty)
    }
    
    private func exercisePickerSheet() -> some View {
        ExercisePickerView { exercise in
            let newTempExercise = TempExercise(exercise: exercise, sets: [TempSet(), TempSet(), TempSet()])
            exercises.append(newTempExercise)
            showingExercisePicker = false
        }
    }
    
    private func saveTemplate() {
        // Update the existing template
        template.name = templateName
        template.templateDescription = templateDescription
        
        // Clear existing exercises
        template.exercises.removeAll()
        
        // Add updated exercises
        for (index, tempExercise) in exercises.enumerated() {
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
            
            // Save individual set data
            for (setIndex, tempSet) in tempExercise.sets.enumerated() {
                let templateSet = TemplateSet(
                    setNumber: setIndex + 1,
                    reps: tempSet.reps,
                    weight: tempSet.weight
                )
                workoutExercise.templateSets.append(templateSet)
            }
            
            template.exercises.append(workoutExercise)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    // Reuse the ExerciseRow component
    struct ExerciseRow: View {
        let exercise: TempExercise
        let exerciseIndex: Int
        let onDelete: () -> Void
        let onRestChange: (Int?) -> Void
        @Binding var exercises: [TempExercise]
        @StateObject private var settings = SettingsManager.shared
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise Header
                HStack {
                    Text(exercise.exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: DesignConstants.Icons.delete)
                        .font(.system(size: 20))
                        .foregroundColor(DesignConstants.Colors.deleteRed())
                        .contentShape(Circle())
                        .onTapGesture {
                            settings.impactFeedback(style: .medium)
                            onDelete()
                        }
                }
                
                // Rest Timer
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Rest: \(formatRestTime(exercise.restSeconds))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Sets
                SetsEditor(
                    exerciseId: exercise.id,
                    exercises: $exercises
                )
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
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
    }
    
    // Reuse the SetsEditor component
    struct SetsEditor: View {
        let exerciseId: UUID
        @Binding var exercises: [TempExercise]
        @StateObject private var settings = SettingsManager.shared
        @State private var isProcessingAction = false
        
        var body: some View {
            if let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseId }) {
                VStack(spacing: 8) {
                    // Sets Header
                    HStack {
                        Text("Set")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)
                        
                        Spacer()
                        
                        Text("Reps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 60)
                        
                        Text("Weight")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 80)
                        
                        Color.clear
                            .frame(width: 30)
                    }
                    .padding(.horizontal, 8)
                    
                    // Set Rows
                    ForEach(exercises[exerciseIndex].sets, id: \.id) { set in
                        SetRow(
                            set: set,
                            setNumber: (exercises[exerciseIndex].sets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1,
                            canDelete: exercises[exerciseIndex].sets.count > 1,
                            onRepsChange: { newValue in
                                if let idx = exercises.firstIndex(where: { $0.id == exerciseId }),
                                   let setIdx = exercises[idx].sets.firstIndex(where: { $0.id == set.id }) {
                                    exercises[idx].sets[setIdx].reps = newValue
                                }
                            },
                            onWeightChange: { newValue in
                                if let idx = exercises.firstIndex(where: { $0.id == exerciseId }),
                                   let setIdx = exercises[idx].sets.firstIndex(where: { $0.id == set.id }) {
                                    exercises[idx].sets[setIdx].weight = newValue
                                }
                            },
                            onDelete: {
                                if let idx = exercises.firstIndex(where: { $0.id == exerciseId }),
                                   let setIdx = exercises[idx].sets.firstIndex(where: { $0.id == set.id }) {
                                    guard !isProcessingAction else { return }
                                    isProcessingAction = true
                                    exercises[idx].sets.remove(at: setIdx)
                                    isProcessingAction = false
                                }
                            }
                        )
                    }
                    
                    // Add Set Button
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
                        if let idx = exercises.firstIndex(where: { $0.id == exerciseId }) {
                            exercises[idx].sets.append(TempSet())
                        }
                        isProcessingAction = false
                    }
                    .padding(.top, 4)
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(10)
            }
        }
    }
    
    // Reuse the SetRow component
    struct SetRow: View {
        let set: TempSet
        let setNumber: Int
        let canDelete: Bool
        let onRepsChange: (Int) -> Void
        let onWeightChange: (Double) -> Void
        let onDelete: () -> Void
        
        @State private var reps: Int
        @State private var weight: Double
        
        init(set: TempSet, setNumber: Int, canDelete: Bool,
             onRepsChange: @escaping (Int) -> Void,
             onWeightChange: @escaping (Double) -> Void,
             onDelete: @escaping () -> Void) {
            self.set = set
            self.setNumber = setNumber
            self.canDelete = canDelete
            self.onRepsChange = onRepsChange
            self.onWeightChange = onWeightChange
            self.onDelete = onDelete
            self._reps = State(initialValue: set.reps)
            self._weight = State(initialValue: set.weight)
        }
        
        var body: some View {
            HStack(spacing: 8) {
                Text("\(setNumber)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
                    .padding(.leading, 8)
                
                Spacer()
                
                // Reps Field
                HStack(spacing: 2) {
                    TextField("10", value: $reps, format: .number)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .frame(width: 40)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .keyboardType(.numberPad)
                        .onChange(of: reps) { _, newValue in
                            onRepsChange(newValue)
                        }
                }
                .frame(width: 60)
                
                // Weight Field
                HStack(spacing: 4) {
                    TextField("0", value: $weight, format: .number)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .keyboardType(.decimalPad)
                        .onChange(of: weight) { _, newValue in
                            onWeightChange(newValue)
                        }
                    
                    Text("lbs")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
                
                // Delete Button
                if canDelete {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.6))
                        .frame(width: 30)
                        .contentShape(Circle())
                        .onTapGesture {
                            SettingsManager.shared.impactFeedback(style: .light)
                            onDelete()
                        }
                } else {
                    Color.clear
                        .frame(width: 30)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    EditTemplateView(template: WorkoutTemplate(name: "Sample"))
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}