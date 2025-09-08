import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse)
    private var templates: [WorkoutTemplate]
    @Query(filter: #Predicate<Program> { $0.isActive == true })
    private var activePrograms: [Program]
    @State private var showingTemplatePicker = false
    
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    
    var activeProgram: Program? {
        activePrograms.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let activeSession = activeSessions.first, !timerManager.isMinimized {
                    ActiveWorkoutView(session: activeSession)
                } else {
                    QuickStartView(
                        templates: templates,
                        activeProgram: activeProgram
                    ) { template, program, week, day in
                        startWorkout(with: template, program: program, week: week, day: day)
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView { template in
                    startWorkout(with: template, program: nil, week: nil, day: nil)
                    showingTemplatePicker = false
                }
            }
        }
    }
    
    private func startWorkout(with template: WorkoutTemplate?, program: Program? = nil, week: Int? = nil, day: Int? = nil) {
        let session = WorkoutSession()
        if let template = template {
            session.templateId = template.id
            session.templateName = template.name
        }
        if let program = program {
            session.programId = program.id
            session.programName = program.name
            session.programWeek = week
            session.programDay = day
        }
        
        if let template = template {
            // Sort exercises by orderIndex to maintain template order
            let sortedExercises = template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
            for (index, workoutExercise) in sortedExercises.enumerated() {
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
    let activeProgram: Program?
    let onTemplateSelect: (WorkoutTemplate?, Program?, Int?, Int?) -> Void
    @State private var animateGradient = false
    @State private var appearAnimation = false
    @State private var selectedCardId: UUID? = nil
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header with animation
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workout")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(0.05), value: appearAnimation)
                        
                        Text("Ready to train?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Active Program Card (if exists)
                if let program = activeProgram,
                   let nextWorkout = program.nextScheduledWorkout,
                   let template = nextWorkout.template {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVE PROGRAM")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .opacity(appearAnimation ? 1 : 0)
                            .animation(.easeOut(duration: 0.2).delay(0.15), value: appearAnimation)
                        
                        Button(action: {
                            selectedCardId = program.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedCardId = nil
                            }
                            onTemplateSelect(template, program, nextWorkout.week?.weekNumber, nextWorkout.dayNumber)
                            #if os(iOS)
                            SettingsManager.shared.impactFeedback(style: .medium)
                            #else
                            SettingsManager.shared.impactFeedback()
                            #endif
                        }) {
                            ZStack {
                                // Background gradient with animation
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(animateGradient ? 0.9 : 1.0),
                                        Color.green.opacity(animateGradient ? 0.7 : 0.8)
                                    ],
                                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                                )
                                
                                HStack(spacing: 16) {
                                    // Icon container
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "figure.run")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                            .rotationEffect(.degrees(selectedCardId == program.id ? 10 : 0))
                                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: selectedCardId)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(program.name)
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 12))
                                            Text("Week \(nextWorkout.week?.weekNumber ?? 1), Day \(nextWorkout.dayNumber)")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(.white.opacity(0.9))
                                        
                                        Text(template.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .scaleEffect(selectedCardId == program.id ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: selectedCardId)
                                }
                                .padding(20)
                            }
                            .cornerRadius(24)
                            .shadow(color: Color.green.opacity(0.4), radius: 15, x: 0, y: 8)
                            .scaleEffect(selectedCardId == program.id ? 0.98 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardId)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 30)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
                }
                
                // Start Empty Workout Button with enhanced design
                Button(action: { 
                    selectedCardId = UUID() // Trigger animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedCardId = nil
                    }
                    onTemplateSelect(nil, nil, nil, nil)
                    #if os(iOS)
                    SettingsManager.shared.impactFeedback(style: .medium)
                    #else
                    SettingsManager.shared.impactFeedback()
                    #endif
                }) {
                    ZStack {
                        // Animated background
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        settings.accentColor.color.opacity(animateGradient ? 0.9 : 1.0),
                                        settings.accentColor.color.opacity(animateGradient ? 0.7 : 0.85)
                                    ],
                                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                                )
                            )
                        
                        // Shimmer effect overlay
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: animateGradient ? 200 : -200)
                            .opacity(0.6)
                        
                        HStack(spacing: 16) {
                            // Animated icon
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(animateGradient ? 5 : -5))
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGradient)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quick Start")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Begin an empty workout")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .scaleEffect(animateGradient ? 1.05 : 0.95)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGradient)
                        }
                        .padding(22)
                    }
                    .shadow(color: settings.accentColor.color.opacity(0.4), radius: 15, x: 0, y: 8)
                    .scaleEffect(selectedCardId != nil && selectedCardId != activeProgram?.id ? 0.98 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardId)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 30)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                .onAppear {
                    appearAnimation = true
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient = true
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
                        
                        ForEach(Array(templates.prefix(3).enumerated()), id: \.element.id) { index, template in
                            QuickTemplateCard(template: template, cardIndex: index) {
                                onTemplateSelect(template, nil, nil, nil)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
            }
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
    }
}

struct QuickTemplateCard: View {
    let template: WorkoutTemplate
    var cardIndex: Int = 0
    let action: () -> Void
    @State private var isPressed = false
    @State private var showGlow = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
            #if os(iOS)
            SettingsManager.shared.impactFeedback(style: .light)
            #else
            SettingsManager.shared.impactFeedback()
            #endif
        }) {
            ZStack {
                // Glow effect background
                if showGlow {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            RadialGradient(
                                colors: [settings.accentColor.color.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .blur(radius: 20)
                        .opacity(showGlow ? 0.6 : 0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showGlow)
                }
                
                HStack(spacing: 16) {
                    // Enhanced Icon with animation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        settings.accentColor.color.opacity(0.15),
                                        settings.accentColor.color.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        
                        Circle()
                            .stroke(settings.accentColor.color.opacity(0.3), lineWidth: 1)
                            .frame(width: 54, height: 54)
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(settings.accentColor.color)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                            .rotationEffect(.degrees(isPressed ? -5 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
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
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    #if os(iOS)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    #else
                    .fill(Color.gray.opacity(0.2))
                    #endif
                    .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .onAppear {
            // Add subtle glow animation after a delay based on card index
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(cardIndex) * 0.3 + 1.0) {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    showGlow = true
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self], inMemory: true)
}