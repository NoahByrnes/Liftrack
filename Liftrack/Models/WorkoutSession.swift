import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var templateId: UUID?
    var templateName: String
    var startedAt: Date
    var completedAt: Date?
    var notes: String?
    @Relationship(deleteRule: .cascade) var exercises: [SessionExercise]
    
    init(template: WorkoutTemplate? = nil, templateName: String = "Quick Workout") {
        self.id = UUID()
        self.templateId = template?.id
        self.templateName = template?.name ?? templateName
        self.startedAt = Date()
        self.exercises = []
    }
    
    var duration: TimeInterval? {
        guard let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
    
    var isActive: Bool {
        completedAt == nil
    }
}

@Model
final class SessionExercise {
    var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var orderIndex: Int
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
    var exercise: Exercise
    var customRestSeconds: Int?
    
    init(exercise: Exercise, orderIndex: Int, customRestSeconds: Int? = nil) {
        self.id = UUID()
        self.exerciseId = exercise.id
        self.exerciseName = exercise.name
        self.orderIndex = orderIndex
        self.sets = []
        self.exercise = exercise
        self.customRestSeconds = customRestSeconds
    }
    
    var restSeconds: Int {
        customRestSeconds ?? exercise.defaultRestSeconds
    }
}

@Model
final class WorkoutSet {
    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var completedAt: Date?
    
    init(setNumber: Int, weight: Double = 0, reps: Int = 0) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
    }
    
    func toggleCompleted() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}