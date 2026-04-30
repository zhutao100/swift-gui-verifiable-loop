# Agent-safe UI-test artifacts and screenshot privacy

XCTest UI runs can place full-screen screenshots or recordings into `.xcresult` bundles. On macOS this is risky for agentic workflows because the app under test may occupy only a small part of the display while the screenshot includes other windows, notifications, menu bar content, and desktop state.

The policy in this skill is:

1. **Prevent broad screenshots at the source** when possible.
2. **Attach app-scoped evidence from test code** when failure context is needed.
3. **Sanitize exported attachments before agents inspect them**.
4. **Keep raw artifacts local and short-lived** unless a human explicitly needs them.

## Recommended default for macOS UI smoke tests

Use `build-for-testing` + `test-without-building`, patch the generated `.xctestrun` to discard automatic XCTest screenshots, and sanitize exported attachments:

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

Artifacts:

- `results.xcresult`: original immutable result bundle; keep local unless policy allows sharing.
- `attachments/`: agent-safe export tree containing explicit app-window/root-element screenshots or cropped status-surface screenshots authored by tests.
- `attachment_sanitization.json`: machine-readable report of copied/redacted/cropped attachments when a transforming policy such as `redact-suspect` or `crop` is used.
- `xctestrun-attachment-policy.json`: report from the `.xctestrun` patch step.

## Strategy comparison

| Strategy | What it solves | Residual risk | Use when |
|---|---:|---:|---|
| Patch `.xctestrun` `SystemAttachmentLifetime=keepNever` | Prevents automatic UI-testing screenshots from being stored in the `.xcresult` | Does not remove explicit `XCTAttachment` screenshots created by tests | Default for agent macOS UI loops using `--reuse-build` |
| Shared `.xcscheme` `systemAttachmentLifetime=keepNever` | Source-controlled team default | Modifies project metadata; may conflict with human debugging preference | Team wants privacy-safe default for all test invocations |
| `XCUIElement` window/root screenshots | Captures a specific app surface instead of the full desktop | Element can still be large; app content itself may be sensitive | Failure attachments authored in UI tests |
| Export sanitizer `keep` | Preserves explicit app-window/root/cropped screenshots for visual evidence | Safe only when automatic system screenshots are suppressed and tests do not attach full-screen images | Default for agent-facing visual evidence |
| Export sanitizer `redact-suspect` | Replaces large/full-screen-looking exported images with placeholders before agents inspect them | Raw `.xcresult` still exists; output PNGs are not useful visual evidence | Privacy triage runs where readable screenshots are not needed |
| Export sanitizer `crop` | Produces model-friendly app-region screenshots | Crop coordinates are environment-specific; bad crop can hide evidence | Stable desktop/window geometry in a dedicated test host |
| Dedicated clean desktop / disposable VM | Reduces blast radius if full-screen capture occurs | Does not solve artifact size/model suitability by itself | Highest-safety local testing, especially for agents |

## Script entry points

### Patch generated `.xctestrun`

```bash
scripts/ui/patch_xctestrun_attachment_policy.py \
  /path/to/App_iphonesimulator.xctestrun \
  --system-attachment-lifetime keepNever
```

This is the least invasive source-prevention method because it mutates only the generated test-run plist under DerivedData. It requires `build-for-testing` + `test-without-building`.

### Patch shared `.xcscheme`

```bash
scripts/ui/patch_xcscheme_attachment_policy.py \
  App.xcodeproj/xcshareddata/xcschemes/App.xcscheme \
  --system-attachment-lifetime keepNever \
  --preferred-screen-capture-format screenshots
```

Use this only if committing the change is intended. Keep the generated `.bak` file out of commits.

### Sanitize exported attachments

```bash
scripts/ui/xcresult_sanitize_attachments.py \
  .artifacts/ui/<run-id>/attachments_raw \
  .artifacts/ui/<run-id>/attachments \
  --clean \
  --policy redact-suspect \
  --report .artifacts/ui/<run-id>/attachment_sanitization.json
```

Policies:

- `keep`: copy all attachments unchanged. Use this only after suppressing automatic screenshots and authoring app-window/root/cropped attachments in tests.
- `redact`: replace all image attachments with neutral placeholder PNGs.
- `redact-suspect`: redact images that look full-screen or high-resolution; copy smaller images.
- `crop`: crop PNG screenshots to `--crop X,Y,WIDTH,HEIGHT`; redact crop failures by default.

## Test authoring rule

Do not use this failure pattern in agent-facing tests:

```swift
XCTAttachment(screenshot: XCUIScreen.main.screenshot())
```

Prefer window/root-element screenshots and an accessibility tree dump. For menu-bar popovers or panels without a stable `XCUIElement` screenshot, crop a full app screenshot to the union of known status-surface element frames before attaching it. On macOS, verify `XCUIApplication.screenshot()` before using it directly in agent-facing runs because some runners export display-sized images.

```swift
let attachment = XCTAttachment(screenshot: app.windows["main.window"].screenshot())
attachment.name = "main-window"
attachment.lifetime = .keepAlways
add(attachment)

let tree = XCTAttachment(string: app.debugDescription)
tree.name = "accessibility-tree"
tree.lifetime = .keepAlways
add(tree)
```

Template: `assets/templates/AgentSafeUITestArtifactsTemplate.swift`.

## Operational rule for agents

Agents should inspect `attachments/`, not `attachments_raw/`, and should not upload or quote raw full-screen screenshots unless a human explicitly approves it. If `attachments_raw/` is present, treat it as local-only evidence.
