import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query(sort: \Program.createdAt, order: .reverse) private var programs: [Program]
    @State private var showingCreateTemplate = false
    @State private var showingCreateProgram = false
    @State private var selectedSegment = 0 // 0 for templates, 1 for programs
    @State private var appearAnimation = false
    @State private var buttonScale = 0.8
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                    // Animated Header with visual hierarchy
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Training")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(0.05), value: appearAnimation)
                            
                            Text(selectedSegment == 0 ? 
                                "\(templates.count) workout templates" : 
                                "\(programs.count) training programs")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.8))
                                .opacity(appearAnimation ? 0.8 : 0)
                                .animation(.easeOut(duration: 0.3).delay(0.1), value: appearAnimation)
                        }
                        Spacer()
                        
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                buttonScale = 0.9
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                buttonScale = 1.0
                            }
                            
                            if selectedSegment == 0 {
                                showingCreateTemplate = true
                            } else {
                                showingCreateProgram = true
                            }
                            settings.impactFeedback(style: .medium)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(settings.accentColor.color)
                                .scaleEffect(buttonScale)
                                .opacity(appearAnimation ? 1 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: appearAnimation)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Animated Segmented Control
                    Picker("View", selection: $selectedSegment.animation(.spring(response: 0.3, dampingFraction: 0.8))) {
                        Text("Templates").tag(0)
                        Text("Programs").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .scaleEffect(appearAnimation ? 1 : 0.95)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
                    
                    // Content based on selection
                    if selectedSegment == 0 {
                        // Templates View
                        if templates.isEmpty {
                            EmptyStateView()
                                .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                                    TemplateCard(template: template, modelContext: modelContext)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                        .opacity(appearAnimation ? 1 : 0)
                                        .offset(y: appearAnimation ? 0 : 30)
                                        .animation(
                                            .spring(response: 0.4, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.05 + 0.2),
                                            value: appearAnimation
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Programs View
                        if programs.isEmpty {
                            EmptyProgramsStateView(onCreateTap: { showingCreateProgram = true })
                                .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 20) {
                                // Active Program
                                if let activeProgram = programs.first(where: { $0.isActive }) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("ACTIVE PROGRAM")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                            .opacity(appearAnimation ? 1 : 0)
                                            .animation(.easeOut(duration: 0.3).delay(0.2), value: appearAnimation)
                                        
                                        NavigationLink(destination: ProgramDetailView(program: activeProgram)) {
                                            ActiveProgramCard(program: activeProgram)
                                        }
                                        .opacity(appearAnimation ? 1 : 0)
                                        .offset(y: appearAnimation ? 0 : 30)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: appearAnimation)
                                    }
                                }
                                
                                // Other Programs
                                let inactivePrograms = programs.filter { !$0.isActive }
                                if !inactivePrograms.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(programs.contains { $0.isActive } ? "OTHER PROGRAMS" : "ALL PROGRAMS")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                        
                                        ForEach(Array(inactivePrograms.enumerated()), id: \.element.id) { index, program in
                                            NavigationLink(destination: ProgramDetailView(program: program)) {
                                                ProgramCard(program: program)
                                            }
                                            .opacity(appearAnimation ? 1 : 0)
                                            .offset(y: appearAnimation ? 0 : 30)
                                            .animation(
                                                .spring(response: 0.4, dampingFraction: 0.8)
                                                .delay(Double(index) * 0.05 + 0.3),
                                                value: appearAnimation
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, DesignConstants.Spacing.tabBarClearance)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                withAnimation {
                    appearAnimation = true
                    buttonScale = 1.0
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView()
            }
            .sheet(isPresented: $showingCreateProgram) {
                ProgramCreationRouter()
            }
            }
        }
    }
}

struct TemplateCard: View {
    let template: WorkoutTemplate
    let modelContext: ModelContext
    @State private var isPressed = false
    @State private var showingDeleteAlert = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        NavigationLink(destination: TemplateDetailView(template: template)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(template.name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if !template.templateDescription.isEmpty {
                            Text(template.templateDescription)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        HStack(spacing: 16) {
                            Label("\(template.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if let lastUsed = template.lastUsedAt {
                                Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(settings.accentColor.color.opacity(0.8))
                }
                
                // Exercise preview
                if !template.exercises.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(template.exercises.prefix(3).sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                            Text(exercise.exercise.name)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(settings.accentColor.color.opacity(0.1))
                                .foregroundColor(settings.accentColor.color)
                                .clipShape(Capsule())
                        }
                        
                        if template.exercises.count > 3 {
                            Text("+\(template.exercises.count - 3)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.primary.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Template", systemImage: "trash")
            }
        }
        .alert("Delete Template?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation(.spring()) {
                    modelContext.delete(template)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("This will permanently delete the template.")
        }
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct EmptyStateView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(settings.accentColor.color.opacity(0.5))
            
            Text("No Templates Yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            
            Text("Create your first workout template\nto get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct EmptyProgramsStateView: View {
    let onCreateTap: () -> Void
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(settings.accentColor.color.opacity(0.5))
            
            Text("No Programs Yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
            
            Text("Create a structured training program\nto track your progress over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateTap) {
                Text("Create Your First Program")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(settings.accentColor.color)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
    }
}

#Preview {
    TemplatesView()
        .modelContainer(for: [WorkoutTemplate.self, Program.self], inMemory: true)
}