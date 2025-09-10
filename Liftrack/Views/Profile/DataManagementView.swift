import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct DataManagementView: View {
    @Query private var workoutSessions: [WorkoutSession]
    @Query private var templates: [WorkoutTemplate]
    @Query private var exercises: [Exercise]
    @StateObject private var settings = SettingsManager.shared
    @State private var showExportSuccess = false
    @State private var showDeleteAlert = false
    @State private var exportType: ExportType = .csv
    @State private var isExporting = false
    @State private var exportedDocument: ExportDocument?
    @State private var isImporting = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var importedCount = (workouts: 0, templates: 0, exercises: 0)
    @Environment(\.modelContext) private var modelContext
    
    enum ExportType {
        case csv, json
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                exportSection
                importSection
                storageSection
            }
            .padding()
        }
        .navigationTitle("Data & Backup")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Export Successful", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your workout data has been exported successfully.")
        }
        .alert("Import Successful", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Imported \(importedCount.workouts) workouts, \(importedCount.templates) templates, and \(importedCount.exercises) exercises.")
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your workouts, templates, and exercises. This action cannot be undone.")
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportedDocument,
            contentType: exportType == .json ? .json : .commaSeparatedText,
            defaultFilename: "Liftrack_\(exportType == .json ? "Backup" : "Export")_\(Date().formatted(date: .abbreviated, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
        ) { result in
            switch result {
            case .success:
                showExportSuccess = true
            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    importJSON(from: file)
                }
            case .failure(let error):
                importErrorMessage = "Failed to select file: \(error.localizedDescription)"
                showImportError = true
            }
        }
    }
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export Data", systemImage: "square.and.arrow.up")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                exportButton(
                    icon: "doc.text",
                    title: "Export to CSV",
                    subtitle: "Export workout history as spreadsheet",
                    color: .blue,
                    action: {
                        exportType = .csv
                        exportCSV()
                    }
                )
                
                Divider()
                    .padding(.horizontal)
                
                exportButton(
                    icon: "doc.badge.arrow.up",
                    title: "Export to JSON",
                    subtitle: "Create complete backup file",
                    color: .green,
                    action: {
                        exportType = .json
                        exportJSON()
                    }
                )
            }
            #if os(iOS)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            #else
            .background(Color.gray.opacity(0.2))
            #endif
            .cornerRadius(16)
        }
    }
    
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Import Data", systemImage: "square.and.arrow.down")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Button(action: {
                    isImporting = true
                    SettingsManager.shared.impactFeedback()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .frame(width: 30)
                            .foregroundColor(.indigo)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import from JSON")
                                .foregroundColor(.primary)
                            Text("Restore from backup file")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            #if os(iOS)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            #else
            .background(Color.gray.opacity(0.2))
            #endif
            .cornerRadius(16)
        }
    }
    
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Storage", systemImage: "externaldrive")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                storageInfo
                
                Divider()
                    .padding(.horizontal)
                
                clearDataButton
            }
            #if os(iOS)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            #else
            .background(Color.gray.opacity(0.2))
            #endif
            .cornerRadius(16)
        }
    }
    
    private func exportButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            SettingsManager.shared.impactFeedback()
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private var storageInfo: some View {
        HStack {
            Image(systemName: "chart.pie")
                .frame(width: 30)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Storage Used")
                    .foregroundColor(.primary)
                Text("\(workoutSessions.count) workouts, \(templates.count) templates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var clearDataButton: some View {
        Button(action: {
            showDeleteAlert = true
            #if os(iOS)
            SettingsManager.shared.impactFeedback(style: .heavy)
            #else
            SettingsManager.shared.impactFeedback()
            #endif
        }) {
            HStack {
                Image(systemName: "trash")
                    .frame(width: 30)
                    .foregroundColor(.red)
                
                Text("Clear All Data")
                    .foregroundColor(.red)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    // MARK: - Export Functions
    private func exportCSV() {
        var csvString = "Date,Workout,Exercise,Set,Weight (lbs),Reps,Warmup,Completed,Duration (min),Notes\n"
        
        let sortedSessions = workoutSessions
            .filter { $0.completedAt != nil }
            .sorted(by: { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) })
        
        for session in sortedSessions {
            let dateString = session.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let duration = Int((session.duration ?? 0) / 60)
            
            for exercise in session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                for set in exercise.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    csvString += "\"\(dateString)\","
                    csvString += "\"\(session.templateName)\","
                    csvString += "\"\(exercise.exerciseName)\","
                    csvString += "\(set.setNumber),"
                    csvString += "\(set.weight),"
                    csvString += "\(set.reps),"
                    csvString += "\(set.isWarmup ? "Yes" : "No"),"
                    csvString += "\(set.isCompleted ? "Yes" : "No"),"
                    csvString += "\(duration),"
                    csvString += "\"\(set.notes)\"\n"
                }
            }
        }
        
        exportedDocument = ExportDocument(text: csvString)
        isExporting = true
    }
    
    private func exportJSON() {
        let exportData = LiftrackExportData(
            exportDate: Date(),
            version: "1.0",
            workouts: workoutSessions.map { WorkoutExport(from: $0) },
            templates: templates.map { TemplateExport(from: $0) },
            exercises: exercises.map { ExerciseExport(from: $0) }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        if let jsonData = try? encoder.encode(exportData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            exportedDocument = ExportDocument(text: jsonString)
            isExporting = true
        }
    }
    
    // MARK: - Import Functions
    private func importJSON(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importErrorMessage = "Cannot access the selected file"
            showImportError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let importData = try decoder.decode(LiftrackExportData.self, from: data)
            
            // Reset counters
            importedCount = (workouts: 0, templates: 0, exercises: 0)
            
            // Import exercises first (as they're referenced by templates and workouts)
            var exerciseMapping: [UUID: Exercise] = [:]
            for exerciseExport in importData.exercises {
                // Check if exercise already exists
                if let existingExercise = exercises.first(where: { $0.name == exerciseExport.name }) {
                    exerciseMapping[exerciseExport.id] = existingExercise
                } else {
                    // Create new exercise
                    let newExercise = Exercise(
                        name: exerciseExport.name,
                        defaultRestSeconds: exerciseExport.defaultRestSeconds
                    )
                    modelContext.insert(newExercise)
                    exerciseMapping[exerciseExport.id] = newExercise
                    importedCount.exercises += 1
                }
            }
            
            // Import templates
            for templateExport in importData.templates {
                // Check if template already exists
                if !templates.contains(where: { $0.id == templateExport.id }) {
                    let newTemplate = WorkoutTemplate(name: templateExport.name)
                    newTemplate.id = templateExport.id
                    newTemplate.createdAt = templateExport.createdAt
                    newTemplate.lastUsedAt = templateExport.lastUsedAt
                    modelContext.insert(newTemplate)
                    importedCount.templates += 1
                }
            }
            
            // Import workouts
            for workoutExport in importData.workouts {
                // Create new workout session
                let newSession = WorkoutSession()
                newSession.id = workoutExport.id
                newSession.templateName = workoutExport.templateName
                newSession.startedAt = workoutExport.startedAt
                newSession.completedAt = workoutExport.completedAt
                
                // Import exercises and sets
                for exerciseExport in workoutExport.exercises {
                    // Find the corresponding Exercise object
                    if let exercise = exercises.first(where: { $0.name == exerciseExport.exerciseName }) {
                        let sessionExercise = SessionExercise(
                            exercise: exercise,
                            orderIndex: exerciseExport.orderIndex,
                            customRestSeconds: exerciseExport.restSeconds
                        )
                        
                        // Import sets
                        for setExport in exerciseExport.sets {
                            let workoutSet = WorkoutSet(
                                setNumber: setExport.setNumber,
                                weight: setExport.weight,
                                reps: setExport.reps,
                                isWarmup: setExport.isWarmup
                            )
                            workoutSet.isCompleted = setExport.isCompleted
                            workoutSet.notes = setExport.notes
                            sessionExercise.sets.append(workoutSet)
                        }
                        
                        newSession.exercises.append(sessionExercise)
                    }
                }
                
                modelContext.insert(newSession)
                importedCount.workouts += 1
            }
            
            // Save all changes
            try modelContext.save()
            showImportSuccess = true
            
        } catch {
            importErrorMessage = "Failed to import data: \(error.localizedDescription)"
            showImportError = true
        }
    }
    
    private func deleteAllData() {
        // Delete all workouts
        for session in workoutSessions {
            modelContext.delete(session)
        }
        
        // Delete all templates
        for template in templates {
            modelContext.delete(template)
        }
        
        // Delete custom exercises (keep seeded ones)
        let seededExerciseNames = [
            "Bench Press (Barbell)", "Squat (Barbell)", "Deadlift (Barbell)",
            "Overhead Press (Barbell)", "Bent Over Row (Barbell)", "Pull-ups",
            "Dips", "Bicep Curls (Dumbbell)", "Tricep Extensions", "Leg Press"
        ]
        
        for exercise in exercises {
            if !seededExerciseNames.contains(exercise.name) {
                modelContext.delete(exercise)
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - Export Document
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Export Data Models
struct LiftrackExportData: Codable {
    let exportDate: Date
    let version: String
    let workouts: [WorkoutExport]
    let templates: [TemplateExport]
    let exercises: [ExerciseExport]
}

struct WorkoutExport: Codable {
    let id: UUID
    let templateName: String
    let startedAt: Date
    let completedAt: Date?
    let duration: TimeInterval?
    let exercises: [SessionExerciseExport]
    
    init(from session: WorkoutSession) {
        self.id = session.id
        self.templateName = session.templateName
        self.startedAt = session.startedAt
        self.completedAt = session.completedAt
        self.duration = session.duration
        self.exercises = session.exercises.map { SessionExerciseExport(from: $0) }
    }
}

struct SessionExerciseExport: Codable {
    let exerciseName: String
    let orderIndex: Int
    let restSeconds: Int
    let sets: [SetExport]
    
    init(from exercise: SessionExercise) {
        self.exerciseName = exercise.exerciseName
        self.orderIndex = exercise.orderIndex
        self.restSeconds = exercise.restSeconds
        self.sets = exercise.sets.map { SetExport(from: $0) }
    }
}

struct SetExport: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isCompleted: Bool
    let isWarmup: Bool
    let notes: String
    
    init(from set: WorkoutSet) {
        self.setNumber = set.setNumber
        self.weight = set.weight
        self.reps = set.reps
        self.isCompleted = set.isCompleted
        self.isWarmup = set.isWarmup
        self.notes = set.notes
    }
}

struct TemplateExport: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    let lastUsedAt: Date?
    let exerciseCount: Int
    
    init(from template: WorkoutTemplate) {
        self.id = template.id
        self.name = template.name
        self.createdAt = template.createdAt
        self.lastUsedAt = template.lastUsedAt
        self.exerciseCount = template.exercises.count
    }
}

struct ExerciseExport: Codable {
    let id: UUID
    let name: String
    let defaultRestSeconds: Int
    let createdAt: Date
    
    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.defaultRestSeconds = exercise.defaultRestSeconds
        self.createdAt = exercise.createdAt
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutTemplate.self, Exercise.self], inMemory: true)
}