# Repository Guidelines

## Project Structure & Module Organization
- `FirstFlight/Application` holds app lifecycle glue (`AppDelegate.swift`) and is the entry point for SpriteKit configuration.
- `FirstFlight/Game` contains gameplay logic (scene setup, physics categories, map loading, and entity models such as `Spider.swift`).
- `FirstFlight/Shapes` defines reusable SpriteKit nodes for rocks and player geometry.
- `FirstFlight/Maps` stores JSON map definitions (currently `Map1.json`), while `Assets.xcassets` keeps art and color sets.
- Tests live in `FirstFlightTests` (swift-testing specs) and `FirstFlightUITests` (XCTest UI flows).

## Build, Test, and Development Commands
- `xcodebuild -project FirstFlight.xcodeproj -scheme FirstFlight -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build` compiles the game for the simulator.
- `xcodebuild ... test` runs both `Testing` and `XCTest` suites; replace `...` with the build command above.
- `xed .` opens the project in Xcode; use the FirstFlight scheme for running the SpriteKit scene.
- For quick map tweaks, edit `FirstFlight/Maps/Map1.json` then relaunch the simulator to reload layout data.

## Coding Style & Naming Conventions
- Swift 5 conventions: 4-space indentation, braces on same line, and meaningful type names in PascalCase (`RockFormation`).
- Functions, variables, and JSON keys stay camelCase; prefer `let` for immutability and `struct` for value semantics.
- Keep SpriteKit node setup and configuration in focused helpers (see `GameScene.setupScene()` for the pattern).
- No repo-wide linter is configured; rely on Xcode warnings and run "Editor > Structure > Re-Indent" before committing.

## Testing Guidelines
- Unit tests use the new `Testing` framework; group them by feature and prefix with `@Test` (`FirstFlightTests/example`).
- UI tests remain under XCTest; name methods with the scenario + expectation (`testExample`, `testLaunchPerformance`).
- Run targeted suites via `xcodebuild -scheme FirstFlightTests test` or from Xcode's Test navigator.
- Aim to cover new gameplay rules and map parsing branches; include regressions that reproduce prior physics bugs.

## Commit & Pull Request Guidelines
- Follow the existing log style: short present-tense summaries (~55 chars) describing the change ("Simplify spider gait animation...").
- Reference related issues in the body and call out gameplay or asset updates explicitly.
- PRs should include: summary of behavior change, simulator/device tested, screenshots or screen recordings for visual tweaks, and any map JSON updates.
- Request review from another agent before merge; ensure CI (xcodebuild test) is green and attach build logs when failures occur.
