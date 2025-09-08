import SwiftUI
import SwiftData

enum LibraryFilter: String, CaseIterable {
    case all = "All"
    case history = "History"
    case templates = "Templates"
    case programs = "Programs"
    
    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .history: return "clock"
        case .templates: return "doc.text"
        case .programs: return "calendar"
        }
    }
}

struct LibraryTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    // All data sources
    @Query(
        filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
        sort: \WorkoutSession.completedAt,
        order: .reverse
    ) private var completedSessions: [WorkoutSession]
    
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query(sort: \Program.createdAt, order: .reverse) private var programs: [Program]
    
    @State private var selectedFilter: LibraryFilter = .all
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var selectedItem: LibraryItem? = nil
    
    @StateObject private var settings = SettingsManager.shared
    
    var filteredItems: [LibraryItem] {
        var items: [LibraryItem] = []
        
        // Add items based on filter
        switch selectedFilter {
        case .all:
            items.append(contentsOf: completedSessions.map { LibraryItem.history($0) })
            items.append(contentsOf: templates.map { LibraryItem.template($0) })
            items.append(contentsOf: programs.map { LibraryItem.program($0) })
        case .history:
            items = completedSessions.map { LibraryItem.history($0) }
        case .templates:
            items = templates.map { LibraryItem.template($0) }
        case .programs:
            items = programs.map { LibraryItem.program($0) }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort by date (most recent first)
        return items.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top padding for header
            Color.clear.frame(height: 40)
            
            // Compact header with search
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search workouts...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LibraryFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                count: getCount(for: filter)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedFilter = filter
                                }
                                settings.selectionFeedback()
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            
            // Content list
            if filteredItems.isEmpty {
                EmptyLibraryView(filter: selectedFilter) {
                    showingCreateSheet = true
                }
            } else {
                List {
                    ForEach(filteredItems) { item in
                        LibraryItemRow(item: item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                handleItemTap(item)
                            }
                    }
                    .onDelete { indexSet in
                        deleteItems(at: indexSet)
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingCreateSheet) {
            CreateItemSheet(filter: selectedFilter)
        }
        .sheet(item: $selectedItem) { item in
            switch item {
            case .history(let session):
                NavigationStack {
                    WorkoutDetailView(session: session)
                }
            case .template(let template):
                NavigationStack {
                    TemplateDetailView(template: template)
                }
            case .program(let program):
                NavigationStack {
                    ProgramDetailView(program: program)
                }
            }
        }
    }
    
    private func getCount(for filter: LibraryFilter) -> Int {
        switch filter {
        case .all:
            return completedSessions.count + templates.count + programs.count
        case .history:
            return completedSessions.count
        case .templates:
            return templates.count
        case .programs:
            return programs.count
        }
    }
    
    private func handleItemTap(_ item: LibraryItem) {
        selectedItem = item
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            switch item {
            case .history(let session):
                modelContext.delete(session)
            case .template(let template):
                modelContext.delete(template)
            case .program(let program):
                modelContext.delete(program)
            }
        }
    }
}

// MARK: - Library Item Wrapper
enum LibraryItem: Identifiable {
    case history(WorkoutSession)
    case template(WorkoutTemplate)
    case program(Program)
    
    var id: String {
        switch self {
        case .history(let session):
            return "history_\(session.id)"
        case .template(let template):
            return "template_\(template.id)"
        case .program(let program):
            return "program_\(program.id)"
        }
    }
    
    var name: String {
        switch self {
        case .history(let session):
            return session.templateName ?? "Quick Workout"
        case .template(let template):
            return template.name
        case .program(let program):
            return program.name
        }
    }
    
    var date: Date {
        switch self {
        case .history(let session):
            return session.completedAt ?? session.startedAt
        case .template(let template):
            return template.lastUsedAt ?? template.createdAt
        case .program(let program):
            return program.createdAt
        }
    }
    
    var type: LibraryFilter {
        switch self {
        case .history:
            return .history
        case .template:
            return .templates
        case .program:
            return .programs
        }
    }
}

// MARK: - Component Views

struct FilterPill: View {
    let filter: LibraryFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 14))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? SettingsManager.shared.accentColor.color : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

struct LibraryItemRow: View {
    let item: LibraryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Circle()
                .fill(typeColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: typeIcon)
                        .font(.system(size: 18))
                        .foregroundColor(typeColor)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                    
                    if case .program(let program) = item, program.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private var typeColor: Color {
        switch item.type {
        case .history: return .blue
        case .templates: return .orange
        case .programs: return .green
        case .all: return .gray
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .history: return "clock"
        case .templates: return "doc.text"
        case .programs: return "calendar"
        case .all: return "square.grid.2x2"
        }
    }
    
    private var subtitle: String {
        switch item {
        case .history(let session):
            let exerciseCount = "\(session.exercises.count) exercises"
            if let duration = session.duration {
                let minutes = Int(duration) / 60
                return "\(exerciseCount) • \(minutes)m"
            }
            return exerciseCount
            
        case .template(let template):
            return "\(template.exercises.count) exercises"
            
        case .program(let program):
            return "\(program.durationWeeks) weeks"
        }
    }
}

struct EmptyLibraryView: View {
    let filter: LibraryFilter
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyTitle)
                .font(.system(size: 18, weight: .semibold))
            
            Text(emptyMessage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if filter != .history {
                Button(action: onCreate) {
                    Text(createButtonTitle)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyIcon: String {
        switch filter {
        case .all: return "tray"
        case .history: return "clock"
        case .templates: return "doc.text"
        case .programs: return "calendar"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No Items Yet"
        case .history: return "No Workout History"
        case .templates: return "No Templates"
        case .programs: return "No Programs"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "Start a workout to see it here"
        case .history: return "Complete your first workout to start tracking"
        case .templates: return "Create templates for quick workout starts"
        case .programs: return "Build structured training programs"
        }
    }
    
    private var createButtonTitle: String {
        switch filter {
        case .templates: return "Create Template"
        case .programs: return "Create Program"
        default: return "Create"
        }
    }
}

struct CreateItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let filter: LibraryFilter
    
    var body: some View {
        NavigationStack {
            Group {
                switch filter {
                case .templates, .all:
                    CreateTemplateView()
                case .programs:
                    CreateProgramView()
                case .history:
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LibraryTabView()
        .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self, Program.self], inMemory: true)
}