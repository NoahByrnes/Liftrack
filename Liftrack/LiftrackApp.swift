//
//  LiftrackApp.swift
//  Liftrack
//
//  Created by Noah Grant-Byrnes on 2025-08-14.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@main
struct LiftrackApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    init() {
        // Clear any corrupt data first
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storePath = documentsPath.appendingPathComponent("default.store")
        
        // Try removing the old store if it exists
        try? FileManager.default.removeItem(at: storePath)
        
        print("Cleared old data store at: \(storePath)")
    }
    
    var sharedModelContainer: ModelContainer = {
        // Start with just the core models
        do {
            let container = try ModelContainer(for:
                Exercise.self,
                WorkoutSession.self,
                SessionExercise.self,
                WorkoutSet.self
            )
            
            print("✅ Basic ModelContainer created successfully")
            
            // Try adding template models
            do {
                let fullContainer = try ModelContainer(for:
                    Exercise.self,
                    WorkoutSession.self,
                    SessionExercise.self,
                    WorkoutSet.self,
                    WorkoutTemplate.self,
                    WorkoutExercise.self,
                    TemplateSet.self,
                    Program.self,
                    ProgramWeek.self,
                    ProgramWorkout.self
                )
                print("✅ Full ModelContainer created successfully")
                return fullContainer
            } catch {
                print("⚠️ Could not create full container, using basic: \(error)")
                return container
            }
        } catch {
            print("❌ ModelContainer Error Details:")
            print("Error: \(error)")
            print("LocalizedDescription: \(error.localizedDescription)")
            
            // Last resort - in-memory only
            do {
                let memoryContainer = try ModelContainer(
                    for: Exercise.self, WorkoutSession.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
                print("⚠️ Using in-memory container as fallback")
                return memoryContainer
            } catch {
                fatalError("Could not even create in-memory container: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
