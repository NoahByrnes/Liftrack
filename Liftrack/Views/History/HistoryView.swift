import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.completedAt != nil },
           sort: \WorkoutSession.completedAt, order: .reverse)
    private var completedSessions: [WorkoutSession]
    
    var body: some View {
        NavigationStack {
            List {
                if completedSessions.isEmpty {
                    ContentUnavailableView(
                        "No Workout History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your completed workouts will appear here")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(completedSessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.templateName)
                .font(.headline)
            
            HStack {
                if let completedAt = session.completedAt {
                    Text(completedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let duration = session.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(session.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct SessionDetailView: View {
    let session: WorkoutSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.exerciseName)
                            .font(.headline)
                        
                        ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                            HStack {
                                Text("Set \(set.setNumber)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(set.weight)) lbs × \(set.reps)")
                                if set.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(session.templateName)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}