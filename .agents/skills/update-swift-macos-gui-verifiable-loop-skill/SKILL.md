---
name: update-swift-macos-gui-verifiable-loop-skill
description: Repo-internal maintainer skill. Research, validate, and update the swift-gui-verifiable-loop skill (macOS + iOS) while preserving Codex/Open-Agent compliance.
license: MIT
compatibility: macOS 15/26 and iOS 18/26 skill maintenance; requires network access for web research and Xcode CLI tools for local validation.
metadata:
  author: repo-internal
  version: "1.0"
  tags: maintenance update web-research codex-skill agentskills swiftui appkit uikit xcresult xcresulttool snapshot-testing xcuitest
---

# Self-update skill: swift-gui-verifiable-loop

This is a **repo-internal maintainer skill** intended for future agentic sessions that modify this repository.

## Objectives

Maintain:

1. **Correctness** (docs, scripts, templates match current Apple/Xcode behavior)
2. **Clarity** (explicit separation of macOS vs iOS workflows; no ambiguous platform mixing)
3. **Standards compliance** (Codex CLI skill structure + Open Agent Skills metadata)
4. **Deterministic verifiability** (examples produce `.xcresult` evidence and machine-readable summaries)

## Non-goals

- Do not add “security bypass” instructions (for example, editing TCC databases).
- Do not add iOS-only guidance to macOS sections (and vice versa).

## Repo invariants (must remain true)

- `swift-gui-verifiable-loop/` is the skill root and contains `SKILL.md`, `scripts/`, `references/`, `assets/`, and `agents/`.
- `swift-gui-verifiable-loop/SKILL.md` explicitly states:
  - macOS targets: **macOS 15 and macOS 26**
  - iOS targets: **iOS 18 and iOS 26**
  - Apple year-based numbering note for “26”
- Platform-specific artifacts are clearly labeled:
  - iOS simulator helpers live under `swift-gui-verifiable-loop/scripts/ios/`
  - iOS templates are prefixed with `iOS...`
  - macOS templates either say “macOS” in the file header comment or name

## Update workflow

### 1) Run repo checks (no web)

```bash
.agents/skills/update-swift-macos-gui-verifiable-loop-skill/scripts/validate_repo.sh
```

Fix any failures before changing content.

### 2) Web research (required)

For each major category, search for current authoritative sources:

- Apple OS versioning (macOS/iOS “26” year-based numbering)
- Xcode release notes for `xcresulttool` changes
- `performAccessibilityAudit` API and usage
- SnapshotTesting latest release + macOS/iOS layout guidance
- XCUITest platform differences (`click()` on macOS, `tap()` on iOS)
- iOS simulator determinism primitives (`simctl privacy`, `simctl io`)
- macOS UI testing permission constraints (local prompts, CI limitations)

Update `swift-gui-verifiable-loop/references/*.md` and templates to reflect verified findings.

### 3) Apply updates with minimal diffs

- Prefer small, well-scoped edits.
- Keep examples runnable (copy-paste safe).
- Avoid hard-coding “latest versions” unless you also update the self-update playbook to refresh them.

### 4) Validate with a local smoke run (when possible)

If you have a sample Xcode project available locally:

- Run `scripts/ui_loop.sh` once for macOS, once for iOS Simulator.
- Confirm `.xcresult` is produced and `summary.json` and exported attachments exist.

### 5) Preserve standards compliance

- Do not change the top-level skill directory name.
- Keep metadata YAML frontmatter valid.
- Keep `agents/openai.yaml` present under each skill.

## Where to record “freshness”

When updating version-sensitive facts (OS numbering, Xcode behavior, SnapshotTesting releases):

- Update the relevant reference doc.
- Add/adjust a short note in the doc that indicates what was verified.
- Prefer linking to primary sources (Apple docs, Apple release notes, upstream GitHub releases).

See `references/REFERENCE.md` in this nested skill for a maintainer checklist.
