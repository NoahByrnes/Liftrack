import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    @State private var showingTemplatePicker = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let activeSession = activeSessions.first {
                    ActiveWorkoutView(session: activeSession)
                } else {
                    QuickStartView(templates: templates) { template in
                        startWorkout(with: template)
                    }
                }
            }
            .navigationTitle("Workout")
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView { template in
                    startWorkout(with: template)
                    showingTemplatePicker = false
                }
            }
        }
    }
    
    private func startWorkout(with template: WorkoutTemplate?) {
        let session = WorkoutSession(template: template)
        
        if let template = template {
            for (index, workoutExercise) in template.exercises.enumerated() {
                let sessionExercise = SessionExercise(exercise: workoutExercise.exercise, orderIndex: index)
                
                for setNumber in 1...workoutExercise.targetSets {
                    let set = WorkoutSet(
                        setNumber: setNumber,
                        weight: workoutExercise.targetWeight ?? 0,
                        reps: workoutExercise.targetReps
                    )
                    sessionExercise.sets.append(set)
                }
                
                session.exercises.append(sessionExercise)
            }
            
            template.lastUsedAt = Date()
        }
        
        modelContext.insert(session)
    }
}

struct QuickStartView: View {
    let templates: [WorkoutTemplate]
    let onTemplateSelect: (WorkoutTemplate?) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Start a Workout")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                Button(action: { onTemplateSelect(nil) }) {
                    Label("Empty Workout", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                if !templates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Templates")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(templates.prefix(3)) { template in
                            Button(action: { onTemplateSelect(template) }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(template.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        if !template.exercises.isEmpty {
                                            Text("\(template.exercises.count) exercises")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self], inMemory: true)
}