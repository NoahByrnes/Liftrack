import SwiftUI

struct GradientBackground: View {
    var body: some View {
        ZStack {
            // Layer 1: Animated gradient background
            if #available(iOS 18.0, *) {
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince1970
                    let offsetX = Float(sin(time)) * 0.1
                    let offsetY = Float(cos(time)) * 0.1
                    
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
                            .black.opacity(0.7), .purple.opacity(0.8), .indigo.opacity(0.7), .black.opacity(0.6),
                            .purple.opacity(0.6), .pink.opacity(0.7), .orange.opacity(0.6), .purple.opacity(0.5),
                            .orange.opacity(0.7), .yellow.opacity(0.6), .pink.opacity(0.7), .purple.opacity(0.8)
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
            
            // Layer 2: Animated noise overlay for flowing grain effect
            if #available(iOS 18.0, *) {
                TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                    GeometryReader { geometry in
                        Canvas { context, size in
                            let time = timeline.date.timeIntervalSince1970
                            
                            for i in 0..<8000 {
                                // Create stable base positions using index as seed
                                let baseX = Double((i * 2654435761) % Int(size.width))
                                let baseY = Double((i * 1597334677) % Int(size.height))
                                
                                // Add flowing movement based on time
                                let flowX = sin(time * 0.3 + Double(i) * 0.001) * 5
                                let flowY = cos(time * 0.2 + Double(i) * 0.001) * 3
                                
                                // Final position with subtle drift
                                let x = (baseX + flowX).truncatingRemainder(dividingBy: size.width)
                                let y = (baseY + flowY).truncatingRemainder(dividingBy: size.height)
                                
                                // Vary opacity slightly over time for shimmer effect
                                let baseOpacity = 0.1 + (Double(i % 100) / 100.0) * 0.15
                                let opacity = baseOpacity + sin(time * 2 + Double(i) * 0.01) * 0.05
                                
                                let particleSize = 0.3 + (Double(i % 10) / 10.0) * 1.7
                                
                                context.fill(
                                    Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                    with: .color(.white.opacity(opacity))
                                )
                            }
                        }
                        .allowsHitTesting(false)
                        .blendMode(.overlay)
                    }
                    .ignoresSafeArea()
                }
            } else {
                // Fallback static grain for iOS 17
                GeometryReader { geometry in
                    Canvas { context, size in
                        for _ in 0..<8000 {
                            let x = Double.random(in: 0...size.width)
                            let y = Double.random(in: 0...size.height)
                            let opacity = Double.random(in: 0.1...0.25)
                            let particleSize = Double.random(in: 0.3...2.0)
                            
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                with: .color(.white.opacity(opacity))
                            )
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