import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @State private var showingCreateTemplate = false
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Templates")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("\(templates.count) workout plans")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button(action: { 
                            showingCreateTemplate = true
                            settings.impactFeedback(style: .medium)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(settings.accentColor.color)
                                .symbolEffect(.pulse)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Templates Grid
                    if templates.isEmpty {
                        EmptyStateView()
                            .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(templates) { template in
                                TemplateCard(template: template, modelContext: modelContext)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, DesignConstants.Spacing.tabBarClearance)
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView()
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

#Preview {
    TemplatesView()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}