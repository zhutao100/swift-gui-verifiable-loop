# swift-gui-verifiable-loop

Install `swift-gui-verifiable-loop/` as an agent skill. The entrypoint is `swift-gui-verifiable-loop/SKILL.md`.

To run the verification loop manually (from this repo root):

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=macOS'
```

iOS Simulator example:

```bash
swift-gui-verifiable-loop/scripts/ui/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

(Use `OS=26.0` when targeting iOS 26 simulator runtimes.)

See `swift-gui-verifiable-loop/references/REFERENCE.md` for detailed guidance.
