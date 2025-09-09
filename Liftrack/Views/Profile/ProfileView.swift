import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
import PhotosUI
#endif

struct ProfileView: View {
    @Query private var allSessions: [WorkoutSession]
    @Query private var allTemplates: [WorkoutTemplate]
    @StateObject private var settings = SettingsManager.shared
    @State private var showingOnboarding = false
    @State private var appearAnimation = false
    @State private var avatarScale = 0.8
    @State private var showingImagePicker = false
    @State private var editingName = false
    @State private var tempDisplayName = ""
    #if os(iOS)
    @State private var selectedImage: PhotosPickerItem? = nil
    #endif
    
    var completedWorkouts: Int {
        allSessions.filter { $0.completedAt != nil }.count
    }
    
    var totalWorkoutTime: TimeInterval {
        allSessions.compactMap { $0.duration }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                    // Profile Picture and Name Section
                    VStack(spacing: 16) {
                        // Profile Picture
                        Button(action: { showingImagePicker = true }) {
                            ZStack {
                                if !settings.profileImageData.isEmpty,
                                   let uiImage = UIImage(data: settings.profileImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                        .overlay(
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 80))
                                                .foregroundColor(settings.accentColor.color)
                                        )
                                }
                                
                                // Edit overlay
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    )
                                    .opacity(0.8)
                            }
                        }
                        .scaleEffect(avatarScale)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: appearAnimation)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: avatarScale)
                        
                        // Display Name
                        VStack(spacing: 4) {
                            if editingName {
                                HStack {
                                    TextField("Enter your name", text: $tempDisplayName)
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: 200)
                                        .onSubmit {
                                            settings.userDisplayName = tempDisplayName
                                            editingName = false
                                        }
                                    
                                    Button("Done") {
                                        settings.userDisplayName = tempDisplayName
                                        editingName = false
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(settings.accentColor.color)
                                }
                            } else {
                                Text(settings.userDisplayName.isEmpty ? "Tap to set name" : settings.userDisplayName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(settings.userDisplayName.isEmpty ? .secondary : .primary)
                                    .onTapGesture {
                                        tempDisplayName = settings.userDisplayName
                                        editingName = true
                                    }
                            }
                            
                            Text("\(completedWorkouts) workouts completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Animated Stats Cards
                    HStack(spacing: 12) {
                        StatsCard(
                            icon: "figure.strengthtraining.traditional",
                            value: "\(completedWorkouts)",
                            label: "Workouts",
                            color: settings.accentColor.color
                        )
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 30)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                        
                        StatsCard(
                            icon: "clock.fill",
                            value: formatDuration(totalWorkoutTime),
                            label: "Total Time",
                            color: .blue
                        )
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 30)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: appearAnimation)
                        
                        StatsCard(
                            icon: "square.stack.3d.up",
                            value: "\(allTemplates.count)",
                            label: "Templates",
                            color: .green
                        )
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 30)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: appearAnimation)
                    }
                    .padding(.horizontal)
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        NavigationLink(destination: PreferencesView()) {
                            SettingsRow(
                                icon: "paintbrush.fill",
                                title: "Appearance",
                                subtitle: "Theme, colors, and display",
                                color: settings.accentColor.color
                            )
                        }
                        
                        NavigationLink(destination: WorkoutSettingsView()) {
                            SettingsRow(
                                icon: "dumbbell.fill",
                                title: "Workout Settings",
                                subtitle: "Timers, sounds, and behavior",
                                color: .orange
                            )
                        }
                        
                        NavigationLink(destination: DataManagementView()) {
                            SettingsRow(
                                icon: "externaldrive.fill",
                                title: "Data & Backup",
                                subtitle: "Export and manage your data",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: AboutView()) {
                            SettingsRow(
                                icon: "info.circle.fill",
                                title: "About",
                                subtitle: "Version and information",
                                color: .gray
                            )
                        }
                        
                        Button(action: { showingOnboarding = true }) {
                            SettingsRow(
                                icon: "sparkles",
                                title: "Setup Assistant",
                                subtitle: "Personalize your training",
                                color: .purple
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: DesignConstants.Spacing.tabBarClearance)
                }
            }
            #if os(iOS)
            .background(Color(UIColor.systemGroupedBackground))
            #else
            .background(Color.gray.opacity(0.1))
            #endif
            #if os(iOS)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                withAnimation {
                    appearAnimation = true
                    avatarScale = 1.0
                }
            }
            // Onboarding view removed - add basic onboarding if needed
            #if os(iOS)
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let selectedImage = newValue,
                       let data = try? await selectedImage.loadTransferable(type: Data.self) {
                        settings.profileImageData = data
                    }
                }
            }
            #endif
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self], inMemory: true)
}