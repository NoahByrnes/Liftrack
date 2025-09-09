//
//  ContentView.swift
//  Liftrack
//
//  Created by Noah Grant-Byrnes on 2025-08-14.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = SettingsManager.shared
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
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
    
    var lastWorkout: WorkoutSession? { recentSessions.first }
    
    var body: some View {
        ZStack {
            if isLoading {
                // Enhanced loading view with animation
                ZStack {
                    // Match the main gradient exactly
                    if #available(iOS 18.0, *) {
                        TimelineView(.animation) { context in
                            let time = context.date.timeIntervalSince1970
                            let offsetX = Float(sin(time)) * 0.1
                            let offsetY = Float(cos(time)) * 0.1
                            
                            MeshGradient(
                                width: 4,
                                height: 4,
                                points: [
                                    [0.0, 0.0],
                                    [0.3, 0.0],
                                    [0.7, 0.0],
                                    [1.0, 0.0],
                                    [0.0, 0.3],
                                    [0.2 + offsetX, 0.4 + offsetY],
                                    [0.7 + offsetX, 0.2 + offsetY],
                                    [1.0, 0.3],
                                    [0.0, 0.7],
                                    [0.3 + offsetX, 0.8],
                                    [0.7 + offsetX, 0.6],
                                    [1.0, 0.7],
                                    [0.0, 1.0],
                                    [0.3, 1.0],
                                    [0.7, 1.0],
                                    [1.0, 1.0]
                                ],
                                colors: [
                                    .black, .black.opacity(0.9), .black.opacity(0.8), .black,
                                    .black.opacity(0.7), .purple.opacity(0.8), .indigo.opacity(0.7), .black.opacity(0.6),
                                    .purple.opacity(0.6), .pink.opacity(0.7), .orange.opacity(0.6), .purple.opacity(0.5),
                                    .orange.opacity(0.7), .yellow.opacity(0.6), .pink.opacity(0.7), .purple.opacity(0.8)
                                ],
                                smoothsColors: true
                            )
                            .ignoresSafeArea()
                        }
                    } else {
                        LinearGradient(
                            colors: [
                                .purple,
                                .pink,
                                .orange,
                                .yellow
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    }
                    
                    // Animated noise overlay for loading screen
                    if #available(iOS 18.0, *) {
                        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                            GeometryReader { geometry in
                                Canvas { context, size in
                                    let time = timeline.date.timeIntervalSince1970
                                    
                                    for i in 0..<8000 {
                                        let baseX = Double((i * 2654435761) % Int(size.width))
                                        let baseY = Double((i * 1597334677) % Int(size.height))
                                        let flowX = sin(time * 0.3 + Double(i) * 0.001) * 5
                                        let flowY = cos(time * 0.2 + Double(i) * 0.001) * 3
                                        let x = (baseX + flowX).truncatingRemainder(dividingBy: size.width)
                                        let y = (baseY + flowY).truncatingRemainder(dividingBy: size.height)
                                        let baseOpacity = 0.1 + (Double(i % 100) / 100.0) * 0.15
                                        let opacity = baseOpacity + sin(time * 2 + Double(i) * 0.01) * 0.05
                                        let particleSize = 0.3 + (Double(i % 10) / 10.0) * 1.7
                                        
                                        context.fill(
                                            Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                            with: .color(.white.opacity(opacity))
                                        )
                                    }
                                }
                                .allowsHitTesting(false)
                                .blendMode(.overlay)
                            }
                            .ignoresSafeArea()
                        }
                    } else {
                        GeometryReader { geometry in
                            Canvas { context, size in
                                for _ in 0..<8000 {
                                    let x = Double.random(in: 0...size.width)
                                    let y = Double.random(in: 0...size.height)
                                    let opacity = Double.random(in: 0.1...0.25)
                                    let particleSize = Double.random(in: 0.3...2.0)
                                    
                                    context.fill(
                                        Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                        with: .color(.white.opacity(opacity))
                                    )
                                }
                            }
                            .allowsHitTesting(false)
                            .blendMode(.overlay)
                        }
                        .ignoresSafeArea()
                    }
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 3)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .trim(from: 0, to: 0.3)
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
                // Minimal single-page design
                NavigationStack {
                    ZStack {
                        // Layer 1: Animated gradient background
                        if #available(iOS 18.0, *) {
                            TimelineView(.animation) { context in
                                let time = context.date.timeIntervalSince1970
                                let offsetX = Float(sin(time)) * 0.1
                                let offsetY = Float(cos(time)) * 0.1
                                
                                MeshGradient(
                                    width: 4,
                                    height: 4,
                                    points: [
                                        [0.0, 0.0],
                                        [0.3, 0.0],
                                        [0.7, 0.0],
                                        [1.0, 0.0],
                                        [0.0, 0.3],
                                        [0.2 + offsetX, 0.4 + offsetY],
                                        [0.7 + offsetX, 0.2 + offsetY],
                                        [1.0, 0.3],
                                        [0.0, 0.7],
                                        [0.3 + offsetX, 0.8],
                                        [0.7 + offsetX, 0.6],
                                        [1.0, 0.7],
                                        [0.0, 1.0],
                                        [0.3, 1.0],
                                        [0.7, 1.0],
                                        [1.0, 1.0]
                                    ],
                                    colors: [
                                        .black, .black.opacity(0.9), .black.opacity(0.8), .black,
                                        .black.opacity(0.7), .purple.opacity(0.8), .indigo.opacity(0.7), .black.opacity(0.6),
                                        .purple.opacity(0.6), .pink.opacity(0.7), .orange.opacity(0.6), .purple.opacity(0.5),
                                        .orange.opacity(0.7), .yellow.opacity(0.6), .pink.opacity(0.7), .purple.opacity(0.8)
                                    ],
                                    smoothsColors: true
                                )
                                .ignoresSafeArea()
                            }
                        } else {
                            // Fallback for iOS 17 and earlier
                            LinearGradient(
                                colors: [
                                    .purple,
                                    .pink,
                                    .orange,
                                    .yellow
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()
                        }
                        
                        // Layer 2: Animated flowing grain effect
                        if #available(iOS 18.0, *) {
                            TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                                GeometryReader { geometry in
                                    Canvas { context, size in
                                        let time = timeline.date.timeIntervalSince1970
                                        
                                        for i in 0..<8000 {
                                            let baseX = Double((i * 2654435761) % Int(size.width))
                                            let baseY = Double((i * 1597334677) % Int(size.height))
                                            let flowX = sin(time * 0.3 + Double(i) * 0.001) * 5
                                            let flowY = cos(time * 0.2 + Double(i) * 0.001) * 3
                                            let x = (baseX + flowX).truncatingRemainder(dividingBy: size.width)
                                            let y = (baseY + flowY).truncatingRemainder(dividingBy: size.height)
                                            let baseOpacity = 0.1 + (Double(i % 100) / 100.0) * 0.15
                                            let opacity = baseOpacity + sin(time * 2 + Double(i) * 0.01) * 0.05
                                            let particleSize = 0.3 + (Double(i % 10) / 10.0) * 1.7
                                            
                                            context.fill(
                                                Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                                with: .color(.white.opacity(opacity))
                                            )
                                        }
                                    }
                                    .allowsHitTesting(false)
                                    .blendMode(.overlay)
                                }
                                .ignoresSafeArea()
                            }
                        } else {
                            GeometryReader { geometry in
                                Canvas { context, size in
                                    for _ in 0..<8000 {
                                        let x = Double.random(in: 0...size.width)
                                        let y = Double.random(in: 0...size.height)
                                        let opacity = Double.random(in: 0.1...0.25)
                                        let particleSize = Double.random(in: 0.3...2.0)
                                        
                                        context.fill(
                                            Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                            with: .color(.white.opacity(opacity))
                                        )
                                    }
                                }
                                .allowsHitTesting(false)
                                .blendMode(.overlay)
                            }
                            .ignoresSafeArea()
                        }
                        
                        // Layer 3: UI Components (above gradient and noise)
                        ZStack {
                            // Profile button positioned absolutely at top right
                            VStack {
                                HStack {
                                    Spacer()
                                    NavigationLink(destination: ProfileView()) {
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
                                    }
                                    .padding(.trailing, 20)
                                    .padding(.top, 50)
                                }
                                Spacer()
                            }
                            
                            // Three buttons truly centered
                            HStack(spacing: 16) {
                                // Repeat last workout button
                                Button(action: {
                                    if let last = lastWorkout {
                                        repeatWorkout(last)
                                    }
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                        
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 26, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .opacity(lastWorkout == nil ? 0.4 : 1.0)
                                .disabled(lastWorkout == nil)
                                
                                // Start new workout button (primary)
                                Button(action: startEmptyWorkout) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.thinMaterial)
                                            .frame(width: 140, height: 80)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                            )
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24, weight: .semibold))
                                            Text("Workout")
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                    }
                                }
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                // Templates button
                                Button(action: { showingTemplatePicker = true }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                        
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 26, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
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
                    .navigationBarHidden(true)
                    .sheet(isPresented: $showingTemplatePicker) {
                        SimpleTemplatePickerSheet(onSelect: startWorkoutFromTemplate)
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
        }
        .preferredColorScheme(.dark) // Keep dark mode for better contrast
        .tint(.white) // White tint for controls
        .onAppear {
            guard !hasInitialized else { return }
            hasInitialized = true
            
            // Check if we have an active workout and should skip loading screen
            let hasActiveSession = !activeSessions.isEmpty
            shouldShowLoadingScreen = !hasActiveSession
            
            // If we have an active workout, skip loading
            if hasActiveSession {
                isLoading = false
            } else {
                // Perform initial setup with loading screen
                Task {
                    // Seed data in background
                    await MainActor.run {
                        DataSeeder.seedExercisesIfNeeded(context: modelContext)
                    }
                    
                    // Load settings
                    _ = settings.accentColor
                    _ = settings.appearanceMode
                    
                    // Only show loading screen if no active workout
                    if shouldShowLoadingScreen {
                        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    }
                    
                    // Fade out launch screen
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isLoading = false
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
        
        // Copy exercises and sets
        for exercise in original.exercises {
            // Find the exercise object
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
        session.templateId = template.id
        session.templateName = template.name
        
        // Copy from template
        for workoutExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: workoutExercise.exercise,
                orderIndex: workoutExercise.orderIndex
            )
            
            for templateSet in workoutExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                let set = WorkoutSet(
                    setNumber: templateSet.setNumber,
                    weight: templateSet.weight,
                    reps: templateSet.reps
                )
                sessionExercise.sets.append(set)
            }
            
            session.exercises.append(sessionExercise)
        }
        
        template.lastUsedAt = Date()
        modelContext.insert(session)
        timerManager.startWorkoutTimer()
        settings.impactFeedback(style: .medium)
    }
}

// MARK: - Template Picker Sheet (simplified)
private struct SimpleTemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            if templates.isEmpty {
                VStack {
                    Spacer()
                    Text("No templates yet")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .navigationTitle("Templates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
            } else {
                List(templates) { template in
                    Button(action: {
                        onSelect(template)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("\(template.exercises.count) exercises")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Templates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self,
            WorkoutTemplate.self,
            WorkoutSession.self
        ], inMemory: true)
}
