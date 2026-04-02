# macOS UI testing permissions (Accessibility / Automation / Developer Tools)

macOS UI tests (targeting macOS 15 and macOS 26) often require OS-level permissions so the test runner can drive the app like a user.

In newer macOS releases, UI test runners can also fail to launch due to Gatekeeper/syspolicyd decisions. Treat the `.xcresult` bundle as the source of truth for what happened.

## Common prompts / toggles on a fresh machine

If you run `xcodebuild test` / UI tests for the first time, macOS may show permission prompts.

Common settings involved:

- **System Settings → Privacy & Security → Accessibility** (UI automation helper / Xcode / your test launcher)
- **System Settings → Privacy & Security → Automation** (Terminal/Xcode controlling other apps)
- **System Settings → Privacy & Security → Developer Tools** (enable the terminal app you use to run `xcodebuild`, e.g. Terminal)

## Gatekeeper / syspolicyd symptoms (macOS 15+)

You may see UI test failures like:

- “Early unexpected exit… Test crashed with signal kill before establishing connection.”
- dialogs like “app is damaged” (runner blocked before it can attach)

Practical policy:

1. Keep the `.xcresult` bundle.
2. Export attachments/diagnostics (`scripts/ui/xcresult_export.sh`) and inspect them.
3. If you need deeper OS evidence, capture a `syspolicyd` log slice around the run window.

Do not rely on `spctl --assess` as the only oracle in this workflow; it can be noisy for Xcode-built products and UI test runners.

## Mitigations (prefer the least invasive)

- Prefer `build-for-testing` + `test-without-building` runs (see `references/xcresult-bundles.md`).
- If you hit runner launch issues, try placing DerivedData under `/tmp` for the UI loop (example: `--reuse-build --derived-data /tmp/ui-loop/DerivedData`).
- If the runner is still blocked and you are okay with a signing override, try `scripts/ui/ui_loop.sh --adhoc-signing` (adds `CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`).
- Avoid disabling signing entirely (for example `CODE_SIGNING_ALLOWED=NO`); it can break UI runner integrity.

## CI environments

Headless CI runners generally cannot click permission prompts.

Practical options:

1. **Prefer snapshots + unit tests in CI**, and run macOS UI tests only on developer machines.
2. **Use self-hosted macOS runners** where you can preconfigure permissions interactively.
3. **Use a CI provider that supports preconfigured macOS UI testing** (some hosted offerings document workarounds/constraints).

Do not rely on brittle, security-bypassing techniques.

## Evidence capture still applies

Even when UI tests are constrained, keep the core contract:

- always keep the `.xcresult` bundle
- export attachments and diagnostics
- record the toolchain fingerprint

That preserves a machine-verifiable loop for agents.

## References

- Apple: “Recording UI automation for testing” (mentions enabling Xcode’s helper under Accessibility privacy settings)
- CI note: CircleCI’s “Testing macOS applications” (describes permission prompts and headless CI limitations)
