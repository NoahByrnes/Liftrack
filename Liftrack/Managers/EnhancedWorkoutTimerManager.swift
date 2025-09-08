import Foundation
import SwiftUI
import UserNotifications
import AVFoundation
import AudioToolbox
import ActivityKit
#if canImport(UIKit)
import UIKit
#endif

class EnhancedWorkoutTimerManager: ObservableObject {
    static let shared = EnhancedWorkoutTimerManager()
    
    @Published var elapsedTime: Int = 0
    @Published var isRunning: Bool = false
    @Published var restTimeRemaining: Int = 0
    @Published var restProgress: CGFloat = 1.0
    @Published var showRestBar: Bool = false
    @Published var isMinimized: Bool = false
    @Published var currentExerciseName: String = ""
    @Published var workoutName: String = ""
    @Published var restTotalDuration: Int = 0
    
    private var workoutTimer: Timer?
    private var restTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var workoutStartTime: Date?
    private var restStartTime: Date?
    private var restDuration: Int = 0
    private var audioPlayer: AVAudioPlayer?
    private var hasPlayedThreeSecond = false
    private var hasPlayedTwoSecond = false
    private var hasPlayedOneSecond = false
    private var liveActivity: Activity<WorkoutActivityAttributes>?
    
    // UserDefaults keys for persistence
    private let workoutStartTimeKey = "WorkoutStartTime"
    private let isRunningKey = "WorkoutTimerIsRunning"
    private let restStartTimeKey = "RestStartTime"
    private let restDurationKey = "RestDuration"
    private let showRestBarKey = "ShowRestBar"
    
    private init() {
        setupNotifications()
        setupAppLifecycleObservers()
        // Restore timer state (this will kill old Live Activities and restart fresh)
        restoreTimerState()
        // Don't sync with existing Live Activities - we're starting fresh
        // syncWithExistingLiveActivity()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // Configure audio session for background audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
        
        // Set up notification categories with actions
        let skipAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "Skip",
            options: []
        )
        
        let addTimeAction = UNNotificationAction(
            identifier: "ADD_TIME_ACTION",
            title: "+30s",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "REST_TIMER",
            actions: [skipAction, addTimeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Request authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if granted {
                print("Notification permission granted")
                // Check if we can use critical alerts
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    print("Critical alerts authorized: \(settings.criticalAlertSetting == .enabled)")
                    print("Sound authorized: \(settings.soundSetting == .enabled)")
                    print("Alert authorized: \(settings.alertSetting == .enabled)")
                }
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupAppLifecycleObservers() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #endif
    }
    
    // MARK: - App Lifecycle
    
    @objc private func appWillResignActive() {
        saveTimerState()
    }
    
    @objc private func appDidBecomeActive() {
        // Restore timer state (kills old Live Activities and starts fresh)
        restoreTimerState()
        // Don't sync - we're starting fresh to avoid conflicts
        // syncWithExistingLiveActivity()
        // Clear any delivered notifications when app becomes active
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    @objc private func appDidEnterBackground() {
        saveTimerState()
        
        #if os(iOS)
        // Start background task to keep timers running briefly
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Schedule notification for rest timer if active
        if showRestBar && restTimeRemaining > 0 {
            scheduleRestTimerNotification()
        }
        #endif
    }
    
    private func endBackgroundTask() {
        #if os(iOS)
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        #endif
    }
    
    // MARK: - State Persistence
    
    private func saveTimerState() {
        UserDefaults.standard.set(isRunning, forKey: isRunningKey)
        UserDefaults.standard.set(showRestBar, forKey: showRestBarKey)
        
        if isRunning, let startTime = workoutStartTime {
            UserDefaults.standard.set(startTime, forKey: workoutStartTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: workoutStartTimeKey)
        }
        
        if showRestBar, let restStart = restStartTime {
            UserDefaults.standard.set(restStart, forKey: restStartTimeKey)
            UserDefaults.standard.set(restDuration, forKey: restDurationKey)
        } else {
            UserDefaults.standard.removeObject(forKey: restStartTimeKey)
            UserDefaults.standard.removeObject(forKey: restDurationKey)
        }
    }
    
    private func restoreTimerState() {
        // First, kill any existing Live Activities to avoid conflicts
        Task { @MainActor in
            for activity in Activity<WorkoutActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        
        // Restore workout timer
        if UserDefaults.standard.bool(forKey: isRunningKey),
           let startTime = UserDefaults.standard.object(forKey: workoutStartTimeKey) as? Date {
            
            let elapsed = Int(Date().timeIntervalSince(startTime))
            elapsedTime = elapsed
            workoutStartTime = startTime
            isRunning = true
            
            // Restart the timer
            workoutTimer?.invalidate()
            workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.elapsedTime = Int(Date().timeIntervalSince(startTime))
            }
        }
        
        // Restore rest timer
        if UserDefaults.standard.bool(forKey: showRestBarKey),
           let restStart = UserDefaults.standard.object(forKey: restStartTimeKey) as? Date {
            
            let duration = UserDefaults.standard.integer(forKey: restDurationKey)
            let elapsed = Int(Date().timeIntervalSince(restStart))
            let remaining = max(0, duration - elapsed)
            
            if remaining > 0 {
                // Instead of restoring old state, start fresh timer with remaining time
                // This avoids conflicts with Live Activity
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.startRestTimer(seconds: remaining)
                }
            } else {
                // Timer expired while app was closed
                showRestBar = false
                UserDefaults.standard.removeObject(forKey: restStartTimeKey)
                UserDefaults.standard.removeObject(forKey: restDurationKey)
                UserDefaults.standard.set(false, forKey: showRestBarKey)
            }
        }
    }
    
    // MARK: - Live Activity Management
    
    private func syncWithExistingLiveActivity() {
        // Check for any existing Live Activities and sync with them
        Task { @MainActor in
            for activity in Activity<WorkoutActivityAttributes>.activities {
                print("Found existing Live Activity: \(activity.id)")
                
                // If we have an active rest timer, keep the activity reference
                // but DON'T update it to avoid conflicts with its countdown
                if showRestBar && restTimeRemaining > 0 {
                    self.liveActivity = activity
                    print("Synced with existing Live Activity for active rest timer")
                    // Don't update here - let the timer's own countdown continue
                } else {
                    // No active rest timer, end the stale activity
                    await activity.end(dismissalPolicy: .immediate)
                    print("Ended stale Live Activity (no active rest timer)")
                    self.liveActivity = nil
                }
                break // Only handle the first one
            }
        }
    }
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // Don't start a new activity if one already exists
        guard liveActivity == nil else {
            print("Live Activity already exists, updating instead")
            updateLiveActivity()
            return
        }
        
        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName.isEmpty ? "Workout" : workoutName,
            startTime: Date()
        )
        
        let initialState = WorkoutActivityAttributes.ContentState(
            currentExercise: currentExerciseName.isEmpty ? "Rest Period" : currentExerciseName,
            restTimeRemaining: restTimeRemaining,
            totalElapsedTime: elapsedTime,
            isResting: true,
            restEndTime: restTimeRemaining > 0 ? Date().addingTimeInterval(TimeInterval(restTimeRemaining)) : nil
        )
        
        do {
            let activity = try Activity<WorkoutActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.liveActivity = activity
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }
        
        Task {
            // Determine if we're actually resting (rest timer active with time remaining)
            let isActuallyResting = showRestBar && restTimeRemaining > 0
            
            let updatedState = WorkoutActivityAttributes.ContentState(
                currentExercise: currentExerciseName.isEmpty ? "Active" : currentExerciseName,
                restTimeRemaining: isActuallyResting ? restTimeRemaining : 0,
                totalElapsedTime: elapsedTime,
                isResting: isActuallyResting,
                restEndTime: isActuallyResting ? Date().addingTimeInterval(TimeInterval(restTimeRemaining)) : nil
            )
            
            await activity.update(.init(state: updatedState, staleDate: nil))
            
            print("Updated Live Activity - Resting: \(isActuallyResting), Rest Time: \(restTimeRemaining), Total Time: \(elapsedTime)")
        }
    }
    
    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        
        Task {
            // End immediately without showing "Workout Complete"
            await activity.end(dismissalPolicy: .immediate)
            self.liveActivity = nil
            print("Ended Live Activity")
        }
    }
    
    // MARK: - Workout Timer
    
    func startWorkoutTimer() {
        guard !isRunning else { return }
        isRunning = true
        workoutStartTime = Date()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = self.workoutStartTime {
                self.elapsedTime = Int(Date().timeIntervalSince(startTime))
            }
        }
        
        saveTimerState()
        // Don't start Live Activity here - only start it during rest
    }
    
    func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        isRunning = false
        workoutStartTime = nil
        saveTimerState()
        // Don't end Live Activity here - only manage it during rest periods
    }
    
    func resetWorkoutTimer() {
        stopWorkoutTimer()
        elapsedTime = 0
    }
    
    // MARK: - Rest Timer
    
    func startRestTimer(seconds: Int) {
        restTimeRemaining = seconds
        restDuration = seconds
        restTotalDuration = seconds
        restProgress = 1.0
        restStartTime = Date()
        
        // Reset countdown flags
        hasPlayedThreeSecond = false
        hasPlayedTwoSecond = false
        hasPlayedOneSecond = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestBar = true
        }
        
        // Start Live Activity when rest timer starts (if not already active)
        if liveActivity == nil {
            startLiveActivity()
        } else {
            // Just update the existing one
            updateLiveActivity()
        }
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.restStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, Double(self.restDuration) - elapsed)
                self.restTimeRemaining = Int(ceil(remaining))
                
                // Calculate progress as a smooth value
                if self.restDuration > 0 {
                    self.restProgress = CGFloat(remaining) / CGFloat(self.restDuration)
                } else {
                    self.restProgress = 0
                }
                
                // Play countdown sounds/haptics at 3, 2, 1
                if remaining <= 3.1 && remaining > 3.0 && !self.hasPlayedThreeSecond {
                    self.hasPlayedThreeSecond = true
                    self.playCountdownPulse(secondsRemaining: 3)
                } else if remaining <= 2.1 && remaining > 2.0 && !self.hasPlayedTwoSecond {
                    self.hasPlayedTwoSecond = true
                    self.playCountdownPulse(secondsRemaining: 2)
                } else if remaining <= 1.1 && remaining > 1.0 && !self.hasPlayedOneSecond {
                    self.hasPlayedOneSecond = true
                    self.playCountdownPulse(secondsRemaining: 1)
                }
                
                // Timer complete
                if remaining <= 0 {
                    self.endRestTimer()
                    self.playRestTimerCompleteSound()
                }
                
                // Update Live Activity every second during rest
                self.updateLiveActivity()
            }
        }
        
        saveTimerState()
        
        // Cancel any existing notifications and schedule new one
        cancelRestTimerNotification()
        if seconds > 0 {
            scheduleRestTimerNotification()
        }
    }
    
    func endRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restStartTime = nil
        restDuration = 0
        restTotalDuration = 0
        restTimeRemaining = 0
        restProgress = 1.0
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestBar = false
        }
        
        cancelRestTimerNotification()
        saveTimerState()
        
        // End Live Activity when rest timer ends
        endLiveActivity()
    }
    
    func adjustRestTime(by seconds: Int) {
        guard restTimeRemaining > 0 else { return }
        
        // Calculate new duration and time
        let newRemaining = max(0, restTimeRemaining + seconds)
        
        // If adjusting would end the timer, just end it
        if newRemaining == 0 {
            endRestTimer()
            return
        }
        
        // Kill everything and restart with new time
        // This is the only way to ensure Live Activity syncs properly
        
        // 1. End the current Live Activity completely
        if liveActivity != nil {
            Task {
                await liveActivity?.end(dismissalPolicy: .immediate)
                liveActivity = nil
            }
        }
        
        // 2. Cancel current timer
        restTimer?.invalidate()
        
        // 3. Restart with new duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.startRestTimer(seconds: newRemaining)
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleRestTimerNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest Timer Complete!"
        content.body = "Time to get back to work! 💪"
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "REST_TIMER"
        content.interruptionLevel = .timeSensitive
        
        // Add action buttons
        content.userInfo = ["type": "rest_timer"]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(restTimeRemaining),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "rest_timer_complete",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Rest timer notification scheduled for \(self.restTimeRemaining) seconds")
            }
        }
    }
    
    private func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["rest_timer_complete"]
        )
    }
    
    private func playCountdownPulse(secondsRemaining: Int) {
        #if os(iOS)
        // Play different intensity haptics based on countdown
        switch secondsRemaining {
        case 3:
            // Light tap for 3 seconds
            SettingsManager.shared.impactFeedback(style: .light)
            AudioServicesPlaySystemSound(1519) // Light tick sound
        case 2:
            // Medium tap for 2 seconds
            SettingsManager.shared.impactFeedback(style: .medium)
            AudioServicesPlaySystemSound(1520) // Medium tick sound
        case 1:
            // Heavy tap for 1 second
            SettingsManager.shared.impactFeedback(style: .heavy)
            AudioServicesPlaySystemSound(1521) // Heavy tick sound
        default:
            break
        }
        
        // Also play a system sound for audio feedback
        AudioServicesPlaySystemSound(1103) // Short beep
        #endif
    }
    
    private func playRestTimerCompleteSound() {
        #if os(iOS)
        // Triple heavy haptic feedback for strong finish
        DispatchQueue.main.async {
            SettingsManager.shared.impactFeedback(style: .heavy)
            SettingsManager.shared.notificationFeedback(type: .success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SettingsManager.shared.impactFeedback(style: .heavy)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            SettingsManager.shared.impactFeedback(style: .heavy)
        }
        
        // Play multiple system sounds for completion
        AudioServicesPlaySystemSound(1005) // Timer complete sound
        AudioServicesPlaySystemSound(1013) // Positive sound
        AudioServicesPlaySystemSound(1025) // Alert sound
        
        // Strong vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // If app is in foreground, play even more sounds
        if UIApplication.shared.applicationState == .active {
            // Play the loudest available sounds
            AudioServicesPlaySystemSound(1315) // Loud notification
            AudioServicesPlaySystemSound(1336) // Alert received
            
            // Double vibration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            
            // Schedule a local notification immediately for in-app alert
            let content = UNMutableNotificationContent()
            content.title = "Rest Complete!"
            content.body = "Time for your next set! 💪"
            content.sound = UNNotificationSound.defaultCritical
            content.interruptionLevel = .timeSensitive
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "rest_timer_immediate",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing immediate notification: \(error)")
                }
            }
        }
        #endif
    }
    
    // MARK: - Public Methods for Exercise Updates
    
    func updateCurrentExercise(_ exerciseName: String) {
        currentExerciseName = exerciseName
        updateLiveActivity()
    }
    
    func updateWorkoutName(_ name: String) {
        workoutName = name
        // If activity is already running, we can't update static attributes,
        // but we can include it in the next state update
        updateLiveActivity()
    }
    
    // MARK: - Cleanup
    
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
        workoutStartTime = nil
        restStartTime = nil
        restDuration = 0
        restTotalDuration = 0
        currentExerciseName = ""
        workoutName = ""
        
        // Clear persistence
        UserDefaults.standard.removeObject(forKey: workoutStartTimeKey)
        UserDefaults.standard.removeObject(forKey: isRunningKey)
        UserDefaults.standard.removeObject(forKey: restStartTimeKey)
        UserDefaults.standard.removeObject(forKey: restDurationKey)
        UserDefaults.standard.removeObject(forKey: showRestBarKey)
        
        // Cancel notifications
        cancelRestTimerNotification()
        
        // End Live Activity
        endLiveActivity()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}