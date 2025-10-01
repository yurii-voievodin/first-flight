# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FirstFlight is an iOS SpriteKit game app that targets iPhone devices. The project uses UIKit with SpriteKit for 2D game development and includes a basic touch-based interaction system with rotating shape nodes.

## Project Structure

- `FirstFlight/` - Main app source code
  - `AppDelegate.swift` - Application lifecycle management
  - `GameViewController.swift` - Main view controller that presents the SpriteKit scene
  - `GameScene.swift` - Main game scene with touch interaction and animated shape nodes
  - `GameScene.sks` - SpriteKit scene file
  - `Actions.sks` - SpriteKit actions file
  - `Assets.xcassets` - App icons and other visual assets
  - `Base.lproj/` - Storyboard files for UI layout
- `FirstFlightTests/` - Unit tests
- `FirstFlightUITests/` - UI automation tests

## Development Commands

### Build Commands
```bash
# Build for iOS simulator
xcodebuild -project FirstFlight.xcodeproj -scheme FirstFlight -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' build

# Build for device
xcodebuild -project FirstFlight.xcodeproj -scheme FirstFlight -configuration Release build
```

### Test Commands
```bash
# Run unit tests
xcodebuild test -project FirstFlight.xcodeproj -scheme FirstFlight -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# Run only unit tests (excluding UI tests)
xcodebuild test -project FirstFlight.xcodeproj -scheme FirstFlight -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:FirstFlightTests

# Run only UI tests
xcodebuild test -project FirstFlight.xcodeproj -scheme FirstFlight -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:FirstFlightUITests
```

## Project Configuration

- **Platform**: iOS (iPhone only)
- **Language**: Swift 5.0
- **Minimum iOS Version**: 26.0 (iOS 18.0)
- **Bundle ID**: `io.github.yurii-voievodin.FirstFlight`
- **Development Team**: M2BF9ZE9NW
- **App Category**: Adventure Games
- **Supported Orientations**: Landscape Left/Right (iPhone), All orientations (iPad)

## Architecture Notes

- Uses SpriteKit for game rendering with a single `GameScene`
- Touch interaction creates animated rotating shapes at touch points
- Scene loads from `GameScene.sks` file with asset-based configuration
- Status bar is hidden for immersive game experience
- Debug mode shows FPS and node count overlays
- Don't build a project until I ask it directly