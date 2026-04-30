# swift-gui-verifiable-loop

Install `swift-gui-verifiable-loop/` as an agent skill. The entrypoint is `swift-gui-verifiable-loop/SKILL.md`.

To run the verification loop manually (from this repo root):

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh --scheme App --test-plan Smoke
```


Agent-safe macOS UI example:

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh \
  --workspace App.xcworkspace \
  --scheme App \
  --test-plan Smoke \
  --destination 'platform=macOS' \
  --reuse-build \
  --system-attachment-lifetime keepNever \
  --sanitize-screenshots keep \
  --delete-raw-attachments
```

This suppresses automatic full-screen XCTest screenshots via the generated `.xctestrun` and keeps explicit app-window or cropped UI-test attachments as the agent-facing evidence.

iOS Simulator example:

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

(The script auto-discovers a root `.xcworkspace`/`.xcodeproj` when present. Pass `--workspace`, `--project`, or `--package-root` to override.)

(Default destination is `platform=macOS`; set `VERBOSE=1` to stream `xcodebuild` output instead of writing per-run logs under the artifacts directory.)

(`scripts/ui/ui_loop.sh` exits non-zero when either `xcodebuild` fails or the exported xcresult summary reports a non-passing result.)

(Use `OS=26.0` when targeting iOS 26 simulator runtimes.)

Refresh an existing target project that was set up by an older skill version:

```bash
swift-gui-verifiable-loop/scripts/project/update_ui_loop_tools.sh \
  --apply \
  --platform macos \
  /path/to/target-repo
```

See `swift-gui-verifiable-loop/references/REFERENCE.md` for detailed guidance.
