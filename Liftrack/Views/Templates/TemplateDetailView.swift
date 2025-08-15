import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    
    var body: some View {
        List {
            Section("Exercises") {
                ForEach(template.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exercise.name)
                            .font(.headline)
                        
                        HStack {
                            Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let weight = exercise.targetWeight, weight > 0 {
                                Text("@ \(Int(weight)) lbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if let lastUsed = template.lastUsedAt {
                Section("Info") {
                    HStack {
                        Text("Last Used")
                        Spacer()
                        Text(lastUsed, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            Text("Edit Template Coming Soon")
        }
    }
}

struct TemplatePickerView: View {
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Environment(\.dismiss) private var dismiss
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    Button(action: { 
                        onSelect(template)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(template.exercises.count) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(template: WorkoutTemplate(name: "Sample"))
            .modelContainer(for: WorkoutTemplate.self, inMemory: true)
    }
}