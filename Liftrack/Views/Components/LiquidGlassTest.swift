import SwiftUI

@available(iOS 26.0, *)
struct LiquidGlassTest: View {
    @Namespace private var namespace
    
    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 20) {
                // Test the glassEffect modifier with correct syntax
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .frame(height: 100)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                
                // Test clear glass variant
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.purple)
                    .frame(height: 100)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))
                
                // Test glass button styles
                HStack(spacing: 16) {
                    Button("Glass Regular") {}
                        .buttonStyle(.glass)
                    
                    Button("Glass Prominent") {}
                        .buttonStyle(.glassProminent)
                }
                
                // Test glass effect transitions
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.orange)
                    .frame(height: 100)
                    .glassEffect(.regular)
                    .glassEffectTransition(.materialize)
            }
            .padding()
        }
    }
}