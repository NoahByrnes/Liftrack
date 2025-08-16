#!/usr/bin/env swift

import Foundation

// Test to verify the sets add/remove fix
print("=== TESTING SETS FIX ===")
print("")

// Simulating the CreateTemplateView.TempSet structure
struct TempSet: Identifiable {
    let id = UUID()
    var reps: Int = 10
    var weight: Double = 0
}

// Test ForEach stability with direct ID iteration vs enumerated
print("TEST: ForEach Stability")
var sets = [TempSet(), TempSet(), TempSet()]
print("Initial: \(sets.count) sets with IDs:")
for set in sets {
    print("  - \(set.id.uuidString.prefix(8))")
}

// Test add operation
print("\nAdding a set...")
let newSet = TempSet()
sets.append(newSet)
print("After add: \(sets.count) sets")

// Test remove by ID (like the fixed version)
print("\nRemoving set by ID...")
if let firstSet = sets.first {
    if let index = sets.firstIndex(where: { $0.id == firstSet.id }) {
        sets.remove(at: index)
        print("After remove: \(sets.count) sets")
    }
}

// Test multiple operations
print("\nMultiple operations test:")
for i in 1...3 {
    sets.append(TempSet())
    print("  Add #\(i): \(sets.count) sets")
}

for i in 1...2 {
    if !sets.isEmpty {
        sets.removeLast()
        print("  Remove #\(i): \(sets.count) sets")
    }
}

print("\nFinal count: \(sets.count) sets")
print("\n=== TEST COMPLETE ===")