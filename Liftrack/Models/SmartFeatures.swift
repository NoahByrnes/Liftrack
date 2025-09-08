import Foundation
import SwiftData

// MARK: - Smart Features Extensions
// These are optional, advanced features that can be enabled/disabled
// They should not interfere with basic workout tracking

extension WorkoutExercise {
    // Progression settings - moved from main model
    struct ProgressionSettings {
        var enabled: Bool = false
        var weeklyWeightIncrease: Double = 5.0
        var progressionFrequency: Int = 1
        var repProgressionEnabled: Bool = false
        var targetRepRange: String = "8-12"
        var minRepThreshold: Int = 8
        var autoDeloadEnabled: Bool = false
        
        var repRangeBounds: (min: Int, max: Int) {
            let components = targetRepRange.split(separator: "-")
            if components.count == 2,
               let min = Int(components[0]),
               let max = Int(components[1]) {
                return (min, max)
            }
            return (8, 12)
        }
    }
}

extension WorkoutSet {
    // Performance tracking - moved from main model
    struct PerformanceMetrics {
        var rpe: Int? = nil
        var techniqueBreakdown: Bool = false
        var isFailed: Bool = false
        
        func performanceScore(actualReps: Int, targetReps: Int, actualWeight: Double, targetWeight: Double) -> Double {
            guard targetReps > 0, targetWeight > 0 else { return 1.0 }
            
            let repScore = Double(actualReps) / Double(targetReps)
            let weightScore = actualWeight / targetWeight
            
            if isFailed { return 0.5 }
            if techniqueBreakdown { return 0.75 }
            
            return (repScore * 0.6) + (weightScore * 0.4)
        }
    }
}

// MARK: - Smart Features Extensions
// The enums for TrainingGoal, PeriodizationModel, OneRMFormula, TrainingExperience
// are defined in TrainingScience.swift and can be used when smart features are enabled

// MARK: - Performance Tracking Models
struct ExercisePerformance {
    let averageReps: Double
    let averageWeight: Double
    let failureRate: Double // 0-1 percentage of failed sets
    let performanceScore: Double // 0-1 overall performance
    let estimated1RM: Double?
    
    init(averageReps: Double, averageWeight: Double, failureRate: Double, performanceScore: Double, estimated1RM: Double? = nil) {
        self.averageReps = averageReps
        self.averageWeight = averageWeight
        self.failureRate = failureRate
        self.performanceScore = performanceScore
        // Simple Epley formula for 1RM estimation
        self.estimated1RM = estimated1RM ?? (averageWeight > 0 && averageReps > 0 && averageReps < 30 ? 
            averageWeight * (1 + averageReps / 30.0) : nil)
    }
}