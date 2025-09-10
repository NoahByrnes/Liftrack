import SwiftUI

struct PreferencesView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    AppearanceModeSection()
                    AccentColorSection()
                    DisplayOptionsSection()
                    
                    // Add bottom padding to clear tab bar
                    Color.clear.frame(height: DesignConstants.Spacing.tabBarClearance)
                }
                .padding()
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance Mode Section
struct AppearanceModeSection: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Appearance", systemImage: "moon.circle.fill")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    AppearanceModeRow(mode: mode)
                }
            }
        }
    }
}

struct AppearanceModeRow: View {
    let mode: AppearanceMode
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: settings.appearanceMode == mode ?
                            [settings.accentColor.color.opacity(0.6), settings.accentColor.color.opacity(0.2)] :
                            [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(settings.appearanceMode == mode ?
                            settings.accentColor.color.opacity(0.1) :
                            Color.white.opacity(0.05))
                )
                .overlay(
                    Image(systemName: iconForMode(mode))
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                )
            
            Text(mode.rawValue)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            if settings.appearanceMode == mode {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(settings.accentColor.color)
                    .font(.system(size: 20))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: settings.appearanceMode == mode ?
                            [settings.accentColor.color.opacity(0.3), settings.accentColor.color.opacity(0.1)] :
                            [.white.opacity(0.15), .white.opacity(0.05)],
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
        .onTapGesture {
            settings.appearanceMode = mode
            settings.impactFeedback()
        }
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

// MARK: - Accent Color Section
struct AccentColorSection: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accent Color", systemImage: "paintpalette.fill")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                ForEach(AccentColor.allCases, id: \.self) { color in
                    AccentColorButton(color: color)
                }
            }
            .padding()
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
    }
}

struct AccentColorButton: View {
    let color: AccentColor
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: settings.accentColor == color ?
                            [color.color, color.color.opacity(0.5)] :
                            [color.color.opacity(0.6), color.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: settings.accentColor == color ? 3 : 1.5
                )
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.color.opacity(settings.accentColor == color ? 0.2 : 0.1))
                )
                .overlay(
                    settings.accentColor == color ?
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                    : nil
                )
            
            Text(color.rawValue)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .onTapGesture {
            settings.accentColor = color
            settings.impactFeedback()
        }
    }
}

// MARK: - Display Options Section
struct DisplayOptionsSection: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Display Options", systemImage: "textformat.size")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                DisplayToggleRow(
                    icon: "textformat.size",
                    title: "Use Larger Text",
                    isOn: $settings.useLargerText,
                    iconColor: .blue
                )
                
                DisplayToggleRow(
                    icon: "wand.and.rays",
                    title: "Enable Animations",
                    isOn: $settings.useAnimations,
                    iconColor: .orange
                )
                
                DisplayToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Haptic Feedback",
                    isOn: $settings.useHaptics,
                    iconColor: .green
                )
            }
        }
    }
}

struct DisplayToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let iconColor: Color
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [iconColor.opacity(0.4), iconColor.opacity(0.1)],
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
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                )
            
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(settings.accentColor.color)
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
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}