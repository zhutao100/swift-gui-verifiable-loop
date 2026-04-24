# swift-gui-verifiable-loop

Install `swift-gui-verifiable-loop/` as an agent skill. The entrypoint is `swift-gui-verifiable-loop/SKILL.md`.

To run the verification loop manually (from this repo root):

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh --scheme App --test-plan Smoke
```

iOS Simulator example:

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

(The script auto-discovers a root `.xcworkspace`/`.xcodeproj` when present. Pass `--workspace`, `--project`, or `--package-root` to override.)

(Default destination is `platform=macOS`; set `VERBOSE=1` to stream `xcodebuild` output instead of writing per-run logs under the artifacts directory.)

(`scripts/ui/ui_loop.sh` exits non-zero when either `xcodebuild` fails or the exported xcresult summary reports a non-passing result.)

(Use `OS=26.0` when targeting iOS 26 simulator runtimes.)

See `swift-gui-verifiable-loop/references/REFERENCE.md` for detailed guidance.
