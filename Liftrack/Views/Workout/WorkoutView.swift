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
                let sessionExercise = SessionExercise(
                    exercise: workoutExercise.exercise, 
                    orderIndex: index,
                    customRestSeconds: workoutExercise.customRestSeconds
                )
                
                // Use individual set data if available, otherwise fall back to averages
                if !workoutExercise.templateSets.isEmpty {
                    for templateSet in workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                        let set = WorkoutSet(
                            setNumber: templateSet.setNumber,
                            weight: templateSet.weight,
                            reps: templateSet.reps
                        )
                        sessionExercise.sets.append(set)
                    }
                } else {
                    // Fallback for old templates without individual set data
                    for setNumber in 1...workoutExercise.targetSets {
                        let set = WorkoutSet(
                            setNumber: setNumber,
                            weight: workoutExercise.targetWeight ?? 0,
                            reps: workoutExercise.targetReps
                        )
                        sessionExercise.sets.append(set)
                    }
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
    @State private var animateGradient = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header - Match Templates/History style
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Ready to train?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Start Empty Workout Button
                Button(action: { 
                    onTemplateSelect(nil)
                    SettingsManager.shared.impactFeedback(style: .medium)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick Start")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Begin an empty workout")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [settings.accentColor.color, settings.accentColor.color.opacity(0.8)],
                            startPoint: animateGradient ? .topLeading : .bottomLeading,
                            endPoint: animateGradient ? .bottomTrailing : .topTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: settings.accentColor.color.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                // Recent Templates
                if !templates.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Templates")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                            Spacer()
                            NavigationLink(destination: TemplatesView()) {
                                Text("See All")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(templates.prefix(3)) { template in
                            QuickTemplateCard(template: template) {
                                onTemplateSelect(template)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct QuickTemplateCard: View {
    let template: WorkoutTemplate
    let action: () -> Void
    @State private var isPressed = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Button(action: {
            action()
            SettingsManager.shared.impactFeedback(style: .light)
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(settings.accentColor.color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 22))
                        .foregroundColor(settings.accentColor.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(template.exercises.count)", systemImage: "dumbbell")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if let lastUsed = template.lastUsedAt {
                            Text(lastUsed.formatted(.relative(presentation: .named)))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(settings.accentColor.color.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self], inMemory: true)
}