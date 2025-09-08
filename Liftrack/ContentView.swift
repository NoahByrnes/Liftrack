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
                // Enhanced loading view with animation
                ZStack {
                    Color(.systemBackground)
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(settings.accentColor.color.opacity(0.2), lineWidth: 4)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(
                                    LinearGradient(
                                        colors: [settings.accentColor.color, settings.accentColor.color.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                            
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 40))
                                .foregroundColor(settings.accentColor.color)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Liftrack")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Loading your workout data...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .opacity(0.8)
                        }
                    }
                }
                .transition(.opacity)
            } else {
                // Main swipe navigation
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        // Swipeable pages with smooth transitions
                        TabView(selection: $selectedTab) {
                            // Condensed Workout view
                            WorkoutTabView()
                                .tag(0)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            
                            // Unified Library view
                            LibraryTabView()
                                .tag(1)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                        .onChange(of: selectedTab) { oldValue, newValue in
                            if oldValue != newValue {
                                settings.selectionFeedback()
                            }
                        }
                        .overlay(alignment: .top) {
                            // Clean header overlay
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 0) // No extra space
                                
                                HStack {
                                    Text(selectedTab == 0 ? "Workout" : "Library")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Profile button
                                    NavigationLink(destination: ProfileView()) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(settings.accentColor.color)
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Page indicator dots
                                HStack(spacing: 8) {
                                    ForEach(0..<2) { index in
                                        Circle()
                                            .fill(selectedTab == index ? settings.accentColor.color : Color(.systemGray5))
                                            .frame(width: selectedTab == index ? 8 : 6, height: selectedTab == index ? 8 : 6)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                                    }
                                }
                                .padding(.bottom, 2)
                            }
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(.systemBackground).opacity(0.95),
                                        Color(.systemBackground).opacity(0.8),
                                        Color(.systemBackground).opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .ignoresSafeArea()
                            )
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
