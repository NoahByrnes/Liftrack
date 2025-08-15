import SwiftUI

struct WorkoutSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @AppStorage("defaultRestTime") private var defaultRestTime = 90
    @AppStorage("autoStartTimer") private var autoStartTimer = false
    @AppStorage("soundEffects") private var soundEffects = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Sound Settings
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
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workout Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WorkoutSettingsView()
    }
}