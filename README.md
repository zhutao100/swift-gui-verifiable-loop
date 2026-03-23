# swift-gui-verifiable-loop

Install this folder as an agent skill. The entrypoint is `SKILL.md`.

To run the verification loop manually:

```bash
scripts/ui_loop.sh --workspace App.xcworkspace --scheme App --test-plan Smoke \
  --destination 'platform=iOS Simulator,name=iPhone 16'
```

See `references/REFERENCE.md` for detailed guidance.
