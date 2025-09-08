import Foundation
import SwiftData

struct DataSeeder {
    private static let hasSeededKey = "HasSeededInitialExercises"
    
    static func seedExercisesIfNeeded(context: ModelContext) {
        // Quick check if we've already seeded
        if UserDefaults.standard.bool(forKey: hasSeededKey) {
            return
        }
        
        let fetchDescriptor = FetchDescriptor<Exercise>()
        
        do {
            let existingExercises = try context.fetch(fetchDescriptor)
            if existingExercises.isEmpty {
                seedInitialExercises(context: context)
                UserDefaults.standard.set(true, forKey: hasSeededKey)
            } else {
                // Mark as seeded if we have exercises
                UserDefaults.standard.set(true, forKey: hasSeededKey)
            }
        } catch {
            print("Error checking for existing exercises: \(error)")
        }
    }
    
    private static func seedInitialExercises(context: ModelContext) {
        let exercises = [
            // Chest
            "Bench Press (Barbell)",
            "Bench Press (Dumbbell)",
            "Incline Bench Press (Barbell)",
            "Incline Bench Press (Dumbbell)",
            "Chest Fly (Machine)",
            "Chest Fly (Dumbbell)",
            "Push Up",
            
            // Back
            "Lat Pulldown",
            "Pull Up",
            "Bent Over Row (Barbell)",
            "Bent Over Row (Dumbbell)",
            "Seated Cable Row",
            "T-Bar Row",
            "Romanian Deadlift (Barbell)",
            "Deadlift",
            
            // Shoulders
            "Shoulder Press (Dumbbell)",
            "Shoulder Press (Barbell)",
            "Lateral Raise",
            "Front Raise",
            "Rear Delt Fly (Machine)",
            "Face Pull",
            
            // Arms
            "Bicep Curl (EZ Bar)",
            "Bicep Curl (Barbell)",
            "Hammer Curl",
            "Concentration Curl",
            "Preacher Curl",
            "Tricep Pushdown (Cable)",
            "Overhead Tricep Extension",
            "Tricep Dips",
            
            // Legs
            "Squat (Barbell)",
            "Front Squat",
            "Leg Press",
            "Leg Extension",
            "Leg Curl",
            "Romanian Deadlift (Dumbbell)",
            "Walking Lunges",
            "Bulgarian Split Squat",
            "Calf Raise",
            "Seated Calf Raise"
        ]
        
        for exerciseName in exercises {
            let exercise = Exercise(name: exerciseName)
            context.insert(exercise)
        }
        
        do {
            try context.save()
            print("Successfully seeded \(exercises.count) exercises")
        } catch {
            print("Error seeding exercises: \(error)")
        }
    }
}