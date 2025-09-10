import SwiftUI

struct GradientBackground: View {
    @State private var grainTime: Double = 0
    
    var body: some View {
        ZStack {
            // Layer 1: Animated gradient background
            if #available(iOS 18.0, *) {
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince1970
                    let offsetX = Float(sin(time * 0.3)) * 0.1  // 3x slower movement
                    let offsetY = Float(cos(time * 0.3)) * 0.1  // 3x slower movement
                    
                    MeshGradient(
                        width: 4,
                        height: 4,
                        points: [
                            [0.0, 0.0],
                            [0.3, 0.0],
                            [0.7, 0.0],
                            [1.0, 0.0],
                            [0.0, 0.3],
                            [0.2 + offsetX, 0.4 + offsetY],
                            [0.7 + offsetX, 0.2 + offsetY],
                            [1.0, 0.3],
                            [0.0, 0.7],
                            [0.3 + offsetX, 0.8],
                            [0.7 + offsetX, 0.6],
                            [1.0, 0.7],
                            [0.0, 1.0],
                            [0.3, 1.0],
                            [0.7, 1.0],
                            [1.0, 1.0]
                        ],
                        colors: [
                            .black, .black.opacity(0.9), .black.opacity(0.8), .black,
                            .black.opacity(0.7), .indigo.opacity(0.8), .indigo.opacity(0.7), .black.opacity(0.6),
                            .indigo.opacity(0.6), .blue.opacity(0.7), .black.opacity(0.6), .blue.opacity(0.5),
                            .black.opacity(0.7), .blue.opacity(0.6), .blue.opacity(0.7), .indigo.opacity(0.8)
                        ],
                        smoothsColors: true
                    )
                    .ignoresSafeArea()
                }
            } else {
                // Fallback for iOS 17 and earlier
                LinearGradient(
                    colors: [
                        .purple,
                        .pink,
                        .orange,
                        .yellow
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Layer 2: Very subtle film grain effect
            if #available(iOS 18.0, *) {
                TimelineView(.animation(minimumInterval: 2.0)) { timeline in // Very slow update - 0.5 fps
                    GeometryReader { geometry in
                        Canvas { context, size in
                            let time = timeline.date.timeIntervalSince1970
                            let grainSize: CGFloat = 3.0 // Larger, softer grain
                            let cols = Int(size.width / grainSize) + 1
                            let rows = Int(size.height / grainSize) + 1
                            
                            // Almost static seed with minimal change
                            let frameNumber = Int(time * 0.5) // Extremely slow change
                            
                            // Draw extremely subtle grain
                            for row in stride(from: 0, to: rows, by: 4) { // Skip even more
                                for col in stride(from: 0, to: cols, by: 4) {
                                    // Complex hash for better distribution
                                    let seed1 = (row * 12347 + col * 8923 + frameNumber * 571)
                                    let seed2 = (row * 3571 + col * 9871)
                                    let hash = ((seed1 &* 2654435761) ^ (seed2 &* 1597334677)) % 1000000
                                    let random = Double(hash) / 1000000.0
                                    
                                    // Very subtle intensity
                                    let intensity = random * 0.03 // Max 3% opacity
                                    
                                    if intensity > 0.01 { // Very low threshold
                                        // Static position (no random offset)
                                        let x = CGFloat(col) * grainSize
                                        let y = CGFloat(row) * grainSize
                                        
                                        context.fill(
                                            Path(CGRect(x: x, y: y, width: grainSize, height: grainSize)),
                                            with: .color(.white.opacity(intensity))
                                        )
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(false)
                        .blendMode(.overlay)
                        .opacity(0.3) // Very low overall opacity
                    }
                    .ignoresSafeArea()
                }
            } else {
                // Fallback grain for iOS 17 - static version
                GeometryReader { geometry in
                    Canvas { context, size in
                        let grainSize: CGFloat = 2
                        let cols = Int(size.width / grainSize) + 1
                        let rows = Int(size.height / grainSize) + 1
                        
                        for row in 0..<rows {
                            for col in 0..<cols {
                                // Generate random value based on position only (static)
                                let seed = (row * 1000 + col) * 2654435761
                                let random = Double((seed & 0xFFFFFF)) / Double(0xFFFFFF)
                                
                                let intensity = random * random * 0.4
                                
                                if intensity > 0.05 {
                                    let x = CGFloat(col) * grainSize
                                    let y = CGFloat(row) * grainSize
                                    
                                    context.fill(
                                        Path(CGRect(x: x, y: y, width: grainSize, height: grainSize)),
                                        with: .color(.white.opacity(intensity))
                                    )
                                }
                            }
                        }
                    }
                    .allowsHitTesting(false)
                    .blendMode(.overlay)
                }
                .ignoresSafeArea()
            }
        }
    }
}

// Glass-morphic card style
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
