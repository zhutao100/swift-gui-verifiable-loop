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
  version: "1.2"
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

- Workspace or project: `App.xcworkspace` or `App.xcodeproj` (optional when `scripts/ui/ui_loop.sh` can auto-discover one at the package root)
- Scheme: `App`
- Test plan (recommended): `Smoke` (a `.xctestplan` attached to the scheme)
- Destination:
  - macOS: `platform=macOS` (optionally include `arch=arm64` or `arch=x86_64`)
  - iOS Simulator: `platform=iOS Simulator,name=<device>,OS=<version>` (prefer a simulator **UDID** when you need strict repeatability)
- Package root (optional): pass `--package-root <dir>` when the script should search somewhere other than the repo root for a package/Xcode container
- Optional: derived data directory for repeatable runs

Keep these as constants in your project docs (e.g., `AGENTS.md`) so agents never guess.

If the target project already has an older copied `scripts/ui/ui_loop.sh`, refresh the managed scripts before using newer options:

```bash
/path/to/swift-gui-verifiable-loop/scripts/project/update_ui_loop_tools.sh \
  --apply \
  --platform macos \
  /path/to/target-repo
```

Use `--platform ios` for iOS-only apps and `--platform both` for shared macOS/iOS repos. This updater is intentionally limited to the skill-owned scripts; update project docs and test launch harnesses separately.

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
  --scheme App \
  --test-plan Smoke
```

**Agent-safe macOS UI example (preferred when full-screen XCTest screenshots are a concern):**

```bash
scripts/ui/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=macOS' \
  --reuse-build \
  --system-attachment-lifetime keepNever \
  --sanitize-screenshots keep \
  --delete-raw-attachments
```

**iOS Simulator example:**

```bash
scripts/ui/ui_loop.sh \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

(For iOS 26 environments, use `OS=26.0` in the destination.)

Outputs per run:

- `<artifacts-dir>/<run-id>/results.xcresult` (immutable evidence)
- `<artifacts-dir>/<run-id>/toolchain.txt` (environment fingerprint)
- `<artifacts-dir>/<run-id>/summary.json` (machine-readable test summary)
- `<artifacts-dir>/<run-id>/xcodebuild-*.log` (captured `xcodebuild` logs unless `VERBOSE=1`)
- `<artifacts-dir>/<run-id>/attachments/**` (exported screenshots/attachments; sanitized when `--sanitize-screenshots` is used)
- `<artifacts-dir>/<run-id>/attachments_raw/**` (raw export only when screenshot sanitization is enabled and raw deletion is not requested)
- `<artifacts-dir>/<run-id>/attachment_sanitization.json` (sanitizer report when a transforming policy is used)
- `<artifacts-dir>/<run-id>/xctestrun-attachment-policy.json` (`.xctestrun` patch report when attachment lifetime policy is patched)
- `<artifacts-dir>/<run-id>/diagnostics/**` (crash logs, diagnostics)

Default artifacts dir: `./.artifacts/ui` (add `/.artifacts/` to your project’s `.gitignore`).

If you prefer manual commands, see `references/xcresult-bundles.md`.

## Platform notes (read once)

- macOS UI tests may require Accessibility/Automation permissions for the UI test runner. See `references/macos-ui-testing-permissions.md`.
- For unattended agent runs, prefer a prepared disposable macOS VM when available
  (for example a GhostVM `xcode-ui-ready` snapshot) over repeatedly running on a
  real host that still needs interactive approval.
- If macOS shows an "XCTest is trying to Enable UI Automation" password prompt, preserve the `.xcresult`, capture TCC attribution with `scripts/macos/tcc_attribution_tail.sh`, try the documented mitigations once, then ask the human or MDM policy owner to grant the OS permission instead of repeatedly rerunning.
- For agent-facing macOS visual evidence, prefer `--reuse-build --system-attachment-lifetime keepNever --sanitize-screenshots keep --delete-raw-attachments` after UI tests attach only app-window/root-element screenshots or cropped status-surface screenshots. Use `redact-suspect` only when privacy is more important than readable PNG evidence. See `references/artifact-privacy.md`.
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

On macOS, be prepared to ignore narrowly-scoped host/framework noise with an explicit closure when the audit traverses synthetic SwiftUI container nodes or system-owned controls (for example, Touch Bar items) that are outside your app's actionable surface.

Template: `assets/templates/AccessibilityAuditUITestTemplate.swift`
Reference: `references/accessibility-audit.md`

## Step 4 — Keep XCUITests minimal (smoke only)

UI tests are valuable, but operationally fragile. Use them as *proof-of-life* flows:

- launch → first interactive screen → one key action
- document/window creation
- settings toggle persists after relaunch
- menu bar extra popover/context menu via a deterministic launch harness when direct `NSStatusItem` clicks are not hittable under XCUITest

Templates:

- macOS: `assets/templates/XCUITestLaunchHarnessTemplate.swift` (uses `click()` and shows menu patterns)
- macOS menu bar extras: `assets/templates/MacOSMenuBarExtraUITestTemplate.swift`
- iOS: `assets/templates/iOSXCUITestLaunchHarnessTemplate.swift` (uses `tap()` and includes a basic interruption monitor)

## Step 5 — Always enrich failures with artifacts

In UI tests, attach:

- window/root-element screenshots on failure; use `XCUIApplication.screenshot()` only after confirming it is app-scoped on that platform/runner, and avoid `XCUIScreen.main.screenshot()` for macOS agent runs
- any relevant exported files
- optional debug JSON state dumps or accessibility-tree text dumps (debug builds only)

`.xcresult` already stores these; export them after each run.

Templates: `assets/templates/XCUITestLaunchHarnessTemplate.swift`, `assets/templates/AgentSafeUITestArtifactsTemplate.swift`
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
- **Sensitive/full-screen screenshots** → patch automatic attachment lifetimes, attach app-scoped screenshots, and sanitize exports.
- **Tooling churn** → record toolchain fingerprint each run; prefer structured `xcresulttool` subcommands.

See `references/REFERENCE.md` for deeper troubleshooting and patterns.

---

# Quick file map

- Orchestrator (canonical): `scripts/ui/ui_loop.sh`
- Evidence extraction (canonical): `scripts/ui/xcresult_summary.sh`, `scripts/ui/xcresult_export.sh`
- Attachment privacy helpers: `scripts/ui/patch_xctestrun_attachment_policy.py`, `scripts/ui/patch_xcscheme_attachment_policy.py`, `scripts/ui/xcresult_sanitize_attachments.py`
- macOS permission triage: `scripts/macos/tcc_attribution_tail.sh`, `scripts/macos/collect_tcc_identities.sh`
- Existing-project updater: `scripts/project/update_ui_loop_tools.sh`
- Toolchain fingerprint (canonical): `scripts/ui/toolchain_fingerprint.sh`
- Templates: `assets/templates/*.swift`
- Deeper reference: `references/REFERENCE.md`

iOS simulator helpers:

- `scripts/ios/simctl_prepare.sh`
- `scripts/ios/simctl_privacy.sh`
