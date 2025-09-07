# Repository Guidelines

## Project Structure & Module Organization
- iOS app sources: `work_out_watch/` (SwiftUI views, Core Data, HealthKit).
- watchOS app sources: `work_out_watch Watch App/` (companion app + sync).
- Tests: `work_out_watchTests/`, `work_out_watchUITests/`, `work_out_watch Watch AppTests/`, `work_out_watch Watch AppUITests/`.
- Assets: `*/Assets.xcassets` per target; Core Data model: `*/WorkoutDataModel.xcdatamodeld`.
- Xcode project: `work_out_watch.xcodeproj`. See `データ永続化システム.md` for persistence notes.

## Build, Test, and Development Commands
- Open in Xcode: `xed .` then select the desired scheme (iOS app or Watch App).
- CLI build (iOS):
  - `xcodebuild -project work_out_watch.xcodeproj -scheme work_out_watch -destination 'platform=iOS Simulator,name=iPhone 15' build`
- CLI build (watchOS):
  - `xcodebuild -project work_out_watch.xcodeproj -scheme 'work_out_watch Watch App' -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build`
- Run tests (adjust destinations to installed simulators):
  - `xcodebuild -project work_out_watch.xcodeproj -scheme work_out_watch -destination 'platform=iOS Simulator,name=iPhone 15' test`

## Coding Style & Naming Conventions
- Language: Swift 5+, SwiftUI.
- Indentation: 4 spaces; line length ~120 chars.
- Names: `PascalCase` for types; `camelCase` for vars/functions; constants `camelCase` with `let`.
- Files: one major type per file named after the type (e.g., `StatisticsView.swift`). SwiftUI views end with `View`.
- Organize by feature; keep watch-specific code in the Watch App target. Use `#if os(watchOS)` where needed.

## Testing Guidelines
- Framework: XCTest + XCUITest.
- Location: unit tests in `*Tests`, UI tests in `*UITests`.
- Naming: test files end with `Tests.swift`; methods `test_...()` and describe behavior.
- Running: via Product > Test in Xcode or `xcodebuild ... test`. Prefer deterministic tests (no HealthKit network).

## Commit & Pull Request Guidelines
- Commits: imperative mood, concise summary (<72 chars), body explains rationale when non-trivial.
  - Example: `Refactor InputView layout to simplify weight controls`
- PRs: clear description, screenshots for UI changes, reference issues, and note any schema/model changes or migration steps.

## Security & Configuration Tips
- HealthKit/Core Data: do not commit personal data. Keep capabilities/entitlements minimal.
- Secrets: no API keys are expected; avoid adding them. Verify schemes and targets before committing.

- 日本語で簡潔かつ丁寧に回答してください