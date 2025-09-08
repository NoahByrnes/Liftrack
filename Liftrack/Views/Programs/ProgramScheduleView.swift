import SwiftUI
import SwiftData

struct ProgramScheduleView: View {
    @Bindable var program: Program
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedWeek: ProgramWeek?
    @State private var showingEditSchedule = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Program Overview Card
                    ProgramOverviewCard(program: program)
                        .padding(.horizontal)
                    
                    // Weekly Schedule
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("WEEKLY SCHEDULE")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: { showingEditSchedule = true }) {
                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(program.programWeeks.sorted(by: { $0.weekNumber < $1.weekNumber })) { week in
                            ScheduleWeekCard(week: week, program: program, isExpanded: selectedWeek?.id == week.id) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedWeek = selectedWeek?.id == week.id ? nil : week
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Program Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEditSchedule) {
                EditProgramScheduleView(program: program)
            }
        }
    }
}

struct ProgramOverviewCard: View {
    let program: Program
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(program.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            if !program.programDescription.isEmpty {
                Text(program.programDescription)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 32) {
                // Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(program.durationWeeks)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(settings.accentColor.color)
                    Text("Weeks")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // Workouts per week
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(program.workoutTemplates.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(settings.accentColor.color)
                    Text("Workouts/Week")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // Total workouts
                VStack(alignment: .leading, spacing: 4) {
                    let totalWorkouts = program.programWeeks.flatMap { $0.scheduledWorkouts }.filter { !$0.isRestDay }.count
                    Text("\(totalWorkouts)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(settings.accentColor.color)
                    Text("Total Sessions")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            if let deloadWeek = program.deloadWeek {
                Label("Deload on week \(deloadWeek)", systemImage: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ScheduleWeekCard: View {
    let week: ProgramWeek
    let program: Program
    let isExpanded: Bool
    let onTap: () -> Void
    @StateObject private var settings = SettingsManager.shared
    
    var completedWorkouts: Int {
        week.scheduledWorkouts.filter { $0.isCompleted && !$0.isRestDay }.count
    }
    
    var totalWorkouts: Int {
        week.scheduledWorkouts.filter { !$0.isRestDay }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week Header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(week.name)
                                .font(.system(size: 18, weight: .semibold))
                            
                            if week.isDeload {
                                Text("DELOAD")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            if week.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                        }
                        
                        Text("\(completedWorkouts)/\(totalWorkouts) workouts completed")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    
                    ForEach(week.scheduledWorkouts.sorted(by: { $0.dayNumber < $1.dayNumber })) { workout in
                        ScheduleWorkoutDayRow(workout: workout, week: week)
                        
                        if workout.dayNumber < 7 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ScheduleWorkoutDayRow: View {
    let workout: ProgramWorkout
    let week: ProgramWeek
    @StateObject private var settings = SettingsManager.shared
    
    var dayOfWeek: String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[workout.dayNumber - 1]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Day indicator
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\(workout.dayNumber)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(workout.isCompleted ? .green : settings.accentColor.color)
            }
            .frame(width: 40)
            
            // Workout info
            if workout.isRestDay {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.secondary)
                    Text("Rest Day")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.dayName)
                        .font(.system(size: 16, weight: .medium))
                    
                    if let template = workout.template {
                        HStack(spacing: 12) {
                            Label("\(template.exercises.count) exercises", systemImage: "dumbbell")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            if week.isDeload {
                                Label("70% weight", systemImage: "arrow.down")
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Completion status
            if workout.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else if !workout.isRestDay {
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.3))
                    .font(.system(size: 20))
            }
        }
        .padding()
    }
}

struct EditProgramScheduleView: View {
    @Bindable var program: Program
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var workoutsPerWeek = 3
    @State private var restDayPattern = RestDayPattern.alternating
    @State private var customSchedule: [Int: WorkoutTemplate] = [:]
    
    enum RestDayPattern: String, CaseIterable {
        case alternating = "Alternating Days"
        case consecutive = "Consecutive Days"
        case weekendRest = "Weekend Rest"
        case custom = "Custom"
        
        var description: String {
            switch self {
            case .alternating: return "Workout every other day"
            case .consecutive: return "Workout days in a row"
            case .weekendRest: return "Rest on weekends"
            case .custom: return "Set your own schedule"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pattern Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SCHEDULE PATTERN")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ForEach(RestDayPattern.allCases, id: \.self) { pattern in
                            Button(action: { 
                                restDayPattern = pattern
                                applyPattern(pattern)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pattern.rawValue)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(pattern.description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if restDayPattern == pattern {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(settings.accentColor.color)
                                    }
                                }
                                .padding()
                                .background(restDayPattern == pattern ? settings.accentColor.color.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WEEKLY PREVIEW")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        WeekPreview(schedule: customSchedule, templates: program.workoutTemplates)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") { 
                        applySchedule()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupInitialSchedule()
        }
    }
    
    private func setupInitialSchedule() {
        // Initialize from existing schedule
        workoutsPerWeek = program.workoutTemplates.count
        // Set up default alternating pattern
        applyPattern(.alternating)
    }
    
    private func applyPattern(_ pattern: RestDayPattern) {
        customSchedule.removeAll()
        let templates = program.workoutTemplates
        
        switch pattern {
        case .alternating:
            // Mon, Wed, Fri for 3 workouts; add Tue, Thu for more
            if templates.count > 0 { customSchedule[1] = templates[0] } // Mon
            if templates.count > 1 { customSchedule[3] = templates[1] } // Wed
            if templates.count > 2 { customSchedule[5] = templates[2] } // Fri
            if templates.count > 3 { customSchedule[2] = templates[3] } // Tue
            if templates.count > 4 { customSchedule[4] = templates[4] } // Thu
            
        case .consecutive:
            // Mon-Tue-Wed-Thu-Fri
            for (index, template) in templates.enumerated() {
                if index < 7 {
                    customSchedule[index + 1] = template
                }
            }
            
        case .weekendRest:
            // Mon-Fri workouts, Sat-Sun rest
            for (index, template) in templates.enumerated() {
                if index < 5 {
                    customSchedule[index + 1] = template
                }
            }
            
        case .custom:
            // Let user manually assign
            break
        }
    }
    
    private func applySchedule() {
        // Regenerate weeks with new schedule
        program.programWeeks.removeAll()
        
        for weekNum in 1...program.durationWeeks {
            let isDeloadWeek = (program.deloadWeek != nil && weekNum == program.deloadWeek)
            let week = ProgramWeek(
                weekNumber: weekNum,
                name: isDeloadWeek ? "Week \(weekNum) - Deload" : "Week \(weekNum)",
                isDeload: isDeloadWeek
            )
            
            // Apply custom schedule
            for day in 1...7 {
                if let template = customSchedule[day] {
                    let workout = ProgramWorkout(
                        dayNumber: day,
                        dayName: template.name,
                        template: template
                    )
                    week.scheduledWorkouts.append(workout)
                } else {
                    let restDay = ProgramWorkout(
                        dayNumber: day,
                        dayName: "Rest Day",
                        isRestDay: true
                    )
                    week.scheduledWorkouts.append(restDay)
                }
            }
            
            program.programWeeks.append(week)
        }
    }
}

struct WeekPreview: View {
    let schedule: [Int: WorkoutTemplate]
    let templates: [WorkoutTemplate]
    @StateObject private var settings = SettingsManager.shared
    
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(1...7, id: \.self) { day in
                HStack {
                    Text(days[day - 1])
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 100, alignment: .leading)
                    
                    if let template = schedule[day] {
                        HStack {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 12))
                            Text(template.name)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(settings.accentColor.color)
                    } else {
                        HStack {
                            Image(systemName: "bed.double")
                                .font(.system(size: 12))
                            Text("Rest Day")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    let container = try! ModelContainer(for: Program.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let program = Program(name: "Sample Program", durationWeeks: 8)
    container.mainContext.insert(program)
    
    return NavigationStack {
        ProgramScheduleView(program: program)
    }
    .modelContainer(container)
}