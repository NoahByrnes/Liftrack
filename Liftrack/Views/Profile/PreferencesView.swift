import SwiftUI

struct PreferencesView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Appearance Mode
                VStack(alignment: .leading, spacing: 12) {
                    Label("Appearance", systemImage: "moon.circle.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Button(action: {
                                settings.appearanceMode = mode
                                settings.impactFeedback()
                            }) {
                                HStack {
                                    Image(systemName: iconForMode(mode))
                                        .font(.system(size: 20))
                                        .foregroundColor(settings.appearanceMode == mode ? settings.accentColor.color : .secondary)
                                        .frame(width: 30)
                                    
                                    Text(mode.rawValue)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if settings.appearanceMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(settings.accentColor.color)
                                    }
                                }
                                .padding()
                                .background(
                                    settings.appearanceMode == mode ?
                                    settings.accentColor.color.opacity(0.1) :
                                    Color.clear
                                )
                            }
                            
                            if mode != AppearanceMode.allCases.last {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Accent Color
                VStack(alignment: .leading, spacing: 12) {
                    Label("Accent Color", systemImage: "paintpalette.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(AccentColor.allCases, id: \.self) { color in
                            Button(action: {
                                settings.accentColor = color
                                settings.impactFeedback()
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 60, height: 60)
                                        
                                        if settings.accentColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                    }
                                    
                                    Text(color.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Display Options
                VStack(alignment: .leading, spacing: 12) {
                    Label("Display Options", systemImage: "textformat.size")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        Toggle(isOn: $settings.useLargerText) {
                            HStack {
                                Image(systemName: "textformat.size")
                                    .frame(width: 30)
                                    .foregroundColor(.blue)
                                Text("Use Larger Text")
                            }
                        }
                        .padding()
                        .tint(settings.accentColor.color)
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        Toggle(isOn: $settings.useAnimations) {
                            HStack {
                                Image(systemName: "wand.and.rays")
                                    .frame(width: 30)
                                    .foregroundColor(.orange)
                                Text("Enable Animations")
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
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconForMode(_ mode: AppearanceMode) -> String {
        switch mode {
        case .system:
            return "gear"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}