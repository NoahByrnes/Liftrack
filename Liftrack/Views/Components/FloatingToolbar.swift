import SwiftUI

@available(iOS 26.0, *)
struct FloatingToolbar: View {
    @Binding var showingProfile: Bool
    @Binding var showingTemplatePicker: Bool
    @State private var isExpanded = false
    
    var body: some View {
        GlassEffectContainer(spacing: isExpanded ? 20.0 : 0.0) {
            HStack(spacing: 4) {
                // Menu toggle button
                Image(systemName: isExpanded ? "xmark" : "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .glassEffect()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }
                
                if isExpanded {
                    // Profile button
                    Image(systemName: "person.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect()
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            showingProfile = true
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    
                    // Templates button
                    Image(systemName: "doc.text")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect()
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            showingTemplatePicker = true
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    
                    // History button
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect()
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            // Navigate to history
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    
                    // Settings/Stats button
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect()
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            // Navigate to settings
                            withAnimation {
                                isExpanded = false
                            }
                        }
                }
            }
        }
    }
}

// Fallback for iOS < 26
struct FloatingToolbarLegacy: View {
    @Binding var showingProfile: Bool
    @Binding var showingTemplatePicker: Bool
    @State private var isExpanded = false
    
    var body: some View {
        HStack(spacing: isExpanded ? 16 : 8) {
            // Menu toggle button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            if isExpanded {
                // Profile button
                Button(action: {
                    showingProfile = true
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .transition(.scale.combined(with: .opacity))
                
                // Templates button
                Button(action: {
                    showingTemplatePicker = true
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .transition(.scale.combined(with: .opacity))
                
                // History button
                Button(action: {
                    // Navigate to history
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .transition(.scale.combined(with: .opacity))
                
                // Settings/Stats button
                Button(action: {
                    // Navigate to settings
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}