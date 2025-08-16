import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AboutView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Info
                VStack(spacing: 16) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(settings.accentColor.color)
                    
                    Text("Liftrack")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Info Cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "person.2.fill",
                        title: "Created by",
                        content: "Noah Byrnes with Claude AI"
                    )
                    
                    InfoCard(
                        icon: "hammer.fill",
                        title: "Built with",
                        content: "SwiftUI & SwiftData"
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
                    Text("Made with ❤️ for fitness enthusiasts")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 Liftrack. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .navigationTitle("About")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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