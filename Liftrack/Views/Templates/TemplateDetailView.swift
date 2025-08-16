import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 {
            return "\(mins)m \(secs)s"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(secs)s"
        }
    }
    
    var body: some View {
        List {
            if !template.templateDescription.isEmpty {
                Section("Description") {
                    Text(template.templateDescription)
                        .font(.body)
                }
            }
            
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
                        
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                            Text("Rest: \(formatRestTime(exercise.restSeconds))")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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