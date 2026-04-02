---
name: swift-gui-verifiable-loop
description: Create and run a deterministic, agent-friendly closed loop for SwiftUI GUI changes on macOS (AppKit) and iOS (UIKit) using xcodebuild + .xcresult evidence + xcresulttool extraction, plus snapshot testing, accessibility audits, and small XCUITest smoke flows.
license: MIT
compatibility: |
  Platforms:
  - macOS: 15 and 26 (year-based numbering) — SwiftUI/AppKit apps.
  - iOS: 18 and 26 (year-based numbering) — SwiftUI/UIKit apps (simulator-focused).

  Tooling:
  - Xcode CLI tools: xcodebuild, xcrun/xcresulttool (Xcode 16+ recommended; Xcode 15+ required for accessibility audits).
  - Network recommended for fetching Swift packages and documentation.
metadata:
  author: generated-by-chatgpt
  version: "1.1"
  tags: swift swiftui appkit uikit xcodebuild xcresult xcresulttool snapshot-testing xctest xcuittest accessibility audit agentic macos ios
---

# Swift GUI verifiable closed-loop (agent skill)

## When to use

Use this skill when an agent (Codex CLI, Claude Code, Xcode agent) is implementing or refactoring **SwiftUI GUI code** on:

- **macOS** (SwiftUI/AppKit)
- **iOS** (SwiftUI/UIKit, typically via Simulator)

and you need a **machine-verifiable** iteration loop:

1) change code
2) run deterministic checks
3) capture immutable evidence
4) decide next step strictly from evidence

This skill prioritizes **deterministic CLI artifacts** over “eyeballing” GUI outcomes.

Versioning note:

- Apple moved to year-based OS version numbering for the “26” generation. This skill intentionally calls out both “pre-26” versions (macOS 15, iOS 18) and “26” versions (macOS 26, iOS 26) to avoid ambiguity in mixed environments.

## Core idea (high-level)

A reliable GUI loop is typically **hybrid**:

- **Deterministic core** (fast inner loop): pure logic/state tests (Swift Testing / XCTest), reducer/view-model tests, dependency-injected integration tests.
- **Deterministic UI evidence** (mid loop): snapshot tests (especially text/hierarchy strategies).
- **Small GUI smoke** (outer loop): minimal XCUITest flows + accessibility audits + rich attachments.
- **Immutable evidence store**: always keep the `.xcresult` bundle and derive summaries/attachments from it.

## Inputs you must collect (one-time per project)

- Workspace or project: `App.xcworkspace` or `App.xcodeproj`
- Scheme: `App`
- Test plan (recommended): `Smoke` (a `.xctestplan` attached to the scheme)
- Destination:
  - macOS: `platform=macOS` (optionally include `arch=arm64` or `arch=x86_64`)
  - iOS Simulator: `platform=iOS Simulator,name=<device>,OS=<version>` (prefer a simulator **UDID** when you need strict repeatability)
- Optional: derived data directory for repeatable runs

Keep these as constants in your project docs (e.g., `AGENTS.md`) so agents never guess.

---

# Step-by-step closed-loop workflow

## Step 0 — Make the UI *verifiable by construction*

Do this once, then keep enforcing it.

1. **Push behavior out of views**
   - Views render state; they do not own business logic.
   - Use MVVM (`@Observable` view-models) or a reducer architecture (e.g., TCA).
2. **Add deterministic entry points**
   - Launch args / env vars / custom URL schemes should let tests jump into a state directly.
3. **Treat Accessibility as an automation contract**
   - Every actionable control gets a stable identifier.
4. **Keep GUI smoke tests small and semantic**
   - Prefer “prove one contract” tests over long pseudo-human scripts.

(Details + templates: see `references/REFERENCE.md` and `assets/templates/`.)

## Step 1 — Run a full deterministic verification pass (baseline)

Use the orchestrator script (recommended).

**macOS example:**

```bash
scripts/ui/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=macOS'
```

**iOS Simulator example:**

```bash
scripts/ui/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

(For iOS 26 environments, use `OS=26.0` in the destination.)

Outputs per run:

- `<artifacts-dir>/<run-id>/results.xcresult` (immutable evidence)
- `<artifacts-dir>/<run-id>/toolchain.txt` (environment fingerprint)
- `<artifacts-dir>/<run-id>/summary.json` (machine-readable test summary)
- `<artifacts-dir>/<run-id>/attachments/**` (exported screenshots/attachments)
- `<artifacts-dir>/<run-id>/diagnostics/**` (crash logs, diagnostics)

Default artifacts dir: `./.artifacts/ui` (add `/.artifacts/` to your project’s `.gitignore`).

If you prefer manual commands, see `references/xcresult-bundles.md`.

## Platform notes (read once)

- macOS UI tests may require Accessibility/Automation permissions for the UI test runner. See `references/macos-ui-testing-permissions.md`.
- iOS simulator runs benefit from simulator-state and permission control via `simctl`. See `references/ios-simulator-determinism.md`.

## Step 2 — Add snapshot tests for stable UI surfaces

Recommended: Point-Free `SnapshotTesting` (see `references/snapshot-testing.md`).

- macOS: prefer `.fixed` / `.sizeThatFits` layouts.
- iOS: device presets (`.device(config: ...)`) are fine, but only deterministic when you pin the simulator runtime + device model.

Policy:

- Only snapshot **isolated view states** (empty/loading/error/selected/disabled).
- Prefer **text/hierarchy** snapshots for stability; use image snapshots selectively.
- Snapshot updates must be explicit (“record mode”), never automatic in CI.

Templates:

- macOS: `assets/templates/SnapshotTestTemplate.swift`
- iOS: `assets/templates/iOSSnapshotTestTemplate.swift`

## Step 3 — Add accessibility audits to the smoke suite

Add at least one audit per major screen family:

```swift
try app.performAccessibilityAudit()
```

This produces a high-signal, machine-actionable gate.

Template: `assets/templates/AccessibilityAuditUITestTemplate.swift`
Reference: `references/accessibility-audit.md`

## Step 4 — Keep XCUITests minimal (smoke only)

UI tests are valuable, but operationally fragile. Use them as *proof-of-life* flows:

- launch → first interactive screen → one key action
- document/window creation
- settings toggle persists after relaunch

Templates:

- macOS: `assets/templates/XCUITestLaunchHarnessTemplate.swift` (uses `click()` and shows menu patterns)
- iOS: `assets/templates/iOSXCUITestLaunchHarnessTemplate.swift` (uses `tap()` and includes a basic interruption monitor)

## Step 5 — Always enrich failures with artifacts

In UI tests, attach:

- screenshots on failure
- any relevant exported files
- optional debug JSON state dumps (debug builds only)

`.xcresult` already stores these; export them after each run.

Template: `assets/templates/XCUITestLaunchHarnessTemplate.swift`
Extraction scripts (canonical): `scripts/ui/xcresult_export.sh`, `scripts/ui/xcresult_summary.sh`

---

# Decision rules for the agent (strict)

After each code change:

1. Run **Step 1** (`scripts/ui/ui_loop.sh`).
2. If compilation/tests fail:
   - fix failures first; do not proceed.
3. If snapshot diffs fail:
   - decide whether change is intended.
   - if intended: update snapshots via “record mode” (see `references/snapshot-testing.md`).
   - if unintended: fix UI.
4. If XCUITest smoke fails:
   - inspect exported attachments/diagnostics.
   - reduce flakiness by improving launch harnesses and accessibility identifiers.
5. Only if all deterministic gates pass:
   - optionally use Preview screenshots as a qualitative spot-check (not a proof oracle).

---

# Common pitfalls (and how this skill mitigates them)

- **GUI nondeterminism** → push logic into unit tests + launch harnesses.
- **Flaky UI queries** → stable accessibility identifiers, concise queries, small smoke flows.
- **Hard-to-interpret failures** → `.xcresult` as evidence + exported attachments/diagnostics.
- **Tooling churn** → record toolchain fingerprint each run; prefer structured `xcresulttool` subcommands.

See `references/REFERENCE.md` for deeper troubleshooting and patterns.

---

# Quick file map

- Orchestrator (canonical): `scripts/ui/ui_loop.sh`
- Evidence extraction (canonical): `scripts/ui/xcresult_summary.sh`, `scripts/ui/xcresult_export.sh`
- Toolchain fingerprint (canonical): `scripts/ui/toolchain_fingerprint.sh`
- Templates: `assets/templates/*.swift`
- Deeper reference: `references/REFERENCE.md`

iOS simulator helpers:

- `scripts/ios/simctl_prepare.sh`
- `scripts/ios/simctl_privacy.sh`
