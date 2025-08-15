import SwiftUI

struct ModernTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    let tabs = [
        TabItem(icon: "square.stack.3d.up", title: "Templates", tag: 0),
        TabItem(icon: "figure.strengthtraining.traditional", title: "Workout", tag: 1),
        TabItem(icon: "chart.line.uptrend.xyaxis", title: "History", tag: 2),
        TabItem(icon: "person.crop.circle", title: "Profile", tag: 3)
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
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: Color(.systemGray).opacity(0.3), radius: 20, x: 0, y: 10)
                .overlay(
                    Capsule()
                        .stroke(Color(.systemGray4).opacity(0.2), lineWidth: 0.5)
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .matchedGeometryEffect(id: "selected", in: animation)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .symbolEffect(.bounce, value: isSelected)
                        .foregroundColor(isSelected ? .purple : .secondary)
                }
                .frame(height: 48)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .purple : .secondary)
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
    .background(Color(.systemBackground))
}