import SwiftUI
import SwiftData

struct ExercisesList: View {
    @Bindable var session: WorkoutSession
    @Binding var isEditMode: Bool
    @Binding var showingAddExercise: Bool
    @Binding var appearAnimation: Bool
    let recentTemplates: [WorkoutTemplate]
    let onLoadTemplate: (WorkoutTemplate) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    templateCarousel
                    exerciseCards
                    addExerciseButton
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            
            restTimerBar
        }
    }
    
    @ViewBuilder
    private var templateCarousel: some View {
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
                                onLoadTemplate(template)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var exerciseCards: some View {
        ForEach(Array(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated()), id: \.element.id) { index, exercise in
            VStack(spacing: 0) {
                supersetIndicator(for: exercise, at: index)
                
                ExerciseCard(
                    exercise: exercise,
                    session: session,
                    isEditMode: isEditMode,
                    onSetComplete: {
                        handleSetComplete(for: exercise)
                    },
                    onDelete: {
                        deleteExercise(exercise)
                    }
                )
                .id(exercise.id)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: session.exercises.map(\.id))
    }
    
    @ViewBuilder
    private func supersetIndicator(for exercise: SessionExercise, at index: Int) -> some View {
        if index > 0 {
            let exercises = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
            let prevExercise = exercises[index - 1]
            if let groupId = exercise.supersetGroupId,
               prevExercise.supersetGroupId == groupId {
                HStack {
                    Text("SUPERSET")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 2, height: 2)
                        }
                    }
                    Text("WITH ABOVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    private var addExerciseButton: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(settings.accentColor.color)
            Text("Add Exercise")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 5)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .onTapGesture {
            showingAddExercise = true
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
    }
    
    @ViewBuilder
    private var restTimerBar: some View {
        if timerManager.showRestBar {
            VStack {
                Spacer()
                
                RestTimerBar()
                    .padding(.horizontal)
                    .padding(.bottom, 100)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func handleSetComplete(for exercise: SessionExercise) {
        let exercises = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        let currentIndex = exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
        
        if !timerManager.isRunning {
            settings.impactFeedback(style: .light)
        }
        
        var shouldStartRest = true
        
        if let groupId = exercise.supersetGroupId {
            if currentIndex < exercises.count - 1 {
                let nextExercise = exercises[currentIndex + 1]
                if nextExercise.supersetGroupId == groupId {
                    shouldStartRest = false
                }
            }
        }
        
        if shouldStartRest {
            timerManager.startRestTimer(seconds: exercise.restSeconds)
        }
    }
    
    private func deleteExercise(_ exercise: SessionExercise) {
        withAnimation {
            if let groupId = exercise.supersetGroupId {
                let sameGroup = session.exercises.filter { $0.supersetGroupId == groupId }
                if sameGroup.count == 2 {
                    sameGroup.forEach { $0.supersetGroupId = nil }
                }
            }
            
            session.exercises.removeAll { $0.id == exercise.id }
            
            let sorted = session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
            for (index, remainingExercise) in sorted.enumerated() {
                remainingExercise.orderIndex = index
            }
            
            try? modelContext.save()
        }
    }
}