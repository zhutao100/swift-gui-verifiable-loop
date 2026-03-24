# AGENTS.md — Swift GUI verifiable loop

This repository is a **skill** for agentic tools to maintain a **machine-verifiable closed loop** while changing SwiftUI/AppKit/UIKit GUI code.

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
- Destination string (prefer simulator **UDID** when possible)

Agents must not guess these values.

## Default iteration loop

1. **Make one coherent change** (keep diffs small).
2. Run a deterministic verification pass:

   ```bash
   scripts/ui_loop.sh \
     --workspace App.xcworkspace \
     --scheme App \
     --test-plan Smoke \
     --destination 'platform=iOS Simulator,name=iPhone 16' \
     --artifacts-dir ./artifacts
   ```

3. Inspect `artifacts/<run-id>/summary.json`.
4. If failed, inspect exported artifacts:
   - `artifacts/<run-id>/attachments/**`
   - `artifacts/<run-id>/diagnostics/**`
   - `artifacts/<run-id>/logs/**`
   - `artifacts/<run-id>/toolchain.txt`
5. Make the next fix based strictly on evidence.

## Fast inner loop (target one test)

When you know the affected test(s), run just that subset:

```bash
scripts/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16' \
  --only-testing MyAppTests/SettingsViewTests/testSettingsView_lightMode
```

## Snapshot workflow rules

Snapshot tests are a primary GUI verifier, but recording must be intentional.

- Normal mode: **compare only**
- Recording mode (explicit): set `SNAPSHOT_RECORD=1`

Example:

```bash
SNAPSHOT_RECORD=1 \
scripts/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16'
```

Rules:

- Never record in CI (use `record: .never` there; see `references/snapshot-testing.md`).
- If a snapshot diff fails, decide: intentional UI change (re-record) vs regression (fix UI).
- Keep snapshot surfaces narrow (isolated states), and pin environment (device config, locale, appearance).

## XCUITest workflow rules

UI tests are valuable but inherently fragile. Keep them:

- **small** (one contract per test)
- **launch-controlled** (launch args/env/deep links)
- **accessibility-first** (stable identifiers, no localized-string selectors)
- **artifact-rich** (screenshots, JSON dumps, logs as attachments)

See templates in `assets/templates/`.

## Determinism defaults

This skill disables parallel test runners by default:

- `-parallel-testing-enabled NO`

You may enable parallelization only when you have evidence it is stable for the affected suite:

```bash
scripts/ui_loop.sh ... --parallel-testing-enabled YES --maximum-parallel-testing-workers 2
```

## Failure triage playbook

When a run fails:

1. Open `summary.json` to identify the failing target/test.
2. If it is a UI test failure:
   - inspect attachments (screenshots/videos when present)
   - check accessibility identifiers
   - shorten the test by adding deterministic entry harnesses
3. If it is a snapshot failure:
   - confirm the simulator/runtime is pinned and stable
   - confirm fonts/dynamic type/locale are controlled
   - re-record only if the change is intended
4. If it is a build failure:
   - use `toolchain.txt` + `logs/*` to correlate with environment issues

## What to read

- `SKILL.md` — the contract and step-by-step workflow
- `references/REFERENCE.md` — design principles and troubleshooting
- `references/snapshot-testing.md` — SnapshotTesting setup + recording policy
- `references/xcresult-bundles.md` — `.xcresult` mechanics and extraction commands
