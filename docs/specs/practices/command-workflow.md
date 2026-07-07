---
id: command-workflow
layer: practices
type: spec
extends:
  - interface/commands.md
---

# Command Workflow

## Purpose

The command specification defines *what* commands exist and *what* they do. This spec defines *how* developers work with those commands day-to-day. Proper workflow ensures the commands compose cleanly, support common development patterns, and integrate smoothly with CI/CD.

## References

- **internal** `../interface/commands.md` — Core command specification
- **internal** `../quality/command-verification.md` — Verification procedures
- **external** `https://semver.org/` — Semantic Versioning
- **external** `https://www.conventionalcommits.org/` — Conventional Commits

---

## Development Workflow

### New Checkout

When cloning or checking out a project for the first time:

```sh
# 1. Clone the repository
git clone <repo-url>
cd <repo>

# 2. Build the project
./build

# 3. Verify the project is healthy
./health

# 4. Run checks to verify correctness
./check

# 5. Run the project to verify it works
./run
```

After this sequence, the developer should have confidence the project is working correctly.

### Daily Development

The standard development loop:

```sh
# Start of session
./build          # Ensure project is up to date

# During development (iterative)
./run --watch    # Run with hot reload
./check          # Verify changes
./health         # Assess overall state

# Before commit
./check --all    # Run all checks
./health         # Verify project health
```

### Clean Build

When encountering build issues or stale artifacts:

```sh
# Reset to known state
./clean --deep

# Fresh build
./build

# Verify
./check
```

### CI/CD Pipeline

The standard CI pipeline:

```sh
# Stage 1: Build
./build

# Stage 2: Check
./check --all

# Stage 3: Health (optional, for reporting)
./health --format json > health-report.json

# Stage 4: Package (project-specific)
# ...
```

---

## Command Composition

### Ordering

Commands have natural ordering dependencies:

```
clean → build → run
           ↓
         check
           ↓
         health
```

- `clean` removes artifacts; `build` recreates them
- `build` must succeed before `run` or `check`
- `check` validates the build output
- `health` can run independently but is most useful after `check` passes

### Idempotency Expectations

| Command   | Idempotent | Notes |
| --------- | ---------- | ----- |
| `build`   | Yes        | Same inputs → same outputs |
| `run`     | No         | Stateful process |
| `check`   | Yes        | Same inputs → same results |
| `health`  | Yes        | Read-only assessment |
| `clean`   | Yes        | Already-clean is clean |

---

## Exit Code Handling

### In Shell Scripts

```sh
#!/bin/bash
set -e  # Exit on any command failure

./build || { echo "Build failed"; exit 1; }
./check || { echo "Checks failed"; exit 1; }
./run
```

### In CI Pipelines

```yaml
# Example GitHub Actions
steps:
  - name: Build
    run: ./build

  - name: Check
    run: ./check --all

  - name: Health Report
    run: ./health --format json > health-report.json
    continue-on-error: true
```

### Exit Code Meanings

| Code | Meaning | CI Behavior |
| ---- | ------- | ----------- |
| 0    | Success | Continue pipeline |
| 1    | Failure | Fail pipeline |
| 2    | Configuration error | Fail pipeline, check config |
| 3    | Dependency error | Fail pipeline, check deps |

---

## Environment Handling

### Configuration Sources

Commands should respect configuration in this priority order (highest first):

1. Command-line arguments (`./build --target release`)
2. Environment variables (`BUILD_TARGET=release ./build`)
3. Configuration files (`.env`, `config.yaml`, etc.)
4. Defaults (hardcoded sensible values)

### Environment Files

Projects may use environment files for configuration:

```sh
# .env file
BUILD_TARGET=release
RUN_MODE=development
CHECK_CATEGORIES=lint,tests
```

### Secrets

Commands must not:
- Log secrets to stdout/stderr
- Include secrets in error messages
- Write secrets to files in plaintext

Use environment variables or secret managers for sensitive configuration.

---

## Output Handling

### Standard Output

- Human-readable by default
- Progress indicators for long operations
- Success/failure messages at the end

### Standard Error

- Error messages and diagnostics
- Warnings (non-fatal issues)
- Debug information (when `--verbose`)

### Machine-Readable Output

When `--format json` is specified:

```json
{
  "command": "check",
  "result": "fail",
  "exitCode": 1,
  "summary": {
    "total": 42,
    "passed": 39,
    "failed": 3
  },
  "failures": [
    {
      "category": "lint",
      "count": 2,
      "items": [
        "src/auth.py:42: E302 expected 2 blank lines",
        "src/auth.py:87: E225 missing whitespace"
      ]
    },
    {
      "category": "tests",
      "count": 1,
      "items": [
        "tests/test_auth.py::test_login - AssertionError"
      ]
    }
  ]
}
```

---

## Common Patterns

### Parallel Execution

Some checks can run in parallel:

```sh
# Run lint and tests in parallel
./check --category lint &
./check --category tests &
wait
```

### Watch Mode

For continuous development:

```sh
# Watch for changes, rebuild and test
while true; do
  ./build && ./check
  inotifywait -r -e modify src/
done
```

### Selective Checks

Target specific areas:

```sh
# Check only changed files
./check --files $(git diff --name-only main)

# Check specific module
./check --module auth
```

### Health Reporting

Generate reports for tracking:

```sh
# Daily health snapshot
./health --format json > reports/health-$(date +%Y-%m-%d).json

# Trend analysis
ls reports/health-*.json | xargs -I {} jq -s '.[]' {} | \
  jq 'select(.trend == "declining")'
```

---

## Version Control Integration

### Pre-commit Hooks

Run checks before allowing commits:

```sh
#!/bin/bash
# .git/hooks/pre-commit

# Format check
./check --category format || {
  echo "Format check failed. Run: ./check --fix"
  exit 1
}

# Lint check
./check --category lint || {
  echo "Lint errors found. Fix before committing."
  exit 1
}
```

### Pre-push Hooks

Run full validation before pushing:

```sh
#!/bin/bash
# .git/hooks/pre-push

./check --all || {
  echo "Checks failed. Fix before pushing."
  exit 1
}
```

### CI Badge Requirements

Projects implementing this spec should display:

- Build status (from `build` + `check`)
- Health score (from `health`)
- Coverage (from `check --category tests`)

---

## Troubleshooting

### Build Failures

```sh
# 1. Clean and retry
./clean --deep && ./build

# 2. Check dependencies
./health dependencies

# 3. Verbose output
./build --verbose
```

### Run Failures

```sh
# 1. Verify build succeeded
./build

# 2. Check configuration
./health runtime

# 3. Check required services
./health --category services
```

### Check Failures

```sh
# 1. Get detailed output
./check --verbose

# 2. Fix automatically if possible
./check --fix

# 3. Run specific category
./check --category lint
```

### Health Issues

```sh
# 1. View specific dimension
./health complexity

# 2. View trends
./health trends

# 3. Generate detailed report
./health --format json > health-detail.json
```

---

## Anti-patterns

1. **Skipping `clean` before debugging build issues** — Stale artifacts cause mysterious failures.
2. **Running `check` without `build`** — Tests may run against stale code.
3. **Ignoring `health` warnings** — Small issues compound into large ones.
4. **Committing while `check` fails** — Breaks team workflow and CI.
5. **Running `clean` without following with `build`** — Leaves project unusable.
6. **Hardcoding configuration in commands** — Makes environments non-portable.