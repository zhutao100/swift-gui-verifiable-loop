# Maintainer checklist (repo-internal)

## Standards compliance

- [ ] `swift-gui-verifiable-loop/` contains `SKILL.md`, `scripts/`, `references/`, `assets/`, `agents/`.
- [ ] `swift-gui-verifiable-loop/agents/openai.yaml` exists.
- [ ] All frontmatter blocks are valid YAML and include `name` + `description`.

## Platform clarity

- [ ] `swift-gui-verifiable-loop/SKILL.md` explicitly lists macOS 15/26 and iOS 18/26.
- [ ] macOS and iOS command examples are in separate labeled blocks.
- [ ] macOS templates do not use iOS-only APIs/configs (and vice versa).

## Web-verified facts (refresh periodically)

- [ ] Apple OS version numbering (“26” year-based)
- [ ] SnapshotTesting latest release and any API deprecations
- [ ] Xcode release notes for `xcresulttool` subcommand changes
- [ ] `performAccessibilityAudit` API signatures and behavior
- [ ] iOS simulator permission coverage of `simctl privacy` (and known gaps)

## Script integrity

- [ ] `scripts/ui_loop.sh` produces `results.xcresult`, `summary.json`, and exported artifacts.
- [ ] `scripts/xcresult_summary.sh` uses structured subcommands when available.
- [ ] iOS simulator scripts live under `scripts/ios/` and are optional.

## Security posture

- [ ] No instructions to bypass macOS privacy/security protections.
- [ ] CI guidance describes constraints and safe alternatives.
