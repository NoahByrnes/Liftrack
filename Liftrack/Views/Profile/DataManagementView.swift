import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DataManagementView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showExportAlert = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                exportSection
                storageSection
            }
            .padding()
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        .navigationTitle("Data & Backup")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Export Coming Soon", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Export functionality will be available in a future update.")
        }
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                // TODO: Implement data deletion
            }
        } message: {
            Text("This will permanently delete all your workouts, templates, and exercises. This action cannot be undone.")
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
                    color: .blue
                )
                
                Divider()
                    .padding(.horizontal)
                
                exportButton(
                    icon: "doc.badge.arrow.up",
                    title: "Backup All Data",
                    subtitle: "Create complete backup file",
                    color: .green
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
    
    private func exportButton(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button(action: {
            showExportAlert = true
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
                Text("~2.5 MB")
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
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
}