#!/usr/bin/env python3
"""Repository health summary for stack-base-go."""

from __future__ import annotations

import subprocess
import tempfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def visible_files() -> list[Path]:
    ignored = {".git", "bin"}
    return sorted(
        path
        for path in ROOT.rglob("*")
        if path.is_file()
        and not any(part in ignored for part in path.parts)
        and path.name != "coverage.out"
        and path.name != "coverage.html"
    )


def parse_frontmatter_value(path: Path, key: str) -> str:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return "unknown"

    prefix = f"{key}:"
    for line in lines[1:]:
        if line == "---":
            break
        if line.startswith(prefix):
            return line.split(":", 1)[1].strip() or "unknown"

    return "unknown"


def has_frontmatter_key(path: Path, key: str) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return False

    prefix = f"{key}:"
    for line in lines[1:]:
        if line == "---":
            return False
        if line.startswith(prefix):
            return True

    return False


def command_output(command: list[str]) -> tuple[int, str]:
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
    except FileNotFoundError:
        return 127, f"{command[0]} not found"
    return result.returncode, result.stdout.strip()


def coverage_percent() -> str:
    with tempfile.NamedTemporaryFile(prefix="stack-base-go-coverage-", delete=True) as profile:
        code, output = command_output(
            [
                "go",
                "test",
                "-coverpkg=./internal/...",
                f"-coverprofile={profile.name}",
                "./tests/...",
            ]
        )
        if code != 0:
            return f"unavailable ({first_line(output)})"

        code, output = command_output(["go", "tool", "cover", f"-func={profile.name}"])
        if code != 0:
            return f"unavailable ({first_line(output)})"

    for line in output.splitlines():
        if line.startswith("total:"):
            return line.split()[-1]

    return "unavailable"


def first_line(output: str) -> str:
    return output.splitlines()[0] if output else "command failed"


def quality_issues() -> list[str]:
    issues: list[str] = []

    code, output = command_output(["gofmt", "-l", "."])
    if code != 0:
        issues.append(f"gofmt failed: {first_line(output)}")
    elif output:
        issues.append(f"gofmt needed: {', '.join(output.splitlines())}")

    code, output = command_output(["go", "vet", "./..."])
    if code != 0:
        issues.append(f"go vet failed: {first_line(output)}")

    code, output = command_output(["go", "test", "./..."])
    if code != 0:
        issues.append(f"go test failed: {first_line(output)}")

    missing_frontmatter = []
    for spec in sorted((ROOT / "docs" / "specs").glob("*/*.md")):
        for key in ("layer", "type", "extends"):
            if not has_frontmatter_key(spec, key):
                missing_frontmatter.append(f"{spec.relative_to(ROOT)} missing {key}")

    issues.extend(missing_frontmatter)
    return issues


def main() -> int:
    files = visible_files()
    go_files = [path for path in files if path.suffix == ".go"]
    test_files = [path for path in go_files if path.name.endswith("_test.go")]
    specs = sorted((ROOT / "docs" / "specs").glob("*/*.md"))
    adrs = sorted(
        path
        for path in (ROOT / "docs" / "adr").glob("*.md")
        if path.name[:3].isdigit() and not path.name.startswith("000-")
    )
    layers = Counter(parse_frontmatter_value(path, "layer") for path in specs)
    issues = quality_issues()

    print("Repository health")
    print("=================")
    print(f"Files: {len(files)}")
    print(f"Go files: {len(go_files)}")
    print(f"Test files: {len(test_files)}")
    print(f"Coverage: {coverage_percent()}")
    print(f"Spec files: {len(specs)}")
    print(f"ADR count: {len(adrs)}")
    print()
    print("Specs by layer:")
    for layer, count in sorted(layers.items()):
        print(f"  {layer}: {count}")
    print()
    print("Quality issues:")
    if issues:
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("  none")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
