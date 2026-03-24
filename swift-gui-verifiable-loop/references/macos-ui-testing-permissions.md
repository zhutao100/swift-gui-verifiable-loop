# macOS UI testing permissions (Accessibility / Automation)

macOS UI tests (targeting macOS 15 and macOS 26) often require OS-level permissions so the test runner can drive the app like a user.

## What you will see on a fresh machine

When you first run a macOS UI test suite, macOS may show permission prompts (for example, asking to allow control/automation or to allow accessibility access for the test runner tooling).

Apple’s UI automation guidance explicitly calls out enabling the helper used by Xcode UI testing in **Privacy & Security → Accessibility**.

## Practical policy for agentic development loops

### Local development machine

- Run a small “hello world” UI test once.
- When prompted, grant the requested permissions.
- Re-run the same test to confirm the prompt is cleared.

### CI environments

Headless CI runners generally cannot click these permission prompts.

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
