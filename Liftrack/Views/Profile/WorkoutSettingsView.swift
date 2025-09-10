import SwiftUI
import UIKit
import UserNotifications
import ActivityKit

struct WorkoutSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @AppStorage("defaultRestTime") private var defaultRestTime = 90
    @AppStorage("autoStartTimer") private var autoStartTimer = false
    @AppStorage("soundEffects") private var soundEffects = true
    @AppStorage("restTimerNotifications") private var restTimerNotifications = true
    @AppStorage("restTimerCountdown") private var restTimerCountdown = true
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    @AppStorage("autoSelectTextFields") private var autoSelectTextFields = true
    @AppStorage("requireEditModeForDelete") private var requireEditModeForDelete = true
    @AppStorage("showPreviousWeights") private var showPreviousWeights = true
    @AppStorage("show1RMEstimates") private var show1RMEstimates = true
    
    @State private var notificationsEnabled = false
    @State private var liveActivitiesAvailable = false
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                // Units Settings
                VStack(alignment: .leading, spacing: 12) {
                    Label("Units", systemImage: "scalemass.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.indigo.opacity(0.4), Color.indigo.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                Image(systemName: "scalemass")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                            )
                        
                        Text("Weight Unit")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Picker("", selection: $settings.preferredWeightUnit) {
                            Text("Pounds (lbs)").tag("lbs")
                            Text("Kilograms (kg)").tag("kg")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.15), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial.opacity(0.3))
                            )
                    )
                }
                
                // Timer Settings
                VStack(alignment: .leading, spacing: 12) {
                    Label("Timer Settings", systemImage: "timer")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $settings.showRestTimerAutomatically) {
                            HStack {
                                Image(systemName: "timer")
                                    .frame(width: 30)
                                    .foregroundColor(.purple)
                                Text("Auto-show Rest Timer")
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $autoStartTimer) {
                            HStack {
                                Image(systemName: "play.circle")
                                    .frame(width: 30)
                                    .foregroundColor(.green)
                                Text("Auto-start Workout Timer")
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        HStack {
                            Image(systemName: "clock")
                                .frame(width: 30)
                                .foregroundColor(.blue)
                            
                            Text("Default Rest Time")
                            
                            Spacer()
                            
                            Picker("", selection: $defaultRestTime) {
                                Text("30s").tag(30)
                                Text("45s").tag(45)
                                Text("60s").tag(60)
                                Text("90s").tag(90)
                                Text("2m").tag(120)
                                Text("3m").tag(180)
                            }
                            .pickerStyle(.menu)
                            .tint(settings.accentColor.color)
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Notifications & Live Activities
                VStack(alignment: .leading, spacing: 12) {
                    Label("Notifications & Activities", systemImage: "bell.badge.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $restTimerNotifications) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .frame(width: 30)
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rest Timer Notifications")
                                    if !notificationsEnabled {
                                        Text("Enable in Settings > Notifications")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        .disabled(!notificationsEnabled)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $liveActivitiesEnabled) {
                            HStack {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .frame(width: 30)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Live Activities")
                                    Text("Shows rest timer in Dynamic Island")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        .disabled(!liveActivitiesAvailable)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Sound & Feedback Settings
                VStack(alignment: .leading, spacing: 12) {
                    Label("Sound & Feedback", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $soundEffects) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .frame(width: 30)
                                    .foregroundColor(.orange)
                                Text("Sound Effects")
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $restTimerCountdown) {
                            HStack {
                                Image(systemName: "metronome.fill")
                                    .frame(width: 30)
                                    .foregroundColor(.indigo)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rest Timer Countdown")
                                    Text("3-2-1 countdown with haptics")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $settings.useHaptics) {
                            HStack {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .frame(width: 30)
                                    .foregroundColor(.green)
                                Text("Haptic Feedback")
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Workout Interface Settings
                VStack(alignment: .leading, spacing: 12) {
                    Label("Workout Interface", systemImage: "rectangle.and.pencil.and.ellipsis")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $autoSelectTextFields) {
                            HStack {
                                Image(systemName: "text.cursor")
                                    .frame(width: 30)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-Select Text Fields")
                                    Text("Selects all text when tapped")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $requireEditModeForDelete) {
                            HStack {
                                Image(systemName: "trash.slash")
                                    .frame(width: 30)
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Require Edit Mode")
                                    Text("Safer deletion of sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $showPreviousWeights) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .frame(width: 30)
                                    .foregroundColor(.teal)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show Previous Weights")
                                    Text("Display last workout data")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $show1RMEstimates) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .frame(width: 30)
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show 1RM Estimates")
                                    Text("Display estimated one-rep max")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Add bottom padding to clear tab bar
                Color.clear.frame(height: DesignConstants.Spacing.tabBarClearance)
            }
            .padding()
        }
        .navigationTitle("Workout Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
            checkLiveActivitiesAvailability()
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func checkLiveActivitiesAvailability() {
        if #available(iOS 16.2, *) {
            liveActivitiesAvailable = ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            liveActivitiesAvailable = false
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutSettingsView()
    }
}