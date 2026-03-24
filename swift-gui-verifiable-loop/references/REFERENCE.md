# Reference guide: Swift GUI verifiable loop

This file is intentionally more detailed than `SKILL.md`. Keep `SKILL.md` short and point here for depth.

## Validated findings

1. A “pure GUI” closed loop is unreliable; the practical answer is a hybrid loop with most correctness pushed into deterministic layers.
2. `.xcresult` is the evidence store; keep it immutable and derive summaries/attachments from it.
3. Snapshot testing is a primary verifiability primitive for view correctness, but must be scoped and environment-controlled.
4. XCUITest should be small + semantic, and strengthened with accessibility identifiers, accessibility audits, and attachments.
5. Deterministic entry harnesses (launch args/env/URLs) are key to removing flakiness and shortening UI paths.

## Platform-specific notes (macOS vs iOS)

Read first: `references/platform-compatibility.md`.

Key points:

- **Host:** always macOS (scripts rely on Xcode CLI tools).
- **macOS targets:** tests run on the current Mac with `platform=macOS`.
- **iOS targets:** tests run in iOS Simulator (recommended) with `platform=iOS Simulator,id=<UDID>`.

## Recommended layering (gates)

- Gate A (fast): unit tests / state-machine tests (Swift Testing or XCTest)
- Gate B (visual regression): snapshots of isolated view states (Point-Free SnapshotTesting)
- Gate C (UI smoke): small XCUITests + `performAccessibilityAudit()`
- Evidence: `.xcresult` + exported attachments/diagnostics + toolchain fingerprint

## Architecture patterns that maximize determinism

### MVVM / `@Observable`

- Put effectful work behind protocols/clients.
- Avoid unstructured `Task {}` in view code; inject schedulers/clock for determinism.

### Reducer architecture (e.g., TCA)

- State transitions are explicit and testable.
- Test output is “text + state diffs”, which is ideal for agents.

See `references/tca-teststore.md`.

## Deterministic entry harnesses (must-have)

Implement one or more of:

- Launch arguments: `--ui-testing`, `--seed-fixtures`, `--start-screen Settings`
- Launch environment: `FIXTURE_SET=smoke`, `NETWORK_MODE=stubbed`
- Deep links: `myapp://open/settings?tab=general`

In UI tests, always set these before `app.launch()`.

Templates:

- `assets/templates/XCUITestLaunchHarnessTemplate.swift`
- `references/ui-entry-harnesses.md`

## Accessibility contract (automation contract)

Rules of thumb:

- Give every interactive control a stable identifier:
  - SwiftUI: `.accessibilityIdentifier("settings.save")`
  - AppKit: `view.setAccessibilityIdentifier("settings.save")`
- Avoid using visible localized strings as selectors.
- Use one root anchor identifier per major screen.

## Flakiness triage checklist

If a UI smoke test flakes:

- Verify identifiers (not copy-based queries).
- Reduce scope (shorter test).
- Prefer deterministic entry harnesses over navigation.
- Disable animations in test mode (or gate animation-heavy flows).
- Export `.xcresult` attachments and inspect screenshots/logs.

## `.xcresult` stability guidance

- Always record toolchain fingerprint (Xcode churn affects parsing).
- Prefer modern `xcresulttool get test-results …` subcommands when available.
- Prefer deterministic test execution settings for UI/snapshot runs:
  - `-parallel-testing-enabled NO` (disable parallel test runners)
  - stable `-destination` (UDID preferred) and stable simulator/runtime
- Avoid relying on `xcresulttool merge` without validating your pinned Xcode version (tool behavior has changed across releases).

See `references/xcresult-bundles.md`.

## Optional (advanced): internal state snapshots

For features that are hard to validate visually, a high-ROI pattern is a debug-only “state export” hook:

- app launched in test mode (launch args/env/URL)
- app writes a JSON state snapshot to a known location (or serves it on localhost)
- UI test attaches that JSON via `XCTAttachment`

This converts “GUI correctness” into an agent-readable, deterministic artifact.

## Further reading within this repo

- `references/platform-compatibility.md`
- `references/destinations.md`
- `references/swift-testing.md`
- `references/snapshot-testing.md`
- `references/accessibility-audit.md`
- `references/ci-github-actions.md`
