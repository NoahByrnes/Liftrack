//
//  LiftrackWidgetLiveActivity.swift
//  LiftrackWidget
//
//  Created by Noah Grant-Byrnes on 2025-08-19.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiftrackWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen/Notification UI
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - when long pressed
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Text(context.attributes.workoutName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(context.state.currentExercise)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if context.state.isResting {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                if let endTime = context.state.restEndTime {
                                    Text(endTime, style: .timer)
                                        .font(.system(.title3, design: .monospaced))
                                        .foregroundColor(.orange)
                                        .multilineTextAlignment(.center)
                                        .monospacedDigit()
                                } else {
                                    Text(formatTime(context.state.restTimeRemaining))
                                        .font(.system(.title3, design: .monospaced))
                                        .foregroundColor(.orange)
                                }
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(formatTime(context.state.totalElapsedTime))
                                    .font(.system(.body, design: .monospaced))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isResting {
                        Image(systemName: "pause.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                
            } compactLeading: {
                // Compact leading - left side of Dynamic Island
                Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(context.state.isResting ? .orange : .green)
            } compactTrailing: {
                // Compact trailing - right side of Dynamic Island
                if context.state.isResting {
                    if let endTime = context.state.restEndTime {
                        Text(endTime, style: .timer)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .monospacedDigit()
                            .frame(width: 32)
                    } else {
                        Text("\(context.state.restTimeRemaining)s")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .monospacedDigit()
                    }
                } else {
                    Text(formatCompactTime(context.state.totalElapsedTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            } minimal: {
                // Minimal UI - just the icon
                Image(systemName: context.state.isResting ? "timer.circle.fill" : "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(context.state.isResting ? .orange : .green)
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatCompactTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text(context.attributes.workoutName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Total workout time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(formatTime(context.state.totalElapsedTime))
                        .font(.system(.caption, design: .monospaced))
                }
                .foregroundColor(.secondary)
            }
            
            // Current Exercise
            Text(context.state.currentExercise)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            // Rest Timer or Status
            if context.state.isResting {
                HStack {
                    Label("Rest Timer", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    if let endTime = context.state.restEndTime {
                        Text(endTime, style: .timer)
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    } else {
                        Text(formatTime(context.state.restTimeRemaining))
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
            } else {
                HStack {
                    Label("Working", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}