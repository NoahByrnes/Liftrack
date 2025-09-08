import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AccentColor: String, CaseIterable {
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case pink = "Pink"
    case red = "Red"
    case teal = "Teal"
    
    var color: Color {
        switch self {
        case .purple:
            return .purple
        case .blue:
            return .blue
        case .green:
            return .green
        case .orange:
            return .orange
        case .pink:
            return .pink
        case .red:
            return .red
        case .teal:
            return .teal
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("appearanceMode") var appearanceModeString: String = AppearanceMode.system.rawValue {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("accentColor") var accentColorString: String = AccentColor.purple.rawValue {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("useHaptics") var useHaptics: Bool = true
    @AppStorage("useAnimations") var useAnimations: Bool = true
    @AppStorage("useLargerText") var useLargerText: Bool = false
    @AppStorage("showRestTimerAutomatically") var showRestTimerAutomatically: Bool = true
    
    // Profile settings
    @AppStorage("userDisplayName") var userDisplayName: String = ""
    @AppStorage("profileImageData") var profileImageData: Data = Data()
    @AppStorage("preferredWeightUnit") var preferredWeightUnit: String = "lbs"
    @AppStorage("lastUsedGreetingIndices") var lastUsedGreetingIndicesData: Data = Data()
    @AppStorage("currentGreetingIndex") var currentGreetingIndex: Int = -1
    
    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeString) ?? .system }
        set { appearanceModeString = newValue.rawValue }
    }
    
    var accentColor: AccentColor {
        get { AccentColor(rawValue: accentColorString) ?? .purple }
        set { accentColorString = newValue.rawValue }
    }
    
    var lastUsedGreetingIndices: [Int] {
        get {
            guard !lastUsedGreetingIndicesData.isEmpty else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: lastUsedGreetingIndicesData)) ?? []
        }
        set {
            lastUsedGreetingIndicesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    #if os(iOS)
    func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if useHaptics {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
    
    func notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        if useHaptics {
            UINotificationFeedbackGenerator().notificationOccurred(type)
        }
    }
    #else
    func impactFeedback(style: Int = 0) {
        // Haptic feedback not available on macOS
    }
    
    func notificationFeedback(type: Int) {
        // Haptic feedback not available on macOS
    }
    #endif
}