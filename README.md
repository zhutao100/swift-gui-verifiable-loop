# swift-gui-verifiable-loop

Install this folder as an agent skill. The entrypoint is `SKILL.md`.

To run the verification loop manually:

```bash
scripts/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=macOS'
```

iOS Simulator example:

```bash
scripts/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
```

(Use `OS=26.0` when targeting iOS 26 simulator runtimes.)

See `references/REFERENCE.md` for detailed guidance.
