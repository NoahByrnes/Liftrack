import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ModernTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    @StateObject private var settings = SettingsManager.shared
    
    let tabs = [
        TabItem(icon: "figure.strengthtraining.traditional", title: "Workout", tag: 0),
        TabItem(icon: "chart.line.uptrend.xyaxis", title: "History", tag: 1),
        TabItem(icon: "doc.text", title: "Templates", tag: 2),
        TabItem(icon: "person.circle", title: "Profile", tag: 3)
    ]
    
    struct TabItem {
        let icon: String
        let title: String
        let tag: Int
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                TabButton(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab.tag,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.tag
                    }
                    SettingsManager.shared.impactFeedback(style: .light)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    @State private var animationTrigger = 0
    
    var body: some View {
        Button(action: {
            if !isSelected {
                animationTrigger += 1
            }
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(SettingsManager.shared.accentColor.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .matchedGeometryEffect(id: "selected", in: animation)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .symbolEffect(.bounce, value: animationTrigger)
                        .foregroundColor(isSelected ? SettingsManager.shared.accentColor.color : .secondary)
                }
                .frame(height: 48)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? SettingsManager.shared.accentColor.color : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Spacer()
        ModernTabBar(selectedTab: .constant(1))
    }
    #if os(iOS)
    .background(Color(UIColor.systemBackground))
    #else
    .background(Color.white)
    #endif
}