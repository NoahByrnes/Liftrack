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
    
    // Program context
    var programId: UUID?
    var programName: String?
    var programWeek: Int?
    var programDay: Int?
    
    init() {
        self.id = UUID()
        self.templateId = nil
        self.templateName = "Quick Workout"
        self.startedAt = Date()
        self.exercises = []
        self.programId = nil
        self.programName = nil
        self.programWeek = nil
        self.programDay = nil
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
    var customRestSeconds: Int?
    var supersetGroupId: String?
    
    init(exercise: Exercise, orderIndex: Int, customRestSeconds: Int? = nil, supersetGroupId: String? = nil) {
        self.id = UUID()
        self.exerciseId = exercise.id
        self.exerciseName = exercise.name
        self.orderIndex = orderIndex
        self.sets = []
        self.customRestSeconds = customRestSeconds ?? exercise.defaultRestSeconds
        self.supersetGroupId = supersetGroupId
    }
    
    var restSeconds: Int {
        customRestSeconds ?? 90 // Default rest time
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
    var isWarmup: Bool = false
    var notes: String = ""
    
    init(setNumber: Int, weight: Double = 0, reps: Int = 0, isWarmup: Bool = false) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
        self.isWarmup = isWarmup
        self.notes = ""
    }
    
    func toggleCompleted() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
    
    func toggleWarmup() {
        isWarmup.toggle()
    }
}