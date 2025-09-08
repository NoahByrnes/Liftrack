import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var templateDescription: String
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]
    var createdAt: Date
    var lastUsedAt: Date?
    
    init(name: String, description: String = "") {
        self.id = UUID()
        self.name = name
        self.templateDescription = description
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
    var supersetGroupId: String? = nil
    @Relationship(deleteRule: .cascade) var templateSets: [TemplateSet]
    
    init(exercise: Exercise, orderIndex: Int, targetSets: Int = 3, targetReps: Int = 10, targetWeight: Double? = nil, customRestSeconds: Int? = nil, supersetGroupId: String? = nil) {
        self.id = UUID()
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.customRestSeconds = customRestSeconds
        self.supersetGroupId = supersetGroupId
        self.templateSets = []
    }
    
    var restSeconds: Int {
        customRestSeconds ?? exercise.defaultRestSeconds
    }
}

@Model
final class TemplateSet {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double
    
    init(setNumber: Int, reps: Int, weight: Double) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
    }
}