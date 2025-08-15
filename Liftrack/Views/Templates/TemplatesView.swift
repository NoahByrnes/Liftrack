import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @State private var showingCreateTemplate = false
    
    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Workout Templates",
                        systemImage: "list.bullet",
                        description: Text("Create your first workout template to get started")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(templates) { template in
                        NavigationLink(destination: TemplateDetailView(template: template)) {
                            TemplateRow(template: template)
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateTemplate = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView()
            }
        }
    }
    
    private func deleteTemplates(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(templates[index])
            }
        }
    }
}

struct TemplateRow: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            
            if !template.exercises.isEmpty {
                Text(template.exercises.prefix(3).map { $0.exercise.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TemplatesView()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}