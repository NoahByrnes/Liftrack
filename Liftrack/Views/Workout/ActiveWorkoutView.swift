import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @State private var showingAddExercise = false
    @State private var showingRestTimer = false
    @State private var showingCancelAlert = false
    @State private var showingEmptyWorkoutAlert = false
    @State private var appearAnimation = false
    @State private var headerScale = 0.9
    @State private var isEditMode = false
    @State private var showingFinishConfirmation = false
    
    // Template-related properties
    @Query(sort: \WorkoutTemplate.lastUsedAt, order: .reverse) private var templates: [WorkoutTemplate]
    
    private var recentTemplates: [WorkoutTemplate] {
        Array(templates.prefix(5))
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 0) {
                // Clean, minimal header
                VStack(spacing: 16) {
                    // Top row with minimize and menu
                    HStack {
                        // Minimize button
                        Button(action: {
                            if session.exercises.isEmpty {
                                cancelWorkout()
                            } else {
                                withAnimation {
                                    timerManager.isMinimized = true
                                    dismiss()
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        
                        Spacer()
                        
                        // Edit/Done toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isEditMode.toggle()
                            }
                            settings.impactFeedback(style: .light)
                        }) {
                            Text(isEditMode ? "Done" : "Edit")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    
                    // Central timer display
                    VStack(spacing: 8) {
                        Text(formatTime(timerManager.elapsedTime))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        if !session.templateName.isEmpty {
                            Text(session.templateName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Action buttons row
                    HStack(spacing: 12) {
                        // Rest timer button
                        Menu {
                            ForEach([30, 60, 90, 120], id: \.self) { seconds in
                                Button(action: {
                                    timerManager.startRestTimer(seconds: seconds)
                                }) {
                                    Label(formatPresetTime(seconds), systemImage: "timer")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "timer")
                                Text("Rest")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Finish workout button
                        Button(action: {
                            if session.exercises.isEmpty {
                                showingEmptyWorkoutAlert = true
                            } else {
                                showingFinishConfirmation = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Finish")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.3))
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                
                // Exercise list with proper styling
                ScrollView {
                    VStack(spacing: 12) {
                        // Show template carousel only when no exercises are present
                        if session.exercises.isEmpty && !recentTemplates.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("QUICK START FROM TEMPLATE")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(recentTemplates) { template in
                                            TemplateQuickCard(template: template) {
                                                loadTemplate(template)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    
                        ForEach(Array(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated()), id: \.element.id) { index, exercise in
                            VStack(spacing: 0) {
                                // Show superset connector for exercises in same group
                                if index > 0 {
                                    let prevExercise = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })[index - 1]
                                    if let groupId = exercise.supersetGroupId,
                                       prevExercise.supersetGroupId == groupId {
                                        HStack {
                                            Spacer()
                                            VStack(spacing: 2) {
                                                ForEach(0..<3, id: \.self) { _ in
                                                    Circle()
                                                        .fill(Color.white.opacity(0.5))
                                                        .frame(width: 3, height: 3)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            
                            ExerciseCard(
                                exercise: exercise,
                                session: session,
                                isEditMode: isEditMode,
                                onSetComplete: {
                                    // Dismiss keyboard when completing a set
                                    #if os(iOS)
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    #endif
                                    if !timerManager.isRunning {
                                        timerManager.startWorkoutTimer()
                                    }
                                    // Update current exercise in Live Activity
                                    timerManager.updateCurrentExercise(exercise.exerciseName)
                                    
                                    // Check if in superset - if so, no rest between superset exercises
                                    let exercises = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                                    var shouldStartRest = true
                                    
                                    if let groupId = exercise.supersetGroupId,
                                       let currentIndex = exercises.firstIndex(where: { $0.id == exercise.id }),
                                       currentIndex + 1 < exercises.count,
                                       exercises[currentIndex + 1].supersetGroupId == groupId {
                                        // Next exercise is in same superset, don't start rest
                                        shouldStartRest = false
                                    }
                                    
                                    if shouldStartRest {
                                        timerManager.startRestTimer(seconds: exercise.customRestSeconds ?? 90)
                                    }
                                },
                                onDelete: {
                                    withAnimation {
                                        // If part of superset, remove from group
                                        if let groupId = exercise.supersetGroupId {
                                            // Unlink other exercises in same superset if only 2
                                            let sameGroup = session.exercises.filter { $0.supersetGroupId == groupId }
                                            if sameGroup.count == 2 {
                                                sameGroup.forEach { $0.supersetGroupId = nil }
                                            }
                                        }
                                        
                                        session.exercises.removeAll { $0.id == exercise.id }
                                        // Renumber remaining exercises
                                        let sortedExercises = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                                        for (index, remainingExercise) in sortedExercises.enumerated() {
                                            remainingExercise.orderIndex = index
                                        }
                                        try? modelContext.save()
                                    }
                                }
                                )
                                .padding(.horizontal, 20)
                            }
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.08), value: appearAnimation)
                        }
                        
                        // Add Exercise Button - Clean floating style
                        Button(action: {
                            showingAddExercise = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add Exercise")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Add padding at bottom to account for tab bar and rest timer
                        Color.clear
                            .frame(height: timerManager.showRestBar ? 180 : 100)
                    }
                    .padding(.top, 8)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Rest timer bar - positioned as floating element above tab bar
            if timerManager.showRestBar {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(timerManager.restTimeRemaining <= 3 ? .red : settings.accentColor.color)
                                .scaleEffect(timerManager.restTimeRemaining <= 3 ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: timerManager.restTimeRemaining)
                            
                            Text("Rest: \(formatRestTime(timerManager.restTimeRemaining))")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(timerManager.restTimeRemaining <= 3 ? .red : .primary)
                                .fontWeight(timerManager.restTimeRemaining <= 3 ? .bold : .regular)
                                .animation(.easeInOut(duration: 0.3), value: timerManager.restTimeRemaining)
                            
                            Spacer()
                            
                            // Quick time adjustment buttons
                            Image(systemName: "minus.circle")
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    timerManager.adjustRestTime(by: -15)
                                }
                            
                            Image(systemName: "plus.circle")
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    timerManager.adjustRestTime(by: 15)
                                }
                            
                            Text("Expand")
                                .font(.footnote)
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    showingRestTimer = true
                                }
                            
                            Text("Skip")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    timerManager.endRestTimer()
                                }
                        }
                        .padding()
                        .background(
                            timerManager.restTimeRemaining <= 3 ? 
                            Color.red.opacity(0.2) : 
                            Color.clear
                        )
                        .background(.ultraThinMaterial)
                        .animation(.easeInOut(duration: 0.3), value: timerManager.restTimeRemaining)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Position above tab bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appearAnimation = true
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1)) {
                headerScale = 1.0
            }
            
            // Set workout name for Live Activity
            timerManager.updateWorkoutName(session.templateName)
            
            // Set initial exercise if available
            if let firstExercise = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).first {
                timerManager.updateCurrentExercise(firstExercise.exerciseName)
            }
        }
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("Are you sure you want to cancel this workout? Your progress will not be saved.")
        }
        .alert("Empty Workout", isPresented: $showingEmptyWorkoutAlert) {
            Button("Add Exercise", role: .cancel) {
                showingAddExercise = true
            }
            Button("Cancel Workout", role: .destructive) {
                cancelWorkout()
            }
        } message: {
            Text("This workout has no exercises and will not be saved. Would you like to add exercises or cancel the workout?")
        }
        .alert("Finish Workout?", isPresented: $showingFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish", role: .none) {
                finishWorkout()
            }
        } message: {
            Text("Are you ready to complete this workout? Make sure all your sets are recorded.")
        }
        .sheet(isPresented: $showingAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(isPresented: $showingRestTimer) {
            ExpandedRestTimerView(
                remainingTime: $timerManager.restTimeRemaining,
                totalDuration: timerManager.restTotalDuration,
                isRunning: timerManager.showRestBar,
                onDismiss: {
                    showingRestTimer = false
                },
                onStop: {
                    timerManager.endRestTimer()
                    showingRestTimer = false
                }
            )
        }
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func formatPresetTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds % 60 == 0 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
        }
    }
    
    private func finishWorkout() {
        timerManager.cleanup()
        
        session.completedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error finishing workout: \(error)")
        }
        
        dismiss()
    }
    
    private func cancelWorkout() {
        timerManager.cleanup()
        
        // Clear all relationships first to avoid SwiftData crash
        session.exercises.removeAll()
        
        // Delete the session
        modelContext.delete(session)
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error canceling workout: \(error)")
        }
        
        dismiss()
    }
    
    private func addExercise(_ exercise: Exercise) {
        let newIndex = (session.exercises.map { $0.orderIndex }.max() ?? -1) + 1
        // Use default rest time from settings
        let defaultRest = UserDefaults.standard.integer(forKey: "defaultRestTime")
        let sessionExercise = SessionExercise(
            exercise: exercise, 
            orderIndex: newIndex,
            customRestSeconds: defaultRest > 0 ? defaultRest : 90  // Use settings default or fallback to 90
        )
        
        for i in 1...3 {
            let set = WorkoutSet(setNumber: i)
            sessionExercise.sets.append(set)
        }
        
        session.exercises.append(sessionExercise)
        try? modelContext.save()
    }
    
    private func loadTemplate(_ template: WorkoutTemplate) {
        // Load exercises from template
        for templateExercise in template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let sessionExercise = SessionExercise(
                exercise: templateExercise.exercise,
                orderIndex: templateExercise.orderIndex,
                customRestSeconds: templateExercise.customRestSeconds
            )
            sessionExercise.supersetGroupId = templateExercise.supersetGroupId
            
            // Create sets based on template configuration
            if !templateExercise.templateSets.isEmpty {
                // Use the template sets if they exist
                for templateSet in templateExercise.templateSets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let set = WorkoutSet(setNumber: templateSet.setNumber)
                    set.reps = templateSet.reps
                    set.weight = templateSet.weight
                    sessionExercise.sets.append(set)
                }
            } else {
                // Otherwise create default sets based on targetSets/targetReps/targetWeight
                for i in 1...templateExercise.targetSets {
                    let set = WorkoutSet(setNumber: i)
                    set.reps = templateExercise.targetReps
                    set.weight = templateExercise.targetWeight ?? 0
                    sessionExercise.sets.append(set)
                }
            }
            
            session.exercises.append(sessionExercise)
        }
        
        // Update template's last used date
        template.lastUsedAt = Date()
        
        // Save changes
        try? modelContext.save()
        
        // Provide feedback
        settings.impactFeedback(style: .medium)
    }
}

struct ExerciseCard: View {
    let exercise: SessionExercise
    let session: WorkoutSession
    let isEditMode: Bool
    let onSetComplete: () -> Void
    let onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @State private var isProcessingAction = false
    @State private var showingNotesDialog = false
    @State private var exerciseNotes = ""
    @State private var showingRestTimerDialog = false
    @State private var tempRestMinutes = 1
    @State private var tempRestSeconds = 30
    
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
    
    private func formatPresetTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds % 60 == 0 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
        }
    }
    
    private func reorderSets(for exercise: SessionExercise) {
        let warmupSets = exercise.sets.filter { $0.isWarmup }.sorted(by: { $0.setNumber < $1.setNumber })
        let regularSets = exercise.sets.filter { !$0.isWarmup }.sorted(by: { $0.setNumber < $1.setNumber })
        
        // Renumber warmup sets
        for (index, set) in warmupSets.enumerated() {
            set.setNumber = index + 1
        }
        
        // Renumber regular sets
        for (index, set) in regularSets.enumerated() {
            set.setNumber = index + 1
        }
    }
    
    
    private func toggleSuperset() {
        let exercises = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if exercise.supersetGroupId != nil {
            // Remove from superset
            exercise.supersetGroupId = nil
        } else {
            // Find the previous or next exercise to superset with
            if let currentIndex = exercises.firstIndex(where: { $0.id == exercise.id }) {
                let groupId = UUID().uuidString
                exercise.supersetGroupId = groupId
                
                // Also set the next exercise to the same superset group
                if currentIndex + 1 < exercises.count {
                    exercises[currentIndex + 1].supersetGroupId = groupId
                } else if currentIndex > 0 {
                    // If this is the last exercise, group with previous
                    exercises[currentIndex - 1].supersetGroupId = groupId
                }
            }
        }
        
        try? modelContext.save()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Superset indicator if part of a superset
            if exercise.supersetGroupId != nil {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .medium))
                    Text("SUPERSET")
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                }
                .foregroundColor(settings.accentColor.color)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            
            // Exercise Header
            HStack {
                Text(exercise.exerciseName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isEditMode {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            #if os(iOS)
                            SettingsManager.shared.impactFeedback(style: .medium)
                            #endif
                            onDelete()
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Rest Timer, Superset and Notes
            HStack {
                Button(action: {
                    tempRestMinutes = exercise.restSeconds / 60
                    tempRestSeconds = exercise.restSeconds % 60
                    showingRestTimerDialog = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 13))
                        Text("Rest: \(formatRestTime(exercise.restSeconds))")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Superset toggle button
                Button(action: {
                    toggleSuperset()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: exercise.supersetGroupId != nil ? "link.circle.fill" : "link.circle")
                            .font(.system(size: 13))
                        Text(exercise.supersetGroupId != nil ? "Unlink" : "Superset")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(exercise.supersetGroupId != nil ? settings.accentColor.color : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Exercise notes button
                Button(action: {
                    showingNotesDialog = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 13))
                        Text("Notes")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Sets Section  
            VStack(spacing: 0) {
                // Sets Header
                HStack(spacing: 0) {
                    Text("Set")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .center)
                    
                    Text("Previous")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("lbs")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .center)
                    
                    Text("Reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .center)
                    
                    // Space for check mark
                    Color.clear
                        .frame(width: 40)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.5))
                
                // Set Rows - Warmup sets first, then regular sets
                ForEach(exercise.sets.sorted(by: { 
                    if $0.isWarmup != $1.isWarmup {
                        return $0.isWarmup
                    }
                    return $0.setNumber < $1.setNumber 
                })) { set in
                    WorkoutSetRow(
                        set: set,
                        exercise: exercise,
                        isEditMode: isEditMode,
                        onComplete: {
                            onSetComplete()
                        },
                        canDelete: exercise.sets.count > 1,
                        onDelete: {
                            withAnimation {
                                exercise.sets.removeAll { $0.id == set.id }
                                // Renumber remaining sets
                                reorderSets(for: exercise)
                                try? modelContext.save()
                            }
                        }
                    )
                }
                
                
                // Add Set Button
                Button(action: {
                    guard !isProcessingAction else { return }
                    isProcessingAction = true
                    let newSetNumber = (exercise.sets.map { $0.setNumber }.max() ?? 0) + 1
                    let newSet = WorkoutSet(setNumber: newSetNumber)
                    exercise.sets.append(newSet)
                    try? modelContext.save()
                    isProcessingAction = false
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Set")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(settings.accentColor.color.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingNotesDialog) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Exercise Notes")
                        .font(.headline)
                        .padding(.top)
                    
                    TextField("Add notes for this exercise...", text: $exerciseNotes, axis: .vertical)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .lineLimit(3...10)
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingNotesDialog = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            // Save notes to exercise
                            try? modelContext.save()
                            showingNotesDialog = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingRestTimerDialog) {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("Rest Timer Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    // Quick Preset Buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK PRESETS")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach([30, 45, 60, 90, 120, 180], id: \.self) { seconds in
                                Button(action: {
                                    tempRestMinutes = seconds / 60
                                    tempRestSeconds = seconds % 60
                                    exercise.customRestSeconds = seconds
                                    try? modelContext.save()
                                    showingRestTimerDialog = false
                                    // Start timer immediately with preset
                                    EnhancedWorkoutTimerManager.shared.startRestTimer(seconds: seconds)
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 20))
                                        Text(formatPresetTime(seconds))
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(exercise.customRestSeconds == seconds ? .white : settings.accentColor.color)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(exercise.customRestSeconds == seconds ? 
                                                settings.accentColor.color : 
                                                settings.accentColor.color.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Custom Time Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CUSTOM TIME")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("Minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("Minutes", selection: $tempRestMinutes) {
                                    ForEach(0..<10) { min in
                                        Text("\(min)").tag(min)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80, height: 100)
                            }
                            
                            VStack {
                                Text("Seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("Seconds", selection: $tempRestSeconds) {
                                    ForEach([0, 15, 30, 45], id: \.self) { sec in
                                        Text("\(sec)").tag(sec)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80, height: 100)
                            }
                        }
                        
                        // Current selection display
                        Text("Rest time: \(formatRestTime((tempRestMinutes * 60) + tempRestSeconds))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingRestTimerDialog = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Start Timer") {
                            let totalSeconds = (tempRestMinutes * 60) + tempRestSeconds
                            exercise.customRestSeconds = totalSeconds
                            try? modelContext.save()
                            showingRestTimerDialog = false
                            // Start timer immediately
                            EnhancedWorkoutTimerManager.shared.startRestTimer(seconds: totalSeconds)
                        }
                        .fontWeight(.medium)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct WorkoutSetRow: View {
    let set: WorkoutSet
    let exercise: SessionExercise
    let isEditMode: Bool
    let onComplete: () -> Void
    let canDelete: Bool
    let onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @AppStorage("show1RMEstimates") private var show1RMEstimates = true
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
           sort: \WorkoutSession.completedAt, order: .reverse) 
    private var previousSessions: [WorkoutSession]
    
    @State private var weight = ""
    @State private var reps = ""
    @State private var showingRPEPicker = false
    
    // Get previous completed set values for placeholders
    private var previousSetValues: (weight: Double, reps: Int)? {
        let completedSets = exercise.sets
            .filter { $0.isCompleted && $0.id != set.id }
            .sorted { $0.setNumber > $1.setNumber }
        
        return completedSets.first.map { (weight: $0.weight, reps: $0.reps) }
    }
    
    // Get previous workout data for this exercise
    private var previousWorkoutData: (weight: Double, reps: Int)? {
        // Find the most recent session with this exercise
        for session in previousSessions {
            if let prevExercise = session.exercises.first(where: { $0.exerciseName == exercise.exerciseName }) {
                // Find the corresponding set number
                let prevSet = prevExercise.sets
                    .filter { $0.isCompleted && $0.isWarmup == set.isWarmup && $0.setNumber == set.setNumber }
                    .first
                
                if let prevSet = prevSet {
                    return (weight: prevSet.weight, reps: prevSet.reps)
                }
            }
        }
        return nil
    }
    
    // Format weight to string, preserving decimals
    private func formatWeight(_ weight: Double) -> String {
        // If weight is a whole number, show without decimal
        if weight == floor(weight) {
            return "\(Int(weight))"
        } else {
            // Otherwise show with one decimal place
            return String(format: "%.1f", weight)
        }
    }
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...4: return .green
        case 5...6: return .yellow
        case 7...8: return .orange
        case 9...10: return .red
        default: return .secondary
        }
    }
    
    var body: some View {
        ZStack {
            // Background actions revealed on swipe (only in edit mode)
            HStack(spacing: 0) {
                // Duplicate action (swipe right) - dynamic width
                if isEditMode && dragOffset > 0 {
                    HStack {
                        Button(action: duplicateSet) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 60)
                                .frame(maxHeight: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .frame(width: max(0, dragOffset))
                    .frame(maxHeight: .infinity)
                    .background(
                        Color.blue
                            .opacity(dragOffset > 50 ? 1.0 : Double(dragOffset) / 50.0)
                    )
                }
                
                Spacer()
                
                // Delete action (swipe left) - dynamic width
                if isEditMode && dragOffset < 0 && canDelete {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                onDelete()
                            }
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 60)
                                .frame(maxHeight: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(width: max(0, abs(dragOffset)))
                    .frame(maxHeight: .infinity)
                    .background(
                        Color.red
                            .opacity(abs(dragOffset) > 50 ? 1.0 : Double(abs(dragOffset)) / 50.0)
                    )
                }
            }
            .frame(maxHeight: .infinity)
            
            // Main content
            HStack(spacing: 0) {
                // Edit mode indicator
                if isEditMode {
                    Rectangle()
                        .fill(settings.accentColor.color.opacity(0.3))
                        .frame(width: 3)
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                }
                // Set number
                Text(set.isWarmup ? "W" : "\(set.setNumber)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(set.isWarmup ? .orange : .primary)
                    .frame(width: 50, alignment: .center)
                    .onTapGesture {
                        withAnimation {
                            // Store the current set number before toggling
                            let wasWarmup = set.isWarmup
                            
                            set.toggleWarmup()
                            
                            if !wasWarmup {
                                // Becoming a warmup - give it the next warmup number
                                let existingWarmupCount = exercise.sets.filter { $0.isWarmup && $0.id != set.id }.count
                                set.setNumber = existingWarmupCount + 1
                            } else {
                                // Becoming a regular set - give it the next regular number
                                let existingRegularCount = exercise.sets.filter { !$0.isWarmup && $0.id != set.id }.count
                                set.setNumber = existingRegularCount + 1
                            }
                            
                            // Now renumber all sets to ensure consistency
                            let warmupSets = exercise.sets.filter { $0.isWarmup }.sorted(by: { $0.setNumber < $1.setNumber })
                            let regularSets = exercise.sets.filter { !$0.isWarmup }.sorted(by: { $0.setNumber < $1.setNumber })
                            
                            // Renumber warmup sets
                            for (index, warmupSet) in warmupSets.enumerated() {
                                warmupSet.setNumber = index + 1
                            }
                            
                            // Renumber regular sets
                            for (index, regularSet) in regularSets.enumerated() {
                                regularSet.setNumber = index + 1
                            }
                            
                            try? modelContext.save()
                        }
                    }
                
                // Previous workout data
                if let previous = previousWorkoutData {
                    Text("\(formatWeight(previous.weight)) × \(previous.reps)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("-")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            
                // Weight Field with lbs label
                HStack(spacing: 4) {
                    #if os(iOS)
                    AutoSelectTextField(
                        placeholder: (previousWorkoutData ?? previousSetValues).map { formatWeight($0.weight) } ?? "0",
                        text: $weight,
                        keyboardType: .decimalPad,
                        textAlignment: .center,
                        font: .systemFont(ofSize: 16, weight: .medium)
                    )
                    .frame(width: 55, height: 32)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(6)
                    .onChange(of: weight) { _, newValue in
                        if let value = Double(newValue) {
                            set.weight = value
                        } else if newValue.isEmpty, let previous = previousSetValues {
                            set.weight = previous.weight
                        }
                    }
                    #else
                    TextField((previousWorkoutData ?? previousSetValues).map { formatWeight($0.weight) } ?? "0", text: $weight)
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .frame(width: 55)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .cornerRadius(6)
                        .onChange(of: weight) { _, newValue in
                            if let value = Double(newValue) {
                                set.weight = value
                            } else if newValue.isEmpty, let previous = previousSetValues {
                                set.weight = previous.weight
                            }
                        }
                    #endif
                    
                    Text("lbs")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(width: 90, alignment: .center)
            
                // Reps Field
                #if os(iOS)
                AutoSelectTextField(
                    placeholder: (previousWorkoutData ?? previousSetValues).map { "\($0.reps)" } ?? "0",
                    text: $reps,
                    keyboardType: .numberPad,
                    textAlignment: .center,
                    font: .systemFont(ofSize: 16, weight: .medium)
                )
                .frame(width: 50, height: 32)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(6)
                .onChange(of: reps) { _, newValue in
                    if let value = Int(newValue) {
                        set.reps = value
                    } else if newValue.isEmpty, let previous = previousSetValues {
                        set.reps = previous.reps
                    }
                }
                .frame(width: 70, alignment: .center)
                #else
                TextField((previousWorkoutData ?? previousSetValues).map { "\($0.reps)" } ?? "0", text: $reps)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                    .cornerRadius(6)
                    .onChange(of: reps) { _, newValue in
                        if let value = Int(newValue) {
                            set.reps = value
                        } else if newValue.isEmpty, let previous = previousSetValues {
                            set.reps = previous.reps
                        }
                    }
                    .frame(width: 70, alignment: .center)
                #endif
            
                // Complete button with failure indicator
                VStack(spacing: 2) {
                    ZStack {
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(set.isCompleted ? DesignConstants.Colors.completedGreen() : .secondary)
                            .frame(width: 40)
                        
                        if false { // Disabled: failure tracking
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Show 1RM for heavy sets (if enabled in settings)
                    if set.isCompleted && show1RMEstimates {
                        if !set.isWarmup && set.reps > 0 && set.reps < 12 && set.weight > 0 {
                            // Simple Epley formula for 1RM estimation
                            let oneRM = set.weight * (1 + Double(set.reps) / 30.0)
                            VStack(spacing: 0) {
                                Text("1RM")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(.secondary.opacity(0.8))
                                Text("\(Int(oneRM))")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onTapGesture {
                    // Auto-fill empty fields with previous values (prefer previous workout data)
                    let previous = previousWorkoutData ?? previousSetValues
                    if weight.isEmpty, let prev = previous {
                        weight = formatWeight(prev.weight)
                        set.weight = prev.weight
                    }
                    if reps.isEmpty, let prev = previous {
                        reps = "\(prev.reps)"
                        set.reps = prev.reps
                    }
                    
                    set.toggleCompleted()
                    if set.isCompleted {
                        onComplete()
                        // Show RPE picker for non-warmup sets
                        if !set.isWarmup {
                            showingRPEPicker = true
                        }
                    }
                    SettingsManager.shared.impactFeedback(style: .light)
                }
                .onLongPressGesture {
                    if canDelete {
                        SettingsManager.shared.impactFeedback(style: .medium)
                        onDelete()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color(UIColor.systemBackground)
                    .shadow(color: isDragging ? Color.black.opacity(0.15) : Color.clear, radius: 5, x: 0, y: 2)
            )
            .offset(x: dragOffset)
        .gesture(
            isEditMode ? DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        isDragging = true
                        // Add resistance at the edges and make it less sensitive
                        let translation = value.translation.width
                        let threshold: CGFloat = 30 // Minimum drag before responding
                        
                        if abs(translation) < threshold {
                            dragOffset = 0
                        } else if abs(translation) > 150 {
                            // Apply resistance after 150px
                            let resistance = (abs(translation) - 150) * 0.5
                            dragOffset = translation > 0 ? 150 + resistance : -150 - resistance
                        } else {
                            dragOffset = translation
                        }
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if abs(dragOffset) > 100 {
                            if dragOffset > 0 {
                                // Swipe right - duplicate
                                duplicateSet()
                                // Haptic feedback
                                #if os(iOS)
                                SettingsManager.shared.impactFeedback(style: .medium)
                                #endif
                            } else if canDelete {
                                // Swipe left - delete
                                onDelete()
                                // Haptic feedback
                                #if os(iOS)
                                SettingsManager.shared.impactFeedback(style: .medium)
                                #endif
                            }
                        }
                        dragOffset = 0
                        isDragging = false
                    }
                } : nil
        )
        }
        .onAppear {
            weight = set.weight > 0 ? formatWeight(set.weight) : ""
            reps = set.reps > 0 ? "\(set.reps)" : ""
        }
        // RPE picker disabled for now
    }
    
    private func duplicateSet() {
        let newSet = WorkoutSet(
            setNumber: (exercise.sets.map { $0.setNumber }.max() ?? 0) + 1,
            weight: set.weight,
            reps: set.reps,
            isWarmup: set.isWarmup
        )
        exercise.sets.append(newSet)
        try? modelContext.save()
    }
}

/* Disabled: RPE tracking will be re-enabled with smart features
struct RPEPickerView: View {
    let set: WorkoutSet
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    
    let rpeDescriptions = [
        1: "Very Light",
        2: "Light",
        3: "Light",
        4: "Moderate",
        5: "Moderate",
        6: "Somewhat Hard",
        7: "Hard",
        8: "Very Hard",
        9: "Extremely Hard",
        10: "Maximum Effort"
    ]
    
    let rpeDetails = [
        1: "Could do many more reps",
        2: "Warm-up weight",
        3: "Easy, conversational",
        4: "Starting to feel it",
        5: "Steady working pace",
        6: "Breathing harder",
        7: "Challenging but doable",
        8: "Near limit, 2-3 reps left",
        9: "Maybe 1 rep left",
        10: "Absolute maximum, failed or nearly failed"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Skip") {
                    isPresented = false
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Rate Perceived Exertion")
                    .font(.headline)
                
                Spacer()
                
                Button("Skip") {
                    isPresented = false
                }
                .foregroundColor(.clear)
                .disabled(true)
            }
            .padding()
            
            // RPE Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(1...10, id: \.self) { rpe in
                        Button(action: {
                            set.rpe = rpe
                            try? modelContext.save()
                            settings.impactFeedback(style: .light)
                            isPresented = false
                        }) {
                            VStack(spacing: 8) {
                                Text("\(rpe)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(rpeButtonColor(rpe))
                                
                                Text(rpeDescriptions[rpe] ?? "")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(rpeDetails[rpe] ?? "")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(rpeButtonColor(rpe).opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(set.rpe == rpe ? rpeButtonColor(rpe) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
    
    private func rpeButtonColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...3: return .green
        case 4...5: return .yellow
        case 6...7: return .orange
        case 8...9: return .red
        case 10: return .purple
        default: return .secondary
        }
    }
}
*/ // End of disabled RPEPickerView

#Preview {
    do {
        let container = try ModelContainer(for: WorkoutSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let session = WorkoutSession()
        container.mainContext.insert(session)
        
        return ActiveWorkoutView(session: session)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview")
    }
}