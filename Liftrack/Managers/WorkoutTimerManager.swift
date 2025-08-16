import Foundation
import SwiftUI

class WorkoutTimerManager: ObservableObject {
    static let shared = WorkoutTimerManager()
    
    @Published var elapsedTime: Int = 0
    @Published var isRunning: Bool = false
    @Published var restTimeRemaining: Int = 0
    @Published var showRestBar: Bool = false
    @Published var isMinimized: Bool = false
    
    private var workoutTimer: Timer?
    private var restTimer: Timer?
    
    private init() {}
    
    func startWorkoutTimer() {
        guard !isRunning else { return }
        isRunning = true
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedTime += 1
        }
    }
    
    func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        isRunning = false
    }
    
    func resetWorkoutTimer() {
        stopWorkoutTimer()
        elapsedTime = 0
    }
    
    func startRestTimer(seconds: Int) {
        restTimeRemaining = seconds
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestBar = true
        }
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
            } else {
                self.endRestTimer()
            }
        }
    }
    
    func endRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestBar = false
        }
    }
    
    func adjustRestTime(by seconds: Int) {
        restTimeRemaining = max(0, restTimeRemaining + seconds)
    }
    
    func cleanup() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        restTimer = nil
        elapsedTime = 0
        restTimeRemaining = 0
        isRunning = false
        showRestBar = false
        isMinimized = false
    }
}