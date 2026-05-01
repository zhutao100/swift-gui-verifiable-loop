# macOS UI testing permissions (Accessibility / Automation / Developer Tools)

macOS UI tests depend on Accessibility semantics and synthesized input events. On a fresh or headless machine, the first UI-test run may trigger a password or privacy prompt before the app under test launches. Agents must treat this as an operating-system gate, not as a flaky test to brute-force with repeated retries.

## Common prompts / toggles on a fresh machine

Common settings involved:

- **System Settings → Privacy & Security → Accessibility**: UI automation helper / Xcode / stable wrapper app / agent terminal.
- **System Settings → Privacy & Security → Automation**: one process controlling another by Apple Events.
- **System Settings → Privacy & Security → Developer Tools**: the terminal or IDE used to run developer tools.
- **PostEvent / Input monitoring-style controls**: event synthesis may be attributed to a different binary than the app under test.

Do not guess which binary needs approval. Capture attribution evidence.

## "XCTest is trying to Enable UI Automation" password prompt

Symptoms in `.xcresult` / `xcodebuild`:

- `The test runner failed to initialize for UI testing`
- `Timed out while enabling automation mode`
- no app screenshots or test attachments because the app never launched

Agent policy:

1. Keep the failed `.xcresult` and exported diagnostics.
2. Capture the responsible TCC attribution chain while reproducing the prompt:

   ```bash
   scripts/macos/tcc_attribution_tail.sh \
     --duration 45 \
     --out .artifacts/tcc-attribution.log
   ```

3. Print identities for candidate executables/apps before authoring PPPC:

   ```bash
   scripts/macos/collect_tcc_identities.sh \
     /Applications/Xcode.app \
     /Applications/Utilities/Terminal.app
   ```

4. Try the least-invasive local mitigations once:
   - `--adhoc-signing`
   - `--reuse-build --derived-data /tmp/<name>/DerivedData`
5. If the same prompt/timeout repeats, stop retrying the UI-test loop and report that a human or device-management policy must approve the permission.

## PPPC / MDM option for managed machines

For managed macOS machines, a Privacy Preferences Policy Control (PPPC) payload can preconfigure privacy classes for specific apps/binaries. Use MDM or your organization’s PPPC tooling; this skill includes only a template:

```bash
cp assets/templates/PPPC-UI-Testing.mobileconfig.template /tmp/PPPC-UI-Testing.mobileconfig
```

Then replace placeholders with values collected from:

```bash
scripts/macos/tcc_attribution_tail.sh --duration 45 --out .artifacts/tcc.log
scripts/macos/collect_tcc_identities.sh /path/to/responsible.app-or-binary
```

Important caveats:

- PPPC is an administrative deployment mechanism. It is not an agent-side bypass for a regular unmanaged developer Mac.
- The responsible path may be Xcode, an Xcode helper, the test runner app, Terminal, a CI agent, or a wrapper binary. Confirm by TCC logs.
- Apple platform behavior can change between macOS releases. Revalidate on every macOS/Xcode major upgrade.

## Disposable VM option for unattended agents

For unmanaged developer Macs, a prepared disposable macOS VM is the practical
agent-safe path when no human can approve prompts during the run. If the
`ghostvm-safe-testing` skill is installed, prepare a VM snapshot for Xcode UI
testing and run this skill's `scripts/ui/ui_loop.sh` inside that guest.

Expected preparation contract:

- a clean base snapshot is reverted before each run
- the guest has Xcode installed and first-launch setup completed
- Xcode UI testing bootstrap has enabled Automation Mode without per-run
  authentication
- TCC rows are seeded for GhostTools plus Xcode/XCTest candidates such as Xcode,
  Xcode Helper, `xcodebuild`, and `xcrun`
- host project inputs are mounted read-only and evidence/artifacts are exported
  through a dedicated writable share

This does not change the policy for a real host: do not loop on an interactive
password prompt there. Move the test to a prepared VM, use PPPC/MDM, or ask the
permission owner to approve the gate.

## Gatekeeper / syspolicyd symptoms (macOS 15+)

You may see UI test failures like:

- “Early unexpected exit… Test crashed with signal kill before establishing connection.”
- dialogs like “app is damaged” (runner blocked before it can attach)

Practical policy:

1. Keep the `.xcresult` bundle.
2. Export attachments/diagnostics (`scripts/ui/xcresult_export.sh`) and inspect them.
3. If you need deeper OS evidence, capture a `syspolicyd` log slice around the run window.

Do not rely on `spctl --assess` as the only oracle in this workflow; it can be noisy for Xcode-built products and UI test runners.

## CI environments

Headless CI runners generally cannot click permission prompts.

Practical options:

1. Prefer snapshots + unit tests in CI, and run macOS UI tests only on prepared developer or self-hosted machines.
2. Use MDM-managed self-hosted macOS runners with PPPC where organizationally appropriate.
3. Use a dedicated clean login session, clean desktop, or disposable VM so any accidental full-screen screenshot contains no user data.
4. Treat macOS UI smoke tests as an outer-loop gate, not the only proof of correctness.

## Evidence capture still applies

Even when UI tests are permission-constrained, keep the core contract:

- always keep the `.xcresult` bundle locally
- export diagnostics/logs
- record the toolchain fingerprint
- inspect only sanitized attachments when agents are involved

Related: `references/artifact-privacy.md`.
