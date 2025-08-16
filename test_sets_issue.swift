// Test script to simulate and log the sets add/remove issue
import Foundation

// Simulating the CreateTemplateView scenario
print("=== TESTING SETS ADD/REMOVE ISSUE ===")
print("")

// Test data structure
struct TempSet: Identifiable {
    let id = UUID()
    var reps: Int = 10
    var weight: Double = 0
}

struct TempExercise {
    var sets: [TempSet] = [TempSet(), TempSet(), TempSet()]
}

// Test scenario
var exercise = TempExercise()

print("Initial state: \(exercise.sets.count) sets")
print("Set IDs: \(exercise.sets.map { $0.id.uuidString.prefix(8) }.joined(separator: ", "))")
print("")

// Test 1: Add a set
print("TEST 1: Adding a set")
let beforeAdd = exercise.sets.count
exercise.sets.append(TempSet())
let afterAdd = exercise.sets.count
print("  Before: \(beforeAdd), After: \(afterAdd)")
print("  Set IDs: \(exercise.sets.map { $0.id.uuidString.prefix(8) }.joined(separator: ", "))")
print("")

// Test 2: Remove a set by ID
print("TEST 2: Removing a set by ID")
if let setToRemove = exercise.sets.first {
    let beforeRemove = exercise.sets.count
    exercise.sets.removeAll(where: { $0.id == setToRemove.id })
    let afterRemove = exercise.sets.count
    print("  Before: \(beforeRemove), After: \(afterRemove)")
    print("  Set IDs: \(exercise.sets.map { $0.id.uuidString.prefix(8) }.joined(separator: ", "))")
}
print("")

// Test 3: Multiple adds
print("TEST 3: Adding 3 sets in succession")
for i in 1...3 {
    let before = exercise.sets.count
    exercise.sets.append(TempSet())
    let after = exercise.sets.count
    print("  Add #\(i): Before=\(before), After=\(after)")
}
print("  Final count: \(exercise.sets.count)")
print("  Set IDs: \(exercise.sets.map { $0.id.uuidString.prefix(8) }.joined(separator: ", "))")
print("")

// Test 4: Using enumerated array with ForEach simulation
print("TEST 4: Simulating ForEach with enumerated array")
let enumeratedSets = Array(exercise.sets.enumerated())
print("  Enumerated count: \(enumeratedSets.count)")
for (index, set) in enumeratedSets {
    print("    Index: \(index), ID: \(set.id.uuidString.prefix(8))")
}

// Now modify while "iterating"
print("  Removing at index 2...")
if exercise.sets.count > 2 {
    exercise.sets.remove(at: 2)
}
print("  New count: \(exercise.sets.count)")
print("")

print("=== FINAL STATE ===")
print("Exercise has \(exercise.sets.count) sets")
print("Set IDs: \(exercise.sets.map { $0.id.uuidString.prefix(8) }.joined(separator: ", "))")