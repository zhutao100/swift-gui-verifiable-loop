# Reference guide: Swift GUI verifiable loop

This file is intentionally more detailed than `SKILL.md`. Keep `SKILL.md` short and point here for depth.

## Validated Findings

1. **A “pure GUI” closed loop is unreliable**; the practical answer is a hybrid loop with most correctness pushed into deterministic layers.
2. **`.xcresult` is the evidence store**; you should keep it immutable and derive summaries/attachments from it.
3. **Snapshot testing is a primary verifiability primitive** for view correctness, but must be scoped and environment-controlled.
4. **XCUITest should be small + semantic**, and strengthened with accessibility identifiers, accessibility audits, and attachments.
5. **Deterministic entry harnesses** (launch args/env/URLs) are key to removing flakiness and shortening UI paths.

## Platform scope (avoid ambiguity)

This skill supports **both** macOS and iOS GUI verification loops.

- **macOS:** targets macOS 15 and macOS 26 (year-based numbering).
- **iOS:** targets iOS 18 and iOS 26 (year-based numbering).

Most mechanics are shared (`xcodebuild`, `.xcresult`, snapshots), but some details differ:

- macOS UI interaction often uses mouse/keyboard actions (for example, `click()`), and may require Accessibility permissions for UI automation.
- iOS UI interaction uses touch gestures (for example, `tap()`), and simulator determinism often benefits from `simctl` helpers.

## Recommended layering (gates)

- Gate A (fast): `swift test` / unit tests / state-machine tests (Swift Testing or XCTest)
- Gate B (visual regression): snapshots of isolated view states
- Gate C (UI smoke): small XCUITests + `performAccessibilityAudit()`
- Evidence: `.xcresult` + exported attachments/diagnostics + toolchain fingerprint

## Architecture patterns that maximize determinism

### MVVM / @Observable
- Put effectful work behind protocols/clients.
- Avoid unstructured `Task {}` in view code; inject schedulers/clock for determinism.

### Reducer architecture (e.g., TCA)
- State transitions are explicit and testable.
- Test output is “text + state diffs”, which is ideal for agents.

See `references/tca-teststore.md`.

## Deterministic entry harnesses (must-have)

Implement one or more of:

- Launch arguments: `--uitest` / `--seed-fixtures` / `--start-screen Settings`
- Launch environment: `FIXTURE_SET=smoke`, `NETWORK_MODE=stubbed`
- Deep links: `myapp://open/settings?tab=general`

In UI tests, always set these before `app.launch()`.

Template: `assets/templates/XCUITestLaunchHarnessTemplate.swift`

## Accessibility contract

Rules of thumb:

- Give every interactive control a stable identifier:
  - SwiftUI: `.accessibilityIdentifier("settings.save")`
  - AppKit: `view.setAccessibilityIdentifier("settings.save")` (or set identifier on NSView subclasses)
- Avoid using visible localized strings as selectors.
- Use one root anchor identifier per major screen.

## Flakiness triage checklist

If a UI smoke test flakes:

- Verify identifiers (not copy-based queries).
- Reduce scope (shorter test).
- Prefer deterministic entry harnesses over navigation.
- Disable animations in test mode.
- Export `.xcresult` attachments and inspect screenshots/logs.

## `.xcresult` stability guidance

- Always record toolchain fingerprint (Xcode version churn affects parsing).
- Prefer modern `xcresulttool get test-results ...` subcommands.
- Prefer deterministic test execution settings for UI/snapshot runs:
  - `-parallel-testing-enabled NO` (disable parallel test runners)
  - stable `-destination` (for macOS, `platform=macOS` is typically sufficient; optionally include `arch=arm64` / `arch=x86_64`)
- Avoid relying on `xcresulttool merge` without validating your pinned Xcode version.

## Optional (advanced): internal state snapshots

For features that are hard to validate visually, a high-ROI pattern is a debug-only “state export” hook:

- app launched in test mode (launch args/env/URL)
- app writes a JSON state snapshot to a known location (or serves it on localhost)
- UI test attaches that JSON via `XCTAttachment`

This converts “GUI correctness” into an agent-readable, deterministic artifact.

See `references/xcresult-bundles.md`.
