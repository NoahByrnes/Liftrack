import Foundation
import SwiftData

@Model
final class Program {
    var id = UUID()
    var name: String
    var programDescription: String
    var durationWeeks: Int
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var isActive: Bool = false
    
    // Basic settings
    var deloadWeek: Int? = nil // e.g., week 4 for deload
    
    // Relationships
    var workoutTemplates: [WorkoutTemplate] = []
    var programWeeks: [ProgramWeek] = []
    var completedSessions: [WorkoutSession] = []
    
    init(name: String, description: String = "", durationWeeks: Int = 8) {
        self.name = name
        self.programDescription = description
        self.durationWeeks = durationWeeks
        self.createdAt = Date()
    }
}


@Model
final class ProgramWeek {
    var id = UUID()
    var weekNumber: Int
    var name: String // e.g., "Week 1 - Intro", "Week 4 - Deload"
    var isDeload: Bool = false
    var weightModifier: Double = 1.0 // Multiplier for weights (0.7 for deload)
    
    // Schedule for the week
    var scheduledWorkouts: [ProgramWorkout] = []
    var isCompleted: Bool = false
    var completedAt: Date?
    
    // Relationship
    var program: Program?
    
    init(weekNumber: Int, name: String = "", isDeload: Bool = false) {
        self.weekNumber = weekNumber
        self.name = name.isEmpty ? "Week \(weekNumber)" : name
        self.isDeload = isDeload
        self.weightModifier = isDeload ? 0.7 : 1.0
    }
}

@Model
final class ProgramWorkout {
    var id = UUID()
    var dayNumber: Int // 1-7 for days of week
    var dayName: String // e.g., "Push Day", "Pull Day", "Leg Day"
    var template: WorkoutTemplate?
    var isRestDay: Bool = false
    var isCompleted: Bool = false
    var completedSession: WorkoutSession?
    
    // Progression targets for this workout
    var targetWeightIncrease: Double = 0
    var targetRepsIncrease: Int = 0
    
    // Relationship
    var week: ProgramWeek?
    
    init(dayNumber: Int, dayName: String, template: WorkoutTemplate? = nil, isRestDay: Bool = false) {
        self.dayNumber = dayNumber
        self.dayName = dayName
        self.template = template
        self.isRestDay = isRestDay
    }
}

// Extension to track program progress
extension Program {
    var currentWeek: Int {
        guard let startedAt = startedAt else { return 0 }
        let weeksSinceStart = Calendar.current.dateComponents([.weekOfYear], from: startedAt, to: Date()).weekOfYear ?? 0
        return min(weeksSinceStart + 1, durationWeeks)
    }
    
    var progressPercentage: Double {
        guard durationWeeks > 0 else { return 0 }
        let completedWorkouts = completedSessions.count
        let totalWorkouts = programWeeks.flatMap { $0.scheduledWorkouts }.filter { !$0.isRestDay }.count
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(totalWorkouts) * 100
    }
    
    var nextScheduledWorkout: ProgramWorkout? {
        for week in programWeeks.sorted(by: { $0.weekNumber < $1.weekNumber }) {
            for workout in week.scheduledWorkouts.sorted(by: { $0.dayNumber < $1.dayNumber }) {
                if !workout.isCompleted && !workout.isRestDay {
                    return workout
                }
            }
        }
        return nil
    }
    
    func generateWeeks() {
        programWeeks.removeAll()
        
        for weekNum in 1...durationWeeks {
            let isDeloadWeek = (deloadWeek != nil && weekNum == deloadWeek)
            let week = ProgramWeek(
                weekNumber: weekNum,
                name: isDeloadWeek ? "Week \(weekNum) - Deload" : "Week \(weekNum)",
                isDeload: isDeloadWeek
            )
            
            // Create workout schedule for the week
            // This is a simple rotation through available templates
            var dayNum = 1
            for template in workoutTemplates {
                if dayNum <= 7 {
                    let workout = ProgramWorkout(
                        dayNumber: dayNum,
                        dayName: template.name,
                        template: template
                    )
                    
                    // Workouts can have optional progression targets
                    // These would be set by smart features if enabled
                    
                    week.scheduledWorkouts.append(workout)
                    dayNum += 2 // Skip a day between workouts
                }
            }
            
            // Fill in rest days
            for day in 1...7 {
                if !week.scheduledWorkouts.contains(where: { $0.dayNumber == day }) {
                    let restDay = ProgramWorkout(
                        dayNumber: day,
                        dayName: "Rest Day",
                        isRestDay: true
                    )
                    week.scheduledWorkouts.append(restDay)
                }
            }
            
            programWeeks.append(week)
        }
    }
}