---
name: update-swift-macos-gui-verifiable-loop-skill
description: Repo-internal maintenance skill. Guides an agent to re-validate and update the swift-gui-verifiable-loop skill with fresh web research, tooling compatibility checks, and standards enforcement.
license: MIT
compatibility: |
  Host: macOS with Git, Python 3.12+, and standard CLI tools.
  This skill updates a repository that targets macOS 15/26 and iOS 18/26 testing workflows.
metadata:
  author: generated-by-chatgpt
  version: "1.0"
  tags: maintenance update skill-validation web-research swift xcode xcresulttool snapshot-testing xcuittest
---

# Update skill: swift-gui-verifiable-loop (repo-internal)

## When to use

Use this skill when you need to:

- refresh guidance for new Xcode / OS releases (macOS 15↔26, iOS 18↔26)
- validate that scripts still work across Xcode CLI churn (especially `xcresulttool`)
- update references/templates with current best practices and concrete examples
- ensure the repo continues to conform to Codex/Open Agent skill shape and stays internally consistent

## Non-negotiable invariants (do not break)

1. **Verifiable loop first:** the “happy path” must produce immutable evidence (`.xcresult` + derived artifacts).
2. **Platform clarity:** instructions must clearly distinguish:
   - host macOS requirements
   - macOS-target app workflows vs iOS-target app workflows
3. **No guessing:** docs must push agents to pin scheme/test plan/destination/UDID in the target project’s docs.
4. **Xcode churn resilience:** scripts should prefer modern `xcresulttool get test-results …` APIs, with safe fallbacks.
5. **Standards compliance:** top-level skill remains in `swift-gui-verifiable-loop/` with `SKILL.md` as entrypoint.

## Update procedure (strict loop)

### 1) Establish a pinned baseline

- Record:
  - `sw_vers`
  - `xcodebuild -version`
  - `xcrun xcresulttool version`
- Ensure the repo’s version notes match reality (see `swift-gui-verifiable-loop/references/platform-compatibility.md`).

### 2) Run repo validation checks

Run:

```bash
python3 .agents/skills/update-swift-macos-gui-verifiable-loop-skill/scripts/validate_repo.py
```

Fix any failures before changing content.

### 3) Web research refresh (targeted)

Search and update (only when there is evidence of change):

- **Xcode release notes** (SDK list, testing changes)
- **`xcresulttool` behavior** (deprecations, new subcommands, flags like `--legacy`)
- **Swift Testing** (attachments, traits, CI support)
- **SnapshotTesting / ViewInspector / TCA** (API changes, known issues, new best practices)
- **XCUIAutomation** (accessibility audit API changes, new recording/replay features)

Policy: prefer primary sources (Apple docs, upstream repos) over blogs.

### 4) Apply updates safely

- Keep `SKILL.md` as the short, operational contract.
- Put deep details in `references/`.
- Add concrete code/workflow examples as:
  - `assets/templates/*.swift` (copy/paste ready)
  - `scripts/*.sh` (CLI-ready)

### 5) Re-run validation and hygiene

- Re-run `validate_repo.py`.
- Run pre-commit if available:

```bash
pre-commit run --all-files
```

## Common update targets

- `swift-gui-verifiable-loop/scripts/xcresult_summary.sh`
- `swift-gui-verifiable-loop/scripts/xcresult_export.sh`
- `swift-gui-verifiable-loop/references/xcresult-bundles.md`
- `swift-gui-verifiable-loop/references/platform-compatibility.md`
- `swift-gui-verifiable-loop/references/snapshot-testing.md`

## File map

- Validator: `.agents/skills/update-swift-macos-gui-verifiable-loop-skill/scripts/validate_repo.py`
- Main skill entrypoint: `swift-gui-verifiable-loop/SKILL.md`
- Deeper docs: `swift-gui-verifiable-loop/references/`
- Templates: `swift-gui-verifiable-loop/assets/templates/`
- Scripts: `swift-gui-verifiable-loop/scripts/`
