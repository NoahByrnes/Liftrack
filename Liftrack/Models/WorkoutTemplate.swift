import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]
    var createdAt: Date
    var lastUsedAt: Date?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.exercises = []
        self.createdAt = Date()
    }
}

@Model
final class WorkoutExercise {
    var id: UUID
    var exercise: Exercise
    var orderIndex: Int
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double?
    var customRestSeconds: Int?
    
    init(exercise: Exercise, orderIndex: Int, targetSets: Int = 3, targetReps: Int = 10, targetWeight: Double? = nil, customRestSeconds: Int? = nil) {
        self.id = UUID()
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.customRestSeconds = customRestSeconds
    }
    
    var restSeconds: Int {
        customRestSeconds ?? exercise.defaultRestSeconds
    }
}