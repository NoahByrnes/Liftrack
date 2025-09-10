import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @Query(
        filter: #Predicate<WorkoutSession> { session in
            session.completedAt == nil
        }
    ) private var activeSessions: [WorkoutSession]
    @Query(
        filter: #Predicate<WorkoutSession> { session in
            session.completedAt != nil
        },
        sort: \WorkoutSession.completedAt, 
        order: .reverse
    ) private var recentSessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    @Query private var exercises: [Exercise]
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @State private var isLoading = true
    @State private var hasInitialized = false
    @State private var shouldShowLoadingScreen = true
    @State private var showingTemplatePicker = false
    @State private var showingProfile = false
    @State private var profileButtonScale = 1.0
    @State private var workoutButtonScale = 1.0
    @State private var templateButtonScale = 1.0
    @State private var repeatButtonScale = 1.0
    @State private var buttonsAppeared = false
    
    var lastWorkout: WorkoutSession? { recentSessions.first }
    
    var body: some View {
        Group {
            if isLoading {
                // Loading screen with gradient
                ZStack {
                    GradientBackground()
                    
                    VStack(spacing: 32) {
                        ZStack {
                            Circle()
                                .trim(from: 0, to: 0.8)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                            
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Liftrack")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Loading your workout data...")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .transition(.opacity)
            } else {
                // Main app with persistent gradient background
                NavigationStack {
                    ZStack {
                        // Persistent gradient background at root level
                        GradientBackground()
                            .ignoresSafeArea()
                        
                        // Content layer
                        ZStack {
                            // Profile button positioned absolutely at top right
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                        
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .scaleEffect(profileButtonScale)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            profileButtonScale = 0.9
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                profileButtonScale = 1.0
                                            }
                                            showingProfile = true
                                        }
                                        settings.impactFeedback(style: .light)
                                    }
                                    .padding(.trailing, 20)
                                    .padding(.top, 50)
                                }
                                Spacer()
                            }
                            
                            // Main content area
                            VStack(spacing: 40) {
                                // App title
                                Text("Liftrack")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.top, 100)
                                
                                Spacer()
                                
                                // Three buttons in center
                                HStack(spacing: 20) {
                                    // Repeat last workout button - circular ghost style with animation
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                        .frame(width: 65, height: 65)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial.opacity(0.3))
                                        )
                                        .overlay(
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                        )
                                        .scaleEffect(repeatButtonScale)
                                        .opacity(buttonsAppeared ? (lastWorkout == nil ? 0.3 : 1.0) : 0)
                                        .offset(y: buttonsAppeared ? 0 : 50)
                                        .rotation3DEffect(
                                            .degrees(buttonsAppeared ? 0 : -90),
                                            axis: (x: 1, y: 0, z: 0)
                                        )
                                        .onTapGesture {
                                            guard lastWorkout != nil else { return }
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                repeatButtonScale = 0.85
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    repeatButtonScale = 1.0
                                                }
                                                if let last = lastWorkout {
                                                    repeatWorkout(last)
                                                }
                                            }
                                            settings.impactFeedback(style: .medium)
                                        }
                                        .disabled(lastWorkout == nil)
                                    
                                    // Start new workout button - larger pill with gradient border and hero animation
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.5),
                                                    .purple.opacity(0.3),
                                                    .pink.opacity(0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: 160, height: 65)
                                        .background(
                                            Capsule()
                                                .fill(.ultraThinMaterial.opacity(0.5))
                                        )
                                        .overlay(
                                            HStack(spacing: 8) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 20, weight: .semibold))
                                                Text("Workout")
                                                    .font(.system(size: 17, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                        )
                                        .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                                        .scaleEffect(workoutButtonScale)
                                        .opacity(buttonsAppeared ? 1 : 0)
                                        .offset(y: buttonsAppeared ? 0 : 100)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                                workoutButtonScale = 0.9
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                                    workoutButtonScale = 1.1
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                        workoutButtonScale = 1.0
                                                    }
                                                    startEmptyWorkout()
                                                }
                                            }
                                            settings.impactFeedback(style: .medium)
                                        }
                                    
                                    // Templates button - circular ghost style with animation
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                        .frame(width: 65, height: 65)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial.opacity(0.3))
                                        )
                                        .overlay(
                                            Image(systemName: "doc.text")
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                        )
                                        .scaleEffect(templateButtonScale)
                                        .opacity(buttonsAppeared ? 1 : 0)
                                        .offset(y: buttonsAppeared ? 0 : 50)
                                        .rotation3DEffect(
                                            .degrees(buttonsAppeared ? 0 : 90),
                                            axis: (x: 1, y: 0, z: 0)
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                templateButtonScale = 0.85
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    templateButtonScale = 1.0
                                                }
                                                showingTemplatePicker = true
                                            }
                                            settings.impactFeedback(style: .medium)
                                        }
                                }
                                
                                Spacer()
                                Spacer()
                            }
                        }
                            
                            // Active workout overlay (if exists)
                            if let activeSession = activeSessions.first {
                                VStack {
                                    Spacer()
                                    MinimizedWorkoutBar(session: activeSession, selectedTab: .constant(0))
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                        }
                    }
                    .navigationBarHidden(true)
                    .sheet(isPresented: $showingTemplatePicker) {
                            SimpleTemplatePickerSheet(onSelect: startWorkoutFromTemplate)
                                .presentationBackground(.ultraThinMaterial)
                    }
                    .sheet(isPresented: $showingProfile) {
                            NavigationStack {
                                ProfileView()
                            }
                            .presentationBackground(.ultraThinMaterial.opacity(0.95))
                    }
                    .fullScreenCover(isPresented: .constant(!activeSessions.isEmpty && !timerManager.isMinimized)) {
                            if let session = activeSessions.first {
                                NavigationStack {
                                    ActiveWorkoutView(session: session)
                                }
                            }
                    }
                }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .onAppear {
            guard !hasInitialized else { return }
            hasInitialized = true
            
            let hasActiveSession = !activeSessions.isEmpty
            shouldShowLoadingScreen = !hasActiveSession
            
            if hasActiveSession {
                isLoading = false
                buttonsAppeared = true
            } else {
                Task {
                    await MainActor.run {
                        DataSeeder.seedExercisesIfNeeded(context: modelContext)
                    }
                    
                    _ = settings.accentColor
                    _ = settings.appearanceMode
                    
                    if shouldShowLoadingScreen {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                    }
                    
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isLoading = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                buttonsAppeared = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func startEmptyWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
    }
    
    private func repeatWorkout(_ original: WorkoutSession) {
        let session = WorkoutSession()
        session.templateName = original.templateName
        
        for exercise in original.exercises {
            let exerciseData = exercises.first { $0.id == exercise.exerciseId } ?? Exercise(name: exercise.exerciseName)
            let newExercise = SessionExercise(
                exercise: exerciseData,
                orderIndex: exercise.orderIndex
            )
            
            for set in exercise.sets {
                let newSet = WorkoutSet(
                    setNumber: set.setNumber,
                    weight: set.weight,
                    reps: set.reps
                )
                newExercise.sets.append(newSet)
            }
            
            session.exercises.append(newExercise)
        }
        
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let session = WorkoutSession()
        session.templateName = template.name
        session.templateId = template.id
        
        for templateExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: templateExercise.exercise,
                orderIndex: templateExercise.orderIndex,
                customRestSeconds: templateExercise.customRestSeconds
            )
            sessionExercise.supersetGroupId = templateExercise.supersetGroupId
            
            if !templateExercise.templateSets.isEmpty {
                for templateSet in templateExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let set = WorkoutSet(setNumber: templateSet.setNumber)
                    set.reps = templateSet.reps
                    set.weight = templateSet.weight
                    sessionExercise.sets.append(set)
                }
            } else {
                for i in 1...templateExercise.targetSets {
                    let set = WorkoutSet(setNumber: i)
                    set.reps = templateExercise.targetReps
                    set.weight = templateExercise.targetWeight ?? 0
                    sessionExercise.sets.append(set)
                }
            }
            
            session.exercises.append(sessionExercise)
        }
        
        template.lastUsedAt = Date()
        
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
        
        try? modelContext.save()
    }
}

struct SimpleTemplatePickerSheet: View {
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Environment(\.dismiss) private var dismiss
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button(action: {
                    onSelect(template)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(template.exercises.count) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}