# AGENTS.md — Swift GUI verifiable loop

This repository is a **skill** for agentic tools to maintain a **machine-verifiable closed loop** while changing SwiftUI GUI code on macOS (AppKit) and iOS (UIKit).

## What “done” means for a change

For any GUI-related change, the agent should be able to produce **immutable evidence**:

- a fresh `.xcresult` bundle
- a machine-readable summary derived from the bundle
- exported attachments/diagnostics/logs when present

Do not rely on manual screenshots, Preview eyeballing, or subjective descriptions as proof.

## Inputs you must pin (per target project)

Before iterating, collect these constants from the target project and write them into the project’s own docs (recommended: the project’s root `AGENTS.md`):

- Workspace or project path (`.xcworkspace` or `.xcodeproj`)
- Scheme name
- Test plan name (recommended)
- Destination string:
  - macOS: `platform=macOS` (optionally include `arch=arm64` / `arch=x86_64`)
  - iOS Simulator: `platform=iOS Simulator,name=<device>,OS=<version>` (prefer a simulator UDID when you need strict repeatability)
- Optional package root override when `scripts/ui/ui_loop.sh` should search somewhere other than the repo root

Agents must not guess these values.

## Refreshing an existing target setup

When a target project already has older copied loop scripts, update the skill-owned scripts before using current options such as `--system-attachment-lifetime` or `--sanitize-screenshots`:

```bash
swift-gui-verifiable-loop/scripts/project/update_ui_loop_tools.sh \
  --apply \
  --platform macos \
  /path/to/target-repo
```

Use `--platform ios` for iOS-only apps and `--platform both` for shared macOS/iOS repos. The updater copies only skill-owned script files; keep project-specific docs, schemes, launch harnesses, and local helper scripts under normal review.

## Default iteration loop

1. **Make one coherent change** (keep diffs small).
2. Run a deterministic verification pass.

   macOS example:

   ```bash
   scripts/ui/ui_loop.sh \
     --scheme App \
     --test-plan Smoke
   ```

   Agent-safe macOS UI example:

   ```bash
   scripts/ui/ui_loop.sh \
     --workspace App.xcworkspace \
     --scheme App \
     --test-plan Smoke \
     --destination 'platform=macOS' \
     --reuse-build \
     --system-attachment-lifetime keepNever \
     --sanitize-screenshots redact-suspect \
     --delete-raw-attachments
   ```

   iOS Simulator example:

   ```bash
   scripts/ui/ui_loop.sh \
     --scheme App \
     --test-plan Smoke \
     --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
   ```

   (For iOS 26 environments, use `OS=26.0` in the destination.)

3. Inspect `<artifacts-dir>/<run-id>/summary.json` (default artifacts dir: `./.artifacts/ui`).
4. If failed, inspect exported artifacts:
   - `<artifacts-dir>/<run-id>/attachments/**` (sanitized when screenshot sanitization was enabled)
   - `<artifacts-dir>/<run-id>/attachment_sanitization.json`
   - `<artifacts-dir>/<run-id>/diagnostics/**`
   - `<artifacts-dir>/<run-id>/logs/**`
   - `<artifacts-dir>/<run-id>/xcodebuild-*.log`
   - `<artifacts-dir>/<run-id>/toolchain.txt`
5. Make the next fix based strictly on evidence.

Tip: add `/.artifacts/` to your project’s `.gitignore`.
Tip: set `VERBOSE=1` when you want live `xcodebuild` output instead of per-run log files.

## Fast inner loop (target one test)

When you know the affected test(s), run just that subset:

```bash
scripts/ui/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=macOS' \
  --only-testing MyAppTests/SettingsViewTests/testSettingsView_lightMode
```

## Snapshot workflow rules

Snapshot tests are a primary GUI verifier, but recording must be intentional.

- Normal mode: **compare only**
- Recording mode (explicit): set `SNAPSHOT_RECORD=1`

Example:

```bash
SNAPSHOT_RECORD=1 \
scripts/ui/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=macOS'
```

iOS Simulator example:

```bash
SNAPSHOT_RECORD=1 \
scripts/ui/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

Rules:

- Never record in CI (use `record: .never` there; see `references/snapshot-testing.md`).
- If a snapshot diff fails, decide: intentional UI change (re-record) vs regression (fix UI).
- Keep snapshot surfaces narrow (isolated states), and pin environment (device config, locale, appearance).



## Agent-safe artifact policy

- Prefer `--reuse-build --system-attachment-lifetime keepNever` for macOS UI smoke tests. This suppresses automatic XCTest UI screenshots before the `.xcresult` is produced.
- Prefer `--sanitize-screenshots redact-suspect --delete-raw-attachments` when exporting attachments for model inspection.
- Agents inspect `attachments/`, never `attachments_raw/`, unless a human explicitly approves raw artifact review.
- UI tests should attach window/root-element screenshots for agent-facing macOS runs. Use `XCUIApplication.screenshot()` only after confirming it is app-scoped on that runner, and do not use `XCUIScreen.main.screenshot()`.
- If macOS prompts for UI automation permission, stop after one mitigation pass and collect TCC attribution evidence with `scripts/macos/tcc_attribution_tail.sh`; do not loop indefinitely.

## XCUITest workflow rules

UI tests are valuable but inherently fragile. Keep them:

- **small** (one contract per test)
- **launch-controlled** (launch args/env/deep links)
- **accessibility-first** (stable identifiers, no localized-string selectors)
- **artifact-rich** (screenshots, JSON dumps, logs as attachments)

For macOS menu bar extras:

- Prefer a launch harness that opens the popover/context menu in `--uitest` mode.
- Treat direct `NSStatusItem` clicking as optional evidence; it may not be hittable even when the item exists in the accessibility tree.

See templates in `assets/templates/`.

iOS simulator helpers:

- `scripts/ios/simctl_prepare.sh`
- `scripts/ios/simctl_privacy.sh`

## Determinism defaults

This skill disables parallel test runners by default:

- `-parallel-testing-enabled NO`

You may enable parallelization only when you have evidence it is stable for the affected suite:

```bash
scripts/ui/ui_loop.sh ... --parallel-testing-enabled YES --maximum-parallel-testing-workers 2
```

## Failure triage playbook

When a run fails:

1. Open `<artifacts-dir>/<run-id>/summary.json` to identify the failing target/test.
2. If it is a UI test failure:
   - inspect attachments (screenshots/videos when present)
   - check accessibility identifiers
   - shorten the test by adding deterministic entry harnesses
3. If it is a snapshot failure:
   - confirm the runtime is pinned and stable (Xcode version, font rendering, color space)
   - confirm fonts/dynamic type/locale are controlled
   - re-record only if the change is intended
4. If it is a build failure:
   - use `toolchain.txt` + `logs/*` to correlate with environment issues

## What to read

- `SKILL.md` — the contract and step-by-step workflow
- `references/REFERENCE.md` — design principles and troubleshooting
- `references/snapshot-testing.md` — SnapshotTesting setup + recording policy
- `references/xcresult-bundles.md` — `.xcresult` mechanics and extraction commands
- `references/artifact-privacy.md` — screenshot retention, redaction, cropping, and agent-safe artifact policy
- `references/macos-ui-testing-permissions.md` — TCC prompt triage and PPPC notes
- `scripts/project/update_ui_loop_tools.sh` — refresh older target projects with the current managed scripts
