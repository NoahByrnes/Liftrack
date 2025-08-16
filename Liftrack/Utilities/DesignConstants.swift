import SwiftUI

/// Centralized design constants for consistent UI across the app
enum DesignConstants {
    
    // MARK: - Spacing
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let tabBarClearance: CGFloat = 100 // Space to clear the tab bar
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 10
        static let xLarge: CGFloat = 12
        static let card: CGFloat = 16
        static let button: CGFloat = 20
    }
    
    // MARK: - Icons
    enum Icons {
        static let delete = "trash.circle.fill"
        static let add = "plus.circle.fill"
        static let timer = "timer"
        static let check = "checkmark.circle.fill"
        static let uncheck = "circle"
        static let close = "xmark"
        static let menu = "line.3.horizontal"
        static let chevronDown = "chevron.up.chevron.down"
    }
    
    // MARK: - Colors
    enum Colors {
        static func deleteRed(opacity: Double = 0.6) -> Color {
            Color.red.opacity(opacity)
        }
        
        static func completedGreen() -> Color {
            Color.green
        }
        
        static func cardBackground() -> Color {
            Color(.systemGray6).opacity(0.5)
        }
        
        static func separatorColor() -> Color {
            Color(.systemGray4).opacity(0.2)
        }
    }
    
    // MARK: - Animation
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
    
    // MARK: - Haptic Styles
    enum Haptic {
        static let lightImpact = UIImpactFeedbackGenerator.FeedbackStyle.light
        static let mediumImpact = UIImpactFeedbackGenerator.FeedbackStyle.medium
        static let heavyImpact = UIImpactFeedbackGenerator.FeedbackStyle.heavy
        
        static let success = UINotificationFeedbackGenerator.FeedbackType.success
        static let warning = UINotificationFeedbackGenerator.FeedbackType.warning
        static let error = UINotificationFeedbackGenerator.FeedbackType.error
    }
    
    // MARK: - Font Sizes
    enum FontSize {
        static let caption: CGFloat = 10
        static let footnote: CGFloat = 12
        static let body: CGFloat = 14
        static let callout: CGFloat = 16
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }
}

// MARK: - View Modifiers
extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self
            .padding(DesignConstants.Spacing.small)
            .background(DesignConstants.Colors.cardBackground())
            .cornerRadius(DesignConstants.CornerRadius.large)
    }
    
    /// Apply standard button styling
    func primaryButtonStyle(color: Color? = nil) -> some View {
        self
            .foregroundColor(.white)
            .padding(DesignConstants.Spacing.medium)
            .background(color ?? SettingsManager.shared.accentColor.color)
            .cornerRadius(DesignConstants.CornerRadius.button)
    }
    
    /// Apply secondary button styling
    func secondaryButtonStyle(color: Color? = nil) -> some View {
        self
            .foregroundColor(color ?? SettingsManager.shared.accentColor.color)
            .padding(DesignConstants.Spacing.medium)
            .background((color ?? SettingsManager.shared.accentColor.color).opacity(0.1))
            .cornerRadius(DesignConstants.CornerRadius.button)
    }
}