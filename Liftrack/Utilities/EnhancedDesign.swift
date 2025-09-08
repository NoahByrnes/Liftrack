import SwiftUI

// MARK: - Enhanced Design System
struct EnhancedDesign {
    
    // MARK: - Animation Constants
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.65)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let interactive = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Shadows
    struct Shadow {
        static func small(_ color: Color = .black) -> some View {
            return color.opacity(0.08)
                .blur(radius: 8)
                .offset(y: 2)
        }
        
        static func medium(_ color: Color = .black) -> some View {
            return color.opacity(0.12)
                .blur(radius: 16)
                .offset(y: 4)
        }
        
        static func large(_ color: Color = .black) -> some View {
            return color.opacity(0.15)
                .blur(radius: 24)
                .offset(y: 8)
        }
        
        static func glow(_ color: Color) -> some View {
            return color.opacity(0.3)
                .blur(radius: 20)
        }
    }
    
    // MARK: - Gradients
    struct Gradient {
        static func subtle(_ color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color, color.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        static func vibrant(_ color: Color) -> LinearGradient {
            LinearGradient(
                colors: [color.opacity(0.9), color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        static func radial(_ color: Color) -> RadialGradient {
            RadialGradient(
                colors: [color.opacity(0.3), color.opacity(0.05)],
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        }
        
        static let shimmer = LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Blur Effects
    struct Blur {
        static let subtle: CGFloat = 2
        static let medium: CGFloat = 8
        static let strong: CGFloat = 20
        static let background: CGFloat = 50
    }
}

// MARK: - View Extensions for Enhanced Design
extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    func glassEffect(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                ZStack {
                    Color(.systemBackground).opacity(0.8)
                    Color(.systemGray6).opacity(0.3)
                }
                .blur(radius: 0.5)
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    func shimmerEffect(isActive: Bool = true) -> some View {
        self.overlay(
            GeometryReader { geometry in
                if isActive {
                    EnhancedDesign.Gradient.shimmer
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width * 2)
                        .animation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false),
                            value: isActive
                        )
                        .offset(x: isActive ? geometry.size.width * 2 : -geometry.size.width * 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
    
    func scaleOnTap(scale: CGFloat = 0.98) -> some View {
        self.scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scale)
    }
    
    func bounceEffect(trigger: Bool) -> some View {
        self
            .scaleEffect(trigger ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: trigger)
    }
    
    func pulseEffect(isPulsing: Bool = true) -> some View {
        self
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
    }
}

// MARK: - Custom Button Styles
struct PressableButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    let isPressed: Bool
    
    init(isPressed: Bool = false) {
        self.isPressed = isPressed
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    if colorScheme == .dark {
                        // Dark mode neumorphic
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .shadow(color: .black, radius: configuration.isPressed ? 2 : 6, 
                                   x: configuration.isPressed ? -2 : -4, 
                                   y: configuration.isPressed ? -2 : -4)
                            .shadow(color: .white.opacity(0.1), radius: configuration.isPressed ? 2 : 6,
                                   x: configuration.isPressed ? 2 : 4,
                                   y: configuration.isPressed ? 2 : 4)
                    } else {
                        // Light mode neumorphic
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.4), radius: configuration.isPressed ? 2 : 6,
                                   x: configuration.isPressed ? -2 : -4,
                                   y: configuration.isPressed ? -2 : -4)
                            .shadow(color: .white, radius: configuration.isPressed ? 2 : 6,
                                   x: configuration.isPressed ? 2 : 4,
                                   y: configuration.isPressed ? 2 : 4)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Haptic Extensions
extension View {
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Custom Transitions
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity)
    }
    
    static var bounce: AnyTransition {
        .scale(scale: 1.1).combined(with: .opacity)
    }
}

// MARK: - Loading Animation View
struct LoadingDots: View {
    @State private var animating = false
    let color: Color
    
    init(color: Color = .primary) {
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Animated Number Display
struct AnimatedNumber: View {
    let value: Double
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text("\(Int(displayValue))")
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}