import SwiftUI
import Charts
import SwiftData

struct InteractiveVolumeChart: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?
    @State private var isDragging = false
    
    private var dailyVolumeData: [(date: Date, volume: Double, dayLabel: String)] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        // Group sessions by day
        var dailyVolumes: [Date: Double] = [:]
        
        for session in sessions {
            guard let completedAt = session.completedAt,
                  completedAt >= thirtyDaysAgo else { continue }
            
            // Normalize to start of day
            let dayStart = calendar.startOfDay(for: completedAt)
            
            // Calculate volume for this session (including warmup sets to match WorkoutCard)
            let sessionVolume = session.exercises.flatMap { $0.sets }
                .filter { $0.isCompleted }
                .map { $0.weight * Double($0.reps) }
                .reduce(0, +)
            
            dailyVolumes[dayStart, default: 0] += sessionVolume
        }
        
        // Create array with all days (including zero volume days)
        var allDays: [(Date, Double, String)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var currentDate = thirtyDaysAgo
        while currentDate <= Date() {
            let dayStart = calendar.startOfDay(for: currentDate)
            let volume = dailyVolumes[dayStart] ?? 0
            let label = formatter.string(from: dayStart)
            allDays.append((dayStart, volume, label))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return allDays
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with selected value
            HStack {
                Text("Total Volume")
                    .font(.headline)
                Spacer()
                if let date = selectedDate, let value = selectedValue {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(value)) lbs")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption2)
                        Text("Touch chart to explore")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Chart(dailyVolumeData, id: \.date) { item in
                // Bar for each day
                BarMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.volume)
                )
                .foregroundStyle(
                    selectedDate == nil || Calendar.current.isDate(item.date, inSameDayAs: selectedDate!) 
                    ? settings.accentColor.color 
                    : settings.accentColor.color.opacity(0.3)
                )
                .cornerRadius(3)
                
                // Selection indicator
                if let selectedDate = selectedDate,
                   Calendar.current.isDate(item.date, inSameDayAs: selectedDate) {
                    RuleMark(x: .value("Date", item.date))
                        .foregroundStyle(Color.primary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(settings.accentColor.color)
                    .symbolSize(100)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let volume = value.as(Double.self) {
                            Text(formatVolume(volume))
                        }
                    }
                }
            }
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    updateSelectionFromLocation(location: location, geometry: geometry)
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        isDragging = false
                                        selectedDate = nil
                                        selectedValue = nil
                                    }
                                }
                        )
                }
            )
        }
    }
    
    private func updateSelectionFromLocation(location: CGPoint, geometry: GeometryProxy) {
        let xPosition = location.x
        let plotWidth = geometry.size.width
        let dataCount = dailyVolumeData.count
        
        guard dataCount > 0 else { return }
        
        // Calculate which data point we're closest to
        let index = Int((xPosition / plotWidth) * CGFloat(dataCount))
        let clampedIndex = max(0, min(dataCount - 1, index))
        
        let selectedData = dailyVolumeData[clampedIndex]
        
        // Only update if value changed (for haptic feedback)
        let valueChanged = selectedDate != selectedData.date
        
        withAnimation(.easeOut(duration: 0.1)) {
            selectedDate = selectedData.date
            selectedValue = selectedData.volume
            isDragging = true
        }
        
        // Haptic feedback on change
        #if os(iOS)
        if valueChanged {
            SettingsManager.shared.impactFeedback(style: .light)
        }
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        } else {
            return "\(Int(volume))"
        }
    }
}

struct InteractiveFrequencyChart: View {
    let sessions: [WorkoutSession]
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedWeek: Int?
    @State private var selectedCount: Int?
    @State private var previousSelectedWeek: Int?
    
    private var weeklyData: [(weekIndex: Int, weekStart: Date, count: Int, label: String)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var weeks: [(Int, Date, Int, String)] = []
        
        // Last 8 weeks
        for weekOffset in (0..<8).reversed() {
            let weekStart = calendar.dateInterval(of: .weekOfYear, 
                for: calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date())!)!.start
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let count = sessions.filter { session in
                guard let date = session.completedAt else { return false }
                return date >= weekStart && date < weekEnd
            }.count
            
            let label = formatter.string(from: weekStart)
            weeks.append((8 - weekOffset, weekStart, count, label))
        }
        
        return weeks
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Weekly Frequency")
                    .font(.headline)
                Spacer()
                if let week = selectedWeek, let count = selectedCount {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Week \(week)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(count) workout\(count == 1 ? "" : "s")")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(settings.accentColor.color)
                    }
                } else {
                    Text("8 week trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Chart(weeklyData, id: \.weekIndex) { item in
                BarMark(
                    x: .value("Week", item.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    selectedWeek == nil || selectedWeek == item.weekIndex
                    ? settings.accentColor.color
                    : settings.accentColor.color.opacity(0.3)
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    if selectedWeek == item.weekIndex {
                        Text("\(item.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...max(7, weeklyData.map { $0.count }.max() ?? 7))
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateWeekSelection(at: value.location, geometry: geometry)
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        selectedWeek = nil
                                        selectedCount = nil
                                        previousSelectedWeek = nil
                                    }
                                }
                        )
                }
            )
        }
    }
    
    private func updateWeekSelection(at location: CGPoint, geometry: GeometryProxy) {
        let xPosition = location.x
        let plotWidth = geometry.size.width
        let weekCount = weeklyData.count
        
        guard weekCount > 0 else { return }
        
        let index = Int((xPosition / plotWidth) * CGFloat(weekCount))
        let clampedIndex = max(0, min(weekCount - 1, index))
        
        let selectedData = weeklyData[clampedIndex]
        
        // Only haptic if week actually changed
        let weekChanged = previousSelectedWeek != selectedData.weekIndex
        
        withAnimation(.easeOut(duration: 0.1)) {
            selectedWeek = selectedData.weekIndex
            selectedCount = selectedData.count
            previousSelectedWeek = selectedData.weekIndex
        }
        
        #if os(iOS)
        if weekChanged {
            SettingsManager.shared.impactFeedback(style: .light)
        }
        #endif
    }
}

struct InteractiveProgressChartsSection: View {
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
            }
            .pickerStyle(SegmentedPickerStyle())
            
            VStack {
                switch selectedChart {
                case 0:
                    InteractiveVolumeChart(sessions: sessions)
                case 1:
                    InteractiveFrequencyChart(sessions: sessions)
                default:
                    EmptyView()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}