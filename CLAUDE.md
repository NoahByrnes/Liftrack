# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Liftrack is a native iOS/macOS SwiftUI application supporting multiple Apple platforms (iOS 18.5+, macOS 15.5+, visionOS). The project uses Xcode's native build system and is configured as a universal app.

## Common Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project Liftrack.xcodeproj -scheme Liftrack -configuration Debug build

# Build for specific platform
xcodebuild -project Liftrack.xcodeproj -scheme Liftrack -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild -project Liftrack.xcodeproj -scheme Liftrack -destination 'platform=macOS'

# Clean build folder
xcodebuild -project Liftrack.xcodeproj -scheme Liftrack clean
```

### Testing
```bash
# Run all tests
xcodebuild test -project Liftrack.xcodeproj -scheme Liftrack -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test
xcodebuild test -project Liftrack.xcodeproj -scheme Liftrack -only-testing:LiftrackTests/TestClassName/testMethodName

# Run UI tests
xcodebuild test -project Liftrack.xcodeproj -scheme Liftrack -only-testing:LiftrackUITests
```

### Code Quality
```bash
# Format Swift code (requires swift-format)
swift-format -i -r Liftrack/ LiftrackTests/ LiftrackUITests/

# Lint Swift code (requires SwiftLint)
swiftlint lint --path Liftrack
```

## Architecture

### Project Structure
- **Liftrack/**: Main app source code
  - `LiftrackApp.swift`: App entry point using SwiftUI App lifecycle
  - `ContentView.swift`: Root view of the application
  - `Assets.xcassets/`: Visual assets including app icons for all platforms
  - `Liftrack.entitlements`: App sandbox permissions

- **LiftrackTests/**: Unit tests using Swift Testing framework
- **LiftrackUITests/**: UI automation tests using XCTest

### Key Technical Details
- **UI Framework**: SwiftUI with @main App lifecycle
- **Testing**: Dual approach using modern Swift Testing (async/await) and XCTest for UI
- **Security**: App Sandbox enabled with read-only file system access
- **Platforms**: Universal app supporting iOS, macOS, and visionOS from single codebase
- **Development Team ID**: 5DGLFC4WVM (for code signing)

### SwiftUI Development Patterns
- Views should be defined in separate files within the Liftrack folder
- Use SwiftUI previews for rapid development iteration
- Follow Apple's SwiftUI best practices for state management (@State, @Binding, @ObservableObject)
- Leverage the universal app structure to share code across platforms

### Testing Approach
- Unit tests use the modern Swift Testing framework with `#expect` assertions
- UI tests use XCTest with XCUIApplication
- Performance tests measure app launch time
- Test files follow the pattern: `[FeatureName]Tests.swift`

## Important Notes
- This is a pure Swift/SwiftUI project with no external dependencies
- The project uses Xcode's native build system (no Swift Package Manager setup yet)
- App icons are already configured for both iOS and macOS platforms
- The app sandbox is configured for security from the start

## Critical SwiftUI Patterns

### Button vs onTapGesture in ForEach
**Problem**: When using `Button` components inside a `ForEach` loop in SwiftUI, the button closures can capture stale indices or trigger multiple buttons simultaneously. This is a known SwiftUI issue with view identity and closure capture.

**Solution**: Always use `onTapGesture` instead of `Button` for interactive elements inside `ForEach` loops.

**Example of the issue (BAD):**
```swift
ForEach(items.indices, id: \.self) { index in
    Button(action: { 
        // This closure captures index at creation time
        // Can trigger wrong item or multiple items
        removeItem(at: index) 
    }) {
        Text("Remove")
    }
}
```

**Correct implementation (GOOD):**
```swift
ForEach(items, id: \.id) { item in
    Text("Remove")
        .onTapGesture {
            // This executes with current state
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                removeItem(at: index)
            }
        }
}
```

**Key Points:**
- Use `onTapGesture` for ALL interactive elements in ForEach loops
- Iterate over objects directly, not indices
- Look up current index when needed using `firstIndex(where:)`
- Add `.contentShape(Rectangle())` or `.contentShape(Circle())` to ensure proper tap targets
- This pattern was critical for fixing the sets add/remove buttons in CreateTemplateView

## Architecture Guidelines - CRITICAL

### Core vs Optional Features
**Problem Prevention**: The codebase previously had "smart" features (AI, progression calculations, etc.) deeply embedded in core models, making them impossible to disable without breaking everything.

**Strict Rules**:
1. **Core models must be minimal** - Only include fields that are absolutely essential for basic functionality
2. **Use composition over modification** - Advanced features should EXTEND core models, not modify them
3. **Feature flags from the start** - Any "smart" or advanced feature must be behind a feature flag

**Example of GOOD architecture**:
```swift
// Core model - minimal, essential fields only
@Model
final class WorkoutSet {
    var id: UUID
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    // That's it! No RPE, no targetWeight, no progression fields
}

// Smart features in separate extension (in SmartFeatures.swift)
extension WorkoutSet {
    struct SmartMetrics {
        var rpe: Int?
        var targetWeight: Double?
        var performanceScore: Double?
    }
    // Smart features are OPTIONAL additions, not core
}
```

**Example of BAD architecture** (what we just fixed):
```swift
// Don't do this - mixing core and smart features
@Model
final class WorkoutSet {
    var weight: Double
    var reps: Int
    var rpe: Int? // ❌ Smart feature in core model
    var targetWeight: Double // ❌ Progression feature in core
    var isFailed: Bool // ❌ Advanced tracking in core
}
```

### Dependency Management
**When adding new features**:
1. Ask: "Can the app work without this?" If yes, it's not core
2. Ask: "Will removing this break basic functionality?" If yes, you've coupled too tightly
3. Use protocols/extensions for optional features, not direct model modifications
4. Keep UI components modular - a view that uses smart features should be separate from core views

### File Organization for Features
**Disabled Features Pattern**: When temporarily disabling features:
- Rename to `.disabled` extension (e.g., `MagicWorkoutView.swift.disabled`)
- Don't just comment out - Xcode still tries to compile .swift files
- Keep related components together so they can be re-enabled as a unit

### Testing Build After Major Changes
After removing or adding features, ALWAYS:
1. Run a clean build: `xcodebuild clean`
2. Check for cascading dependencies
3. Don't try to fix all errors at once - disable entire feature chains if needed

### Hierarchy Principles
**The app follows this strict hierarchy**:
```
Sets → Exercises → Workouts → Programs (optional) → Program Library
```

- **WorkoutSet**: Atomic unit of work (weight, reps, completed state)
- **SessionExercise**: Exercise containing multiple sets
- **WorkoutSession**: Single workout (may reference a program)
- **WorkoutTemplate**: Reusable workout blueprint
- **Program**: Container for scheduled workouts over time
- **Program Library**: User's collection of programs

Each level should only know about the level directly below it. Programs shouldn't directly manipulate sets, for example.