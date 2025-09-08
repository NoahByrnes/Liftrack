import SwiftUI
import SwiftData

struct ProgramCreationRouter: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: CreationOption? = nil
    @StateObject private var settings = SettingsManager.shared
    
    enum CreationOption {
        case smart
        case custom
    }
    
    var body: some View {
        if let option = selectedOption {
            // Show selected creation flow
            switch option {
            case .smart:
                // Smart program selection removed - go directly to custom
                CreateProgramView()
            case .custom:
                CreateProgramView()
            }
        } else {
            // Show selection screen
            NavigationStack {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create New Program")
                            .font(.largeTitle.bold())
                        
                        Text("Choose how you'd like to build your program")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Options
                    VStack(spacing: 16) {
                        // Smart Programs
                        Button(action: { selectedOption = .smart }) {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [settings.accentColor.color, settings.accentColor.color.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.white)
                                }
                                
                                // Text
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Smart Programs")
                                            .font(.headline)
                                        
                                        Text("RECOMMENDED")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green)
                                            .cornerRadius(4)
                                    }
                                    
                                    Text("Choose from proven programs like PPL, 5/3/1, or StrongLifts. We'll customize it to your strength levels.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Custom Program
                        Button(action: { selectedOption = .custom }) {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Text
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Custom Program")
                                        .font(.headline)
                                    
                                    Text("Build your own program from scratch. Select templates and configure progression manually.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Info Box
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(settings.accentColor.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New to training?")
                                .font(.caption.weight(.semibold))
                            Text("Smart Programs are perfect for beginners and intermediate lifters. They handle all the progression math for you.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(settings.accentColor.color.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }
}

#Preview {
    ProgramCreationRouter()
        .modelContainer(for: [Program.self, WorkoutTemplate.self], inMemory: true)
}