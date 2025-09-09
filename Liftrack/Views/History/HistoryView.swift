import SwiftUI
import SwiftData
import Charts
#if canImport(UIKit)
import UIKit
#endif

struct HistoryView: View {
    @Binding var showingProfile: Bool
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
           sort: \WorkoutSession.completedAt, order: .reverse)
    private var completedSessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @State private var selectedTimeRange = 0
    @State private var selectedDate = Date()
    @State private var showingWorkoutDetail: WorkoutSession? = nil
    @State private var appearAnimation = false
    @State private var chartAnimation = false
    @State private var isRefreshing = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                // Pull to refresh indicator
                if isRefreshing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                VStack(spacing: 24) {
                    // Add top padding to account for fixed header
                    Color.clear.frame(height: 120)
                    
                    // Animated Calendar Widget
                    CalendarWidget(
                        sessions: completedSessions,
                        selectedDate: $selectedDate
                    )
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .scaleEffect(appearAnimation ? 1 : 0.95)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
                    
                    // Stats Overview
                    if !completedSessions.isEmpty {
                        StatsOverview(sessions: completedSessions)
                            .padding(.horizontal)
                            .opacity(chartAnimation ? 1 : 0)
                            .offset(y: chartAnimation ? 0 : 30)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: chartAnimation)
                        
                        // Personal Records Dashboard
                        PersonalRecordsDashboard(sessions: completedSessions)
                            .padding(.horizontal)
                            .opacity(chartAnimation ? 1 : 0)
                            .offset(y: chartAnimation ? 0 : 30)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: chartAnimation)
                        
                        // Progress Charts with Interactive Features
                        InteractiveProgressChartsSection(sessions: completedSessions)
                            .padding(.horizontal)
                            .opacity(chartAnimation ? 1 : 0)
                            .offset(y: chartAnimation ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: chartAnimation)
                    }
                    
                    // Recent Workouts
                    if completedSessions.isEmpty {
                        EmptyHistoryView()
                            .padding(.top, 60)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Workouts")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(completedSessions.prefix(10).enumerated()), id: \.element.id) { index, session in
                                    WorkoutCard(session: session)
                                        .onTapGesture {
                                            settings.impactFeedback(style: .light)
                                            showingWorkoutDetail = session
                                        }
                                        .opacity(appearAnimation ? 1 : 0)
                                        .offset(y: appearAnimation ? 0 : 30)
                                        .animation(
                                            .spring(response: 0.4, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.05 + 0.4),
                                            value: appearAnimation
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, DesignConstants.Spacing.tabBarClearance)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await refreshData()
            }
            .onAppear {
                withAnimation {
                    appearAnimation = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    chartAnimation = true
                }
            }
            .sheet(item: $showingWorkoutDetail) { session in
                NavigationStack {
                    WorkoutDetailView(session: session)
                }
            }
            }
        }
    }
}

extension HistoryView {
    private func refreshData() async {
        // Add haptic feedback for pull to refresh
        await MainActor.run {
            settings.impactFeedback(style: .medium)
            withAnimation {
                isRefreshing = true
            }
        }
        
        // Simulate a refresh delay (in real app, this would be data fetching)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            withAnimation {
                isRefreshing = false
                // Reset animations to replay them
                appearAnimation = false
                chartAnimation = false
            }
            
            // Replay animations after refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    appearAnimation = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    chartAnimation = true
                }
            }
            
            settings.notificationFeedback(type: .success)
        }
    }
}

// MARK: - Calendar Widget
struct CalendarWidget: View {
    let sessions: [WorkoutSession]
    @Binding var selectedDate: Date
    @State private var displayedMonth = Date()
    @StateObject private var settings = SettingsManager.shared
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private var workoutDates: Set<DateComponents> {
        Set(sessions.compactMap { session in
            guard let date = session.completedAt else { return nil }
            return calendar.dateComponents([.year, .month, .day], from: date)
        })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(settings.accentColor.color)
                }
                
                Spacer()
                
                Text(monthFormatter.string(from: displayedMonth))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            CalendarGridView(
                displayedMonth: displayedMonth,
                workoutDates: workoutDates,
                selectedDate: $selectedDate
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    private func previousMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }
}

struct CalendarGridView: View {
    let displayedMonth: Date
    let workoutDates: Set<DateComponents>
    @Binding var selectedDate: Date
    @StateObject private var settings = SettingsManager.shared
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            hasWorkout: hasWorkout(on: date),
                            isToday: calendar.isDateInToday(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }
    
    private func hasWorkout(on date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return workoutDates.contains(components)
    }
}

struct DayCell: View {
    let date: Date
    let hasWorkout: Bool
    let isToday: Bool
    let isSelected: Bool
    @StateObject private var settings = SettingsManager.shared
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    var body: some View {
        ZStack {
            // Background
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(settings.accentColor.color)
                    .frame(width: 36, height: 36)
            } else if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(settings.accentColor.color, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
            
            // Day number
            Text(dayFormatter.string(from: date))
                .font(.system(size: 16, weight: isToday ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? settings.accentColor.color : .primary))
            
            // Workout indicator
            if hasWorkout {
                Circle()
                    .fill(isSelected ? .white : settings.accentColor.color)
                    .frame(width: 6, height: 6)
                    .offset(y: 14)
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Progress Charts
struct ProgressChartsSection: View {
    let sessions: [WorkoutSession]
    @State private var selectedChart = 0
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            
            Picker("Chart Type", selection: $selectedChart) {
                Text("Volume").tag(0)
                Text("Frequency").tag(1)
                Text("Duration").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            VStack {
                switch selectedChart {
                case 0:
                    VolumeChart(sessions: sessions)
                case 1:
                    FrequencyChart(sessions: sessions)
                case 2:
                    DurationChart(sessions: sessions)
                default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

struct VolumeChart: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    
    private var volumeData: [(date: Date, volume: Double)] {
        let last30Days = sessions.filter { session in
            guard let date = session.completedAt else { return false }
            return date > Date().addingTimeInterval(-30 * 24 * 60 * 60)
        }
        
        return last30Days.compactMap { session in
            guard let date = session.completedAt else { return nil }
            let volume = session.exercises.flatMap { $0.sets }
                .filter { $0.isCompleted }
                .map { $0.weight * Double($0.reps) }
                .reduce(0, +)
            return (date, volume)
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        if volumeData.isEmpty {
            Text("No data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(volumeData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(settings.accentColor.color)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(settings.accentColor.color.opacity(0.2))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let volume = value.as(Double.self) {
                            Text("\(Int(volume/1000))k")
                        }
                    }
                }
            }
        }
    }
}

struct FrequencyChart: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    
    private var weeklyData: [(week: String, count: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var weekCounts: [(Date, Int)] = []
        
        for weekOffset in (0..<4).reversed() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date())!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let count = sessions.filter { session in
                guard let date = session.completedAt else { return false }
                return date >= weekStart && date < weekEnd
            }.count
            
            weekCounts.append((weekStart, count))
        }
        
        return weekCounts.map { (formatter.string(from: $0.0), $0.1) }
    }
    
    var body: some View {
        Chart(weeklyData, id: \.week) { item in
            BarMark(
                x: .value("Week", item.week),
                y: .value("Workouts", item.count)
            )
            .foregroundStyle(settings.accentColor.color)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                    }
                }
            }
        }
    }
}

struct DurationChart: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    
    private var durationData: [(date: Date, minutes: Int)] {
        let last30Days = sessions.filter { session in
            guard let date = session.completedAt else { return false }
            return date > Date().addingTimeInterval(-30 * 24 * 60 * 60)
        }
        
        return last30Days.compactMap { session in
            guard let date = session.completedAt,
                  let duration = session.duration else { return nil }
            return (date, Int(duration / 60))
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        if durationData.isEmpty {
            Text("No data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(durationData, id: \.date) { item in
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(settings.accentColor.color)
                .symbolSize(100)
                
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(settings.accentColor.color.opacity(0.5))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let minutes = value.as(Int.self) {
                            Text("\(minutes)m")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stats Overview
struct StatsOverview: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    
    var totalWorkouts: Int { sessions.count }
    var thisWeekWorkouts: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { ($0.completedAt ?? Date()) > weekAgo }.count
    }
    var totalTime: String {
        let total = sessions.compactMap { $0.duration }.reduce(0, +)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    var currentStreak: Int {
        // Calculate current workout streak
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        for _ in 0..<30 {
            let dayWorkouts = sessions.filter { session in
                guard let date = session.completedAt else { return false }
                return calendar.isDate(date, inSameDayAs: checkDate)
            }
            
            if !dayWorkouts.isEmpty {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if calendar.isDateInToday(checkDate) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "calendar",
                    value: "\(totalWorkouts)",
                    label: "Total",
                    color: settings.accentColor.color
                )
                
                StatCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Streak",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(thisWeekWorkouts)",
                    label: "This Week",
                    color: .green
                )
                
                StatCard(
                    icon: "clock.fill",
                    value: totalTime,
                    label: "Total Time",
                    color: .blue
                )
            }
        }
    }
}

// MARK: - Personal Records Dashboard
struct PersonalRecordsDashboard: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedExercise: Exercise? = nil
    @State private var showAllPRs = false
    
    private var personalRecords: [(exercise: Exercise, maxWeight: Double, reps: Int, date: Date)] {
        var records: [Exercise: (weight: Double, reps: Int, date: Date)] = [:]
        
        for session in sessions {
            guard let completedAt = session.completedAt else { continue }
            
            for sessionExercise in session.exercises {
                // Create placeholder exercise from stored data  
                let exercise = Exercise(name: sessionExercise.exerciseName)
                exercise.id = sessionExercise.exerciseId
                
                for set in sessionExercise.sets where set.isCompleted {
                    let currentMax = records[exercise]?.weight ?? 0
                    
                    // Check if this is a new PR (higher weight or same weight with more reps)
                    if set.weight > currentMax || 
                       (set.weight == currentMax && set.reps > (records[exercise]?.reps ?? 0)) {
                        records[exercise] = (set.weight, set.reps, completedAt)
                    }
                }
            }
        }
        
        return records.map { ($0.key, $0.value.weight, $0.value.reps, $0.value.date) }
            .sorted { $0.maxWeight > $1.maxWeight }
    }
    
    var topPRs: [(exercise: Exercise, maxWeight: Double, reps: Int, date: Date)] {
        Array(personalRecords.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personal Records")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                
                Spacer()
                
                if personalRecords.count > 3 {
                    Button(action: { showAllPRs.toggle() }) {
                        Text(showAllPRs ? "Show Less" : "Show All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }
            
            VStack(spacing: 12) {
                ForEach(showAllPRs ? personalRecords : topPRs, id: \.exercise.id) { record in
                    PRCard(
                        exercise: record.exercise,
                        weight: record.maxWeight,
                        reps: record.reps,
                        date: record.date,
                        unit: settings.preferredWeightUnit
                    )
                }
            }
            
            if personalRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No personal records yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Complete workouts to track your PRs")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }
}

struct PRCard: View {
    let exercise: Exercise
    let weight: Double
    let reps: Int
    let date: Date
    let unit: String
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var displayWeight: String {
        let convertedWeight = unit == "kg" ? weight * 0.453592 : weight
        return String(format: "%.1f", convertedWeight)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                
                HStack(spacing: 8) {
                    Text("\(displayWeight) \(unit)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("×")
                        .foregroundColor(.secondary)
                    
                    Text("\(reps) reps")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Date
            Text(dateFormatter.string(from: date))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Workout Card
struct WorkoutCard: View {
    let session: WorkoutSession
    @State private var isPressed = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.templateName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        if let completedAt = session.completedAt {
                            Label(completedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        if let duration = session.duration {
                            Label(formatDuration(duration), systemImage: "timer")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Quick stats
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 11))
                    Text("\(session.exercises.count) exercises")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                if let totalVolume = calculateTotalVolume(session) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 11))
                        Text("\(Int(totalVolume)) lbs")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    private func calculateTotalVolume(_ session: WorkoutSession) -> Double? {
        let volume = session.exercises.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .map { $0.weight * Double($0.reps) }
            .reduce(0, +)
        return volume > 0 ? volume : nil
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = SettingsManager.shared
    @State private var showingActiveWorkout = false
    @State private var newWorkoutSession: WorkoutSession?
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session Info Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.completedAt?.formatted(date: .complete, time: .shortened) ?? "")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDuration(session.duration ?? 0))
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        StatBadge(label: "Exercises", value: "\(session.exercises.count)")
                        StatBadge(label: "Sets", value: "\(session.exercises.flatMap { $0.sets }.count)")
                        StatBadge(label: "Volume", value: "\(Int(calculateTotalVolume(session))) lbs")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                
                // Exercises
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    
                    ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                        ExerciseDetailCard(exercise: exercise)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        repeatWorkout()
                    }) {
                        Label("Repeat This Workout", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(settings.accentColor.color)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        shareWorkout()
                    }) {
                        Label("Share Workout", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(settings.accentColor.color)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.accentColor.color, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.templateName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let newSession = newWorkoutSession {
                ActiveWorkoutView(session: newSession)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    private func calculateTotalVolume(_ session: WorkoutSession) -> Double {
        session.exercises.flatMap { $0.sets }
            .filter { $0.isCompleted }
            .map { $0.weight * Double($0.reps) }
            .reduce(0, +)
    }
    
    private func repeatWorkout() {
        // Create new workout session based on this historical one
        let newSession = WorkoutSession()
        newSession.templateName = session.templateName
        
        // Copy exercises with their structure but fresh sets
        for exercise in session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // Create a placeholder exercise from stored name
            let actualExercise = Exercise(name: exercise.exerciseName)
            actualExercise.id = exercise.exerciseId
            let newExercise = SessionExercise(
                exercise: actualExercise,
                orderIndex: exercise.orderIndex,
                customRestSeconds: exercise.customRestSeconds
            )
            
            // Create fresh sets based on the original workout, preserving warmup order
            let sortedSets = exercise.sets.sorted(by: { 
                // Warmup sets first, then regular sets
                if $0.isWarmup != $1.isWarmup {
                    return $0.isWarmup
                }
                // Within each group, sort by set number
                return $0.setNumber < $1.setNumber
            })
            
            for set in sortedSets {
                let newSet = WorkoutSet(setNumber: set.setNumber)
                // Pre-fill with previous weights/reps as targets
                newSet.weight = set.weight
                newSet.reps = set.reps
                newSet.isWarmup = set.isWarmup
                newExercise.sets.append(newSet)
            }
            
            newSession.exercises.append(newExercise)
        }
        
        // Insert and save the new session
        modelContext.insert(newSession)
        try? modelContext.save()
        
        // Store reference and show workout
        newWorkoutSession = newSession
        showingActiveWorkout = true
        
        // Dismiss the detail view
        dismiss()
    }
    
    private func shareWorkout() {
        // Create shareable workout summary
        var summary = "🏋️ Workout Summary\n"
        summary += "━━━━━━━━━━━━━━━━━━\n"
        summary += "📍 \(session.templateName)\n"
        
        if let completedAt = session.completedAt {
            summary += "📅 \(completedAt.formatted(date: .abbreviated, time: .shortened))\n"
        }
        
        if let duration = session.duration {
            summary += "⏱️ Duration: \(formatDuration(duration))\n"
        }
        
        let totalVolume = calculateTotalVolume(session)
        summary += "💪 Total Volume: \(Int(totalVolume)) lbs\n"
        summary += "\n━━━━━━━━━━━━━━━━━━\n\n"
        
        // Add exercises details
        for exercise in session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            summary += "▸ \(exercise.exerciseName)\n"
            
            let completedSets = exercise.sets.filter { $0.isCompleted }.sorted(by: {
                // Warmup sets first, then regular sets
                if $0.isWarmup != $1.isWarmup {
                    return $0.isWarmup
                }
                // Within each group, sort by set number
                return $0.setNumber < $1.setNumber
            })
            
            for set in completedSets {
                let setType = set.isWarmup ? "W\(set.setNumber)" : "Set \(set.setNumber)"
                let weightStr = set.weight == floor(set.weight) ? "\(Int(set.weight))" : String(format: "%.1f", set.weight)
                summary += "  • \(setType): \(weightStr) lbs × \(set.reps) reps\n"
            }
            summary += "\n"
        }
        
        summary += "━━━━━━━━━━━━━━━━━━\n"
        summary += "Tracked with Liftrack 💪"
        
        shareText = summary
        showingShareSheet = true
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(settings.accentColor.color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExerciseDetailCard: View {
    let exercise: SessionExercise
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.system(size: 18, weight: .semibold))
            
            VStack(spacing: 8) {
                HStack {
                    Text("Set")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    
                    Text("Weight")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    
                    Text("Reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                    
                    Text("Status")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 50)
                }
                
                ForEach(exercise.sets.sorted(by: { 
                    // Warmup sets first, then regular sets
                    if $0.isWarmup != $1.isWarmup {
                        return $0.isWarmup
                    }
                    // Within each group, sort by set number
                    return $0.setNumber < $1.setNumber
                })) { set in
                    HStack {
                        Text(set.isWarmup ? "W" : "\(set.setNumber)")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(set.isWarmup ? .orange : .primary)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("\(set.weight == floor(set.weight) ? "\(Int(set.weight))" : String(format: "%.1f", set.weight)) lbs")
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity)
                        
                        Text("\(set.reps)")
                            .font(.system(size: 15))
                            .frame(width: 50)
                        
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set.isCompleted ? settings.accentColor.color : .secondary)
                            .frame(width: 50)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct EmptyHistoryView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(settings.accentColor.color.opacity(0.5))
            
            Text("No Workout History")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            
            Text("Complete your first workout\nto start tracking progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Share Sheet
#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: View {
    let activityItems: [Any]
    var body: some View {
        Text("Sharing is not available on this platform")
            .padding()
    }
}
#endif

#Preview {
    HistoryView(showingProfile: .constant(false))
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}