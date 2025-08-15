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