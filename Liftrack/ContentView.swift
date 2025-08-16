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
    @State private var selectedTab = 0
    @StateObject private var settings = SettingsManager.shared
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt == nil })
    private var activeSessions: [WorkoutSession]
    @StateObject private var timerManager = WorkoutTimerManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch selectedTab {
                case 0:
                    TemplatesView()
                case 1:
                    WorkoutView()
                case 2:
                    HistoryView()
                case 3:
                    ProfileView()
                default:
                    TemplatesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: 0) {
                // Minimized workout bar (if active and minimized)
                if let activeSession = activeSessions.first,
                   timerManager.isMinimized {
                    MinimizedWorkoutBar(session: activeSession)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Custom tab bar
                ModernTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .tint(settings.accentColor.color)
        .onAppear {
            DataSeeder.seedExercisesIfNeeded(context: modelContext)
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
