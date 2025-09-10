import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AboutView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                // App Info
                VStack(spacing: 16) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(settings.accentColor.color)
                        .padding()
                        .background(
                            Circle()
                                .fill(settings.accentColor.color.opacity(0.1))
                        )
                    
                    Text("Liftrack")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Version \(appVersion) (Build \(buildNumber))")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 20)
                
                // What's New Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("What's New", systemImage: "sparkles")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        WhatsNewItem(text: "Live Activities for rest timers")
                        WhatsNewItem(text: "Interactive workout history charts")
                        WhatsNewItem(text: "Auto-select text fields")
                        WhatsNewItem(text: "Enhanced timer persistence")
                        WhatsNewItem(text: "Improved haptic feedback")
                        WhatsNewItem(text: "Edit mode for safer deletion")
                    }
                    .padding()
                    #if os(iOS)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    #else
                    .background(Color.gray.opacity(0.2))
                    #endif
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Info Cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "person.2.fill",
                        title: "Created by",
                        content: "Noah Byrnes with Claude AI"
                    )
                    
                    InfoCard(
                        icon: "iphone.and.arrow.forward",
                        title: "Compatibility",
                        content: "iOS 18.5+, macOS 15.5+, visionOS"
                    )
                    
                    InfoCard(
                        icon: "hammer.fill",
                        title: "Built with",
                        content: "SwiftUI, SwiftData, ActivityKit"
                    )
                    
                    InfoCard(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        content: "All data stored locally on device"
                    )
                    
                    InfoCard(
                        icon: "star.fill",
                        title: "Rate Liftrack",
                        content: "Enjoying the app? Leave a review!"
                    )
                    
                    InfoCard(
                        icon: "envelope.fill",
                        title: "Feedback",
                        content: "Send suggestions and bug reports"
                    )
                }
                .padding(.horizontal)
                
                // Attribution
                VStack(spacing: 8) {
                    Text("Made with dedication for fitness enthusiasts")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 Liftrack. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Add bottom padding to clear tab bar
                Color.clear.frame(height: DesignConstants.Spacing.tabBarClearance)
            }
            .padding(.vertical)
        .navigationTitle("About")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct WhatsNewItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            
            Spacer()
            }
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(settings.accentColor.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                #if os(iOS)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                #else
                .fill(Color.gray.opacity(0.2))
                #endif
                .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}