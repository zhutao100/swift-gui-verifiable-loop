---
name: swift-gui-verifiable-loop
description: Create and run a deterministic, agent-friendly closed loop for SwiftUI/AppKit GUI changes using xcodebuild + .xcresult evidence + xcresulttool extraction, plus snapshot testing, accessibility audits, and small XCUITest smoke flows.
license: MIT
compatibility: macOS 15+ with Xcode CLI tools (xcodebuild, xcrun/xcresulttool, simctl). Network recommended for fetching Swift packages and documentation.
metadata:
  author: generated-by-chatgpt
  version: "1.0"
  tags: swift swiftui appkit xcodebuild xcresult xcresulttool snapshot-testing xctest xcuittest accessibility audit agentic
---

# Swift GUI verifiable closed-loop (agent skill)

## When to use

Use this skill when an agent (Codex CLI, Claude Code, Xcode agent) is implementing or refactoring **SwiftUI/AppKit/UIKit UI code** and you need a **machine-verifiable** iteration loop:

1) change code
2) run deterministic checks
3) capture immutable evidence
4) decide next step strictly from evidence

This skill prioritizes **deterministic CLI artifacts** over “eyeballing” GUI outcomes.

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
  - iOS Simulator: `platform=iOS Simulator,name=iPhone 16`
  - macOS: typically `platform=macOS`
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

Use the orchestrator script (recommended):

```bash
scripts/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16' \
  --artifacts-dir ./artifacts
```

Outputs per run:

- `artifacts/<run-id>/results.xcresult` (immutable evidence)
- `artifacts/<run-id>/toolchain.txt` (environment fingerprint)
- `artifacts/<run-id>/summary.json` (machine-readable test summary)
- `artifacts/<run-id>/attachments/**` (exported screenshots/attachments)
- `artifacts/<run-id>/diagnostics/**` (crash logs, diagnostics)

If you prefer manual commands, see `references/xcresult-bundles.md`.

## Step 2 — Add snapshot tests for stable UI surfaces

Recommended: Point-Free `SnapshotTesting` (see `references/snapshot-testing.md`).

Policy:

- Only snapshot **isolated view states** (empty/loading/error/selected/disabled).
- Prefer **text/hierarchy** snapshots for stability; use image snapshots selectively.
- Snapshot updates must be explicit (“record mode”), never automatic in CI.

Template: `assets/templates/SnapshotTestTemplate.swift`

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

Template: `assets/templates/XCUITestLaunchHarnessTemplate.swift`

## Step 5 — Always enrich failures with artifacts

In UI tests, attach:

- screenshots on failure
- any relevant exported files
- optional debug JSON state dumps (debug builds only)

`.xcresult` already stores these; export them after each run.

Template: `assets/templates/XCUITestLaunchHarnessTemplate.swift`
Extraction scripts: `scripts/xcresult_export.sh`, `scripts/xcresult_summary.sh`

---

# Decision rules for the agent (strict)

After each code change:

1. Run **Step 1** (`scripts/ui_loop.sh`).
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

- Orchestrator: `scripts/ui_loop.sh`
- Evidence extraction: `scripts/xcresult_summary.sh`, `scripts/xcresult_export.sh`
- Toolchain fingerprint: `scripts/toolchain_fingerprint.sh`
- Simulator helpers: `scripts/simctl_prepare.sh`
- Templates: `assets/templates/*.swift`
- Deeper reference: `references/REFERENCE.md`
