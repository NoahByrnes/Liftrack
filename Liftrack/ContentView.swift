//
//  ContentView.swift
//  Liftrack
//
//  Created by Noah Grant-Byrnes on 2025-08-14.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedTabIndex") private var selectedTab = 0
    @AppStorage("hasActiveWorkout") private var hasActiveWorkout = false
    @StateObject private var settings = SettingsManager.shared
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    @StateObject private var timerManager = EnhancedWorkoutTimerManager.shared
    @State private var isLoading = true
    @State private var hasInitialized = false
    @State private var shouldShowLoadingScreen = true
    
    var body: some View {
        ZStack {
            if isLoading {
                // Simple loading view
                ZStack {
                    Color(.systemBackground)
                    VStack(spacing: 20) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(settings.accentColor.color)
                        Text("Liftrack")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                .transition(.opacity)
            } else {
                // Main swipe navigation
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        // Swipeable pages
                        TabView(selection: $selectedTab) {
                            // Combined Workout + Programs view
                            WorkoutHubView()
                                .tag(0)
                            
                            // History view
                            HistoryView(showingProfile: .constant(false))
                                .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .safeAreaInset(edge: .top) {
                            // Persistent header with profile icon and page dots
                            VStack(spacing: 0) {
                                HStack {
                                    Text(selectedTab == 0 ? "Workout" : "History")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    // Profile button
                                    NavigationLink(destination: ProfileView()) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(settings.accentColor.color)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 10)
                                
                                // Page indicator dots
                                HStack(spacing: 8) {
                                    ForEach(0..<2) { index in
                                        Circle()
                                            .fill(selectedTab == index ? settings.accentColor.color : Color(.systemGray4))
                                            .frame(width: 8, height: 8)
                                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                            .background(.ultraThinMaterial)
                        }
                        
                        // Minimized workout bar at bottom (if active)
                        if let activeSession = activeSessions.first,
                           timerManager.isMinimized {
                            VStack {
                                Spacer()
                                MinimizedWorkoutBar(session: activeSession, selectedTab: $selectedTab)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .navigationBarHidden(true)
                }
            }
        }
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .tint(settings.accentColor.color)
        .onAppear {
            guard !hasInitialized else { return }
            hasInitialized = true
            
            // Check if we have an active workout and should skip loading screen
            let hasActiveSession = !activeSessions.isEmpty
            shouldShowLoadingScreen = !hasActiveSession
            
            // If we have an active workout, go straight to workout tab
            if hasActiveSession {
                selectedTab = 0 // Workout tab (now first tab)
                hasActiveWorkout = true
                isLoading = false
            } else {
                // Perform initial setup with loading screen
                Task {
                    // Seed data in background
                    await MainActor.run {
                        DataSeeder.seedExercisesIfNeeded(context: modelContext)
                    }
                    
                    // Load settings
                    _ = settings.accentColor
                    _ = settings.appearanceMode
                    
                    // Only show loading screen if no active workout
                    if shouldShowLoadingScreen {
                        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    }
                    
                    // Fade out launch screen
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isLoading = false
                        }
                    }
                }
            }
        }
        .onChange(of: activeSessions) { oldValue, newValue in
            // Update the flag when workout state changes
            hasActiveWorkout = !newValue.isEmpty
            
            // If a workout just started, switch to workout tab
            if oldValue.isEmpty && !newValue.isEmpty {
                selectedTab = 0
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // App became active - check for active workout
                if !activeSessions.isEmpty {
                    selectedTab = 0 // Return to workout tab
                }
            case .background:
                // Save state when going to background
                // Tab selection is already persisted via @AppStorage
                break
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self,
            WorkoutTemplate.self,
            WorkoutSession.self
        ], inMemory: true)
}
