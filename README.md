# swift-gui-verifiable-loop

Install `swift-gui-verifiable-loop/` as an agent skill. The entrypoint is `swift-gui-verifiable-loop/SKILL.md`.

## Platform scope

- **Host:** macOS Sequoia 15.x or macOS Tahoe 26.x with Xcode command-line tools.
- **Targets covered by the skill:**
  - macOS apps targeting **macOS 15** and **26**
  - iOS apps targeting **iOS 18** and **26** (typically via iOS Simulator)

## Run the verification loop manually

### iOS (Simulator, recommended)

```bash
swift-gui-verifiable-loop/scripts/ui_loop.sh   --workspace App.xcworkspace   --scheme App   --test-plan Smoke   --destination 'platform=iOS Simulator,id=<UDID>'
```

### macOS (current Mac)

```bash
swift-gui-verifiable-loop/scripts/ui_loop.sh   --workspace App.xcworkspace   --scheme App   --test-plan Smoke   --destination 'platform=macOS'
```

See `swift-gui-verifiable-loop/references/REFERENCE.md` for detailed guidance.
