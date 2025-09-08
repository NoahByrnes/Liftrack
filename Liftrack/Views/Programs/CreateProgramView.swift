import SwiftUI
import SwiftData

struct CreateProgramView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.name) private var availableTemplates: [WorkoutTemplate]
    @StateObject private var settings = SettingsManager.shared
    
    @State private var programName = ""
    @State private var programDescription = ""
    @State private var durationWeeks = 8
    @State private var selectedTemplates: [WorkoutTemplate] = []
    @State private var includeDeload = false
    @State private var deloadWeek = 4
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Invisible tap area for keyboard dismissal
                    Color.clear
                        .frame(height: 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    
                    VStack(spacing: 24) {
                        // Program Info
                        VStack(alignment: .leading, spacing: 20) {
                            Text("PROGRAM DETAILS")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Program Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("e.g., Push Pull Legs", text: $programName)
                                    .font(.system(size: 17))
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Program goals and notes...", text: $programDescription, axis: .vertical)
                                    .font(.system(size: 17))
                                    .padding()
                                    .lineLimit(2...4)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Duration and Schedule
                        VStack(alignment: .leading, spacing: 20) {
                            Text("DURATION & SCHEDULE")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Duration
                            HStack {
                                Label("Program Duration", systemImage: "calendar")
                                    .font(.system(size: 16))
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    TextField("8", value: $durationWeeks, format: .number)
                                        .font(.system(size: 16, weight: .medium))
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 40)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                        .keyboardType(.numberPad)
                                        .onChange(of: durationWeeks) { _, newValue in
                                            // Limit to reasonable range
                                            if newValue < 1 { durationWeeks = 1 }
                                            if newValue > 52 { durationWeeks = 52 }
                                            // Adjust deload week if needed
                                            if deloadWeek > newValue {
                                                deloadWeek = min(4, newValue)
                                            }
                                        }
                                    
                                    Text("weeks")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            // Workout Selection
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Select Workouts")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Text("\(selectedTemplates.count) selected")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(availableTemplates) { template in
                                            TemplateChip(
                                                template: template,
                                                isSelected: selectedTemplates.contains { $0.id == template.id },
                                                action: { toggleTemplate(template) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Show selected order
                                if !selectedTemplates.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Weekly Schedule Preview")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        ForEach(Array(selectedTemplates.enumerated()), id: \.element.id) { index, template in
                                            HStack {
                                                Text("Day \(index * 2 + 1)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 50)
                                                
                                                Text(template.name)
                                                    .font(.system(size: 15))
                                                
                                                Spacer()
                                                
                                                Button(action: { removeTemplate(template) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Deload Week
                        VStack(alignment: .leading, spacing: 20) {
                            Text("RECOVERY")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $includeDeload) {
                                    Label("Include Deload Week", systemImage: "arrow.down.circle")
                                        .font(.system(size: 16))
                                }
                                .tint(settings.accentColor.color)
                                
                                if includeDeload {
                                    HStack {
                                        Text("Deload on week")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        TextField("4", value: $deloadWeek, format: .number)
                                            .font(.system(size: 16, weight: .medium))
                                            .multilineTextAlignment(.center)
                                            .frame(width: 40)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(6)
                                            .keyboardType(.numberPad)
                                            .onChange(of: deloadWeek) { _, newValue in
                                                // Keep within program duration
                                                if newValue < 1 { deloadWeek = 1 }
                                                if newValue > durationWeeks { deloadWeek = durationWeeks }
                                            }
                                    }
                                    
                                    Text("Deload weeks use 70% of normal weight to aid recovery")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createProgram() }
                        .disabled(programName.isEmpty || selectedTemplates.isEmpty)
                }
            }
        }
    }
    
    private func toggleTemplate(_ template: WorkoutTemplate) {
        if selectedTemplates.contains(where: { $0.id == template.id }) {
            selectedTemplates.removeAll { $0.id == template.id }
        } else {
            selectedTemplates.append(template)
        }
    }
    
    private func removeTemplate(_ template: WorkoutTemplate) {
        selectedTemplates.removeAll { $0.id == template.id }
    }
    
    private func createProgram() {
        let program = Program(
            name: programName,
            description: programDescription,
            durationWeeks: durationWeeks
        )
        
        program.deloadWeek = includeDeload ? deloadWeek : nil
        program.workoutTemplates = selectedTemplates
        
        // Generate the weekly structure
        program.generateWeeks()
        
        modelContext.insert(program)
        try? modelContext.save()
        
        dismiss()
    }
}

struct TemplateChip: View {
    let template: WorkoutTemplate
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? settings.accentColor.color : .secondary)
                
                Text(template.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? settings.accentColor.color : .primary)
                
                Text("(\(template.exercises.count))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? settings.accentColor.color.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? settings.accentColor.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Removed ProgressionOption and ProgressionType dependency

#Preview {
    NavigationStack {
        CreateProgramView()
    }
    .modelContainer(for: [Program.self, WorkoutTemplate.self], inMemory: true)
}