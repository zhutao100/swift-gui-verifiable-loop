#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Issue:
    kind: str  # "ERROR" | "WARN"
    message: str
    path: Path | None = None


def repo_root() -> Path:
    # .agents/skills/update-.../scripts/validate_repo.py -> repo root is 4 parents up
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_required_paths(root: Path) -> list[Issue]:
    issues: list[Issue] = []
    required = [
        root / "README.md",
        root / "LICENSE",
        root / "swift-gui-verifiable-loop" / "SKILL.md",
        root / "swift-gui-verifiable-loop" / "AGENTS.md",
        root / "swift-gui-verifiable-loop" / "references" / "REFERENCE.md",
        root / "swift-gui-verifiable-loop" / "scripts" / "ui_loop.sh",
        root / "swift-gui-verifiable-loop" / "assets" / "templates" / "XCUITestLaunchHarnessTemplate.swift",
        root / "swift-gui-verifiable-loop" / "agents" / "openai.yaml",
    ]
    for p in required:
        if not p.exists():
            issues.append(Issue("ERROR", "Missing required path", p))
    return issues


def check_skill_front_matter(skill_md: Path) -> list[Issue]:
    issues: list[Issue] = []
    text = read_text(skill_md)
    if not text.startswith("---\n"):
        issues.append(Issue("ERROR", "SKILL.md must start with YAML front matter ('---')", skill_md))
        return issues

    parts = text.split("\n---\n", 1)
    if len(parts) != 2:
        issues.append(Issue("ERROR", "SKILL.md front matter must be closed by a second '---' line", skill_md))
        return issues

    fm = parts[0].strip().splitlines()[1:]  # skip first '---'
    fm_text = "\n".join(fm)

    required_keys = ["name:", "description:", "license:", "compatibility:", "metadata:"]
    for k in required_keys:
        if k not in fm_text:
            issues.append(Issue("ERROR", f"SKILL.md front matter missing '{k}'", skill_md))

    if re.search(r"^\s*version:\s*['\"]?\d", fm_text, flags=re.MULTILINE) is None:
        issues.append(Issue("WARN", "SKILL.md front matter: metadata.version not found (expected under metadata:)", skill_md))

    return issues


def check_markdown_code_fences(root: Path) -> list[Issue]:
    issues: list[Issue] = []
    for md in root.rglob("*.md"):
        # Skip vendored content? none expected.
        text = read_text(md)
        fence_count = len(re.findall(r"```", text))
        if fence_count % 2 != 0:
            issues.append(Issue("ERROR", f"Unbalanced markdown code fences (``` count = {fence_count})", md))
    return issues


def check_executables(root: Path) -> list[Issue]:
    issues: list[Issue] = []
    scripts = [
        root / "swift-gui-verifiable-loop" / "scripts" / "ui_loop.sh",
        root / "swift-gui-verifiable-loop" / "scripts" / "xcresult_summary.sh",
        root / "swift-gui-verifiable-loop" / "scripts" / "xcresult_export.sh",
        root / "swift-gui-verifiable-loop" / "scripts" / "toolchain_fingerprint.sh",
        root / "swift-gui-verifiable-loop" / "scripts" / "simctl_prepare.sh",
    ]
    for s in scripts:
        if s.exists() and not os.access(s, os.X_OK):
            issues.append(Issue("ERROR", "Script is not executable (+x)", s))
    return issues


def check_json_schema(schema_path: Path) -> list[Issue]:
    issues: list[Issue] = []
    try:
        data = json.loads(read_text(schema_path))
    except Exception as e:  # noqa: BLE001
        issues.append(Issue("ERROR", f"Invalid JSON: {e}", schema_path))
        return issues

    required = set(data.get("required", []))
    for key in ["run_id", "results_bundle", "summary_json", "toolchain_fingerprint"]:
        if key not in required:
            issues.append(Issue("ERROR", f"Schema 'required' missing '{key}'", schema_path))
    return issues


def check_referenced_paths(root: Path) -> list[Issue]:
    issues: list[Issue] = []

    def extract_backticked_paths(text: str) -> set[str]:
        # Conservative: only validate repo-internal relative paths.
        candidates = set(re.findall(r"`([^`]+)`", text))
        return {
            c
            for c in candidates
            if c.startswith(("scripts/", "assets/", "references/"))
        }

    base = root / "swift-gui-verifiable-loop"
    docs = [
        base / "SKILL.md",
        base / "AGENTS.md",
        base / "references" / "REFERENCE.md",
    ]
    for d in docs:
        if not d.exists():
            continue
        for rel in sorted(extract_backticked_paths(read_text(d))):
            p = base / rel
            if not p.exists():
                issues.append(Issue("ERROR", f"Doc references missing path: {rel}", d))
    return issues


def main() -> int:
    root = repo_root()

    issues: list[Issue] = []
    issues += check_required_paths(root)
    skill_md = root / "swift-gui-verifiable-loop" / "SKILL.md"
    if skill_md.exists():
        issues += check_skill_front_matter(skill_md)

    issues += check_markdown_code_fences(root)
    issues += check_executables(root)

    schema_path = root / "swift-gui-verifiable-loop" / "assets" / "schemas" / "run-manifest.schema.json"
    if schema_path.exists():
        issues += check_json_schema(schema_path)

    issues += check_referenced_paths(root)

    errors = [i for i in issues if i.kind == "ERROR"]
    warns = [i for i in issues if i.kind == "WARN"]

    def fmt(i: Issue) -> str:
        loc = f" ({i.path})" if i.path else ""
        return f"{i.kind}: {i.message}{loc}"

    if issues:
        print("\n".join(fmt(i) for i in issues))
        print()
    print(f"Validation complete: {len(errors)} error(s), {len(warns)} warning(s).")

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
