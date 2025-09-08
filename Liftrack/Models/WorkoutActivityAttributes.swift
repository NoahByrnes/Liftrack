import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that updates
        var currentExercise: String
        var restTimeRemaining: Int
        var totalElapsedTime: Int
        var isResting: Bool
        var restEndTime: Date? // For timer countdown
    }
    
    // Static content that doesn't change
    var workoutName: String
    var startTime: Date
}