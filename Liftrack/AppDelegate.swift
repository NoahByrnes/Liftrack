import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications authorized")
            }
        }
        
        // Register for background refresh
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.liftrack.refresh", using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Reset the current greeting index so a new one is selected on next launch
        SettingsManager.shared.currentGreetingIndex = -1
        
        // Request extra time when entering background
        backgroundTask = application.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Schedule background refresh
        scheduleBackgroundRefresh()
        
        // Keep the app alive longer if there's an active workout
        if EnhancedWorkoutTimerManager.shared.isRunning {
            // The timer manager already handles its own background task
            // This is just extra insurance
            print("Active workout detected, maintaining background task")
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // End background task when returning to foreground
        endBackgroundTask()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Reset the current greeting index so a new one is selected on next launch
        SettingsManager.shared.currentGreetingIndex = -1
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        // Reset greeting index when memory warning received (app might be terminated)
        SettingsManager.shared.currentGreetingIndex = -1
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.liftrack.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next background refresh
        scheduleBackgroundRefresh()
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "SKIP_ACTION":
            // Handle skip action
            EnhancedWorkoutTimerManager.shared.endRestTimer()
            
        case "ADD_TIME_ACTION":
            // Add 30 seconds to timer
            EnhancedWorkoutTimerManager.shared.adjustRestTime(by: 30)
            
        default:
            break
        }
        
        completionHandler()
    }
}