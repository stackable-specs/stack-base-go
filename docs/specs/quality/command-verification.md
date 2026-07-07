---
id: command-verification
layer: quality
type: spec
extends:
  - interface/commands.md
  - practices/command-workflow.md
---

# Command Verification

## Purpose

This spec defines how to verify that a project's command implementations are correct, complete, and compliant with the Project Command Specification. It provides test cases, acceptance criteria, and verification procedures for each command.

## References

- **internal** `../interface/commands.md` — Core command specification
- **internal** `../practices/command-workflow.md` — Workflow patterns
- **external** `https://testanything.org/` — Test Anything Protocol
- **external** `https://www.gnu.org/software/automake/manual/html_node/Scripts_002dbased-Testsuites.html` — GNU Automake test suites

---

## Verification Framework

### Test Categories

| Category | Purpose | Location |
| -------- | ------- | -------- |
| Contract | Does the command meet the spec? | `tests/contract/` |
| Behavior | Does the command work correctly? | `tests/behavior/` |
| Integration | Do commands work together? | `tests/integration/` |
| Performance | Is the command fast enough? | `tests/performance/` |

### Test Structure

```
tests/
├── contract/         # Specification compliance tests
│   ├── build/
│   ├── run/
│   ├── check/
│   ├── health/
│   └── clean/
├── behavior/         # Functional correctness tests
│   ├── build/
│   ├── run/
│   ├── check/
│   ├── health/
│   └── clean/
├── integration/      # Command composition tests
│   └── workflows/
└── performance/      # Performance benchmarks
    └── timing/
```

---

## Contract Tests

Contract tests verify that commands meet the specification.

### build Contract Tests

#### TC-BUILD-001: Idempotency

**Given:** A clean project checkout
**When:** `./build` is run twice consecutively
**Then:** Both runs succeed, and outputs are equivalent

```sh
./clean --deep
./build
BUILD_OUTPUT_1=$(find . -type f -newer .git -exec sha256sum {} \; | sort)
./build
BUILD_OUTPUT_2=$(find . -type f -newer .git -exec sha256sum {} \; | sort)
test "$BUILD_OUTPUT_1" = "$BUILD_OUTPUT_2"
```

#### TC-BUILD-002: Clean State Requirement

**Given:** A clean project checkout
**When:** `./build` is run
**Then:** All dependencies are fetched and project compiles

```sh
./clean --deep
./build
test $? -eq 0
test -f <expected-artifact>
```

#### TC-BUILD-003: Failure Clarity

**Given:** A project with missing dependency
**When:** `./build` is run
**Then:** Exit code is non-zero and error message explains the failure

```sh
# Simulate missing dependency
mv package.json package.json.bak
./build
EXIT_CODE=$?
mv package.json.bak package.json
test $EXIT_CODE -ne 0
# Verify error message explains the issue
```

#### TC-BUILD-004: Incremental Build

**Given:** A built project with one source file changed
**When:** `./build` is run
**Then:** Only affected outputs are rebuilt

```sh
./build
touch src/module.py
./build
# Verify only module.py and dependents were rebuilt
```

---

### run Contract Tests

#### TC-RUN-001: Startup Success

**Given:** A successfully built project
**When:** `./run` is executed
**Then:** The project starts and responds to signals

```sh
./build
./run &
PID=$!
sleep 5  # Wait for startup
kill -TERM $PID
wait $PID
test $? -eq 0 -o $? -eq 130
```

#### TC-RUN-002: Build Required

**Given:** A clean project (no build)
**When:** `./run` is executed
**Then:** Fails with clear message about building first

```sh
./clean --deep
./run 2>&1 | grep -i "build"
test $? -eq 0
```

#### TC-RUN-003: Graceful Shutdown

**Given:** A running project
**When:** SIGTERM or SIGINT is sent
**Then:** Process cleans up and exits cleanly

```sh
./build
./run &
PID=$!
sleep 2
kill -TERM $PID
wait $PID
test $? -eq 0 -o $? -eq 143
```

#### TC-RUN-004: Environment Configuration

**Given:** Environment variable configuration
**When:** `./run` is executed
**Then:** Configuration is respected

```sh
export PORT=9999
./build
./run &
# Verify port 9999 is used
curl localhost:9999/health
kill $PID
```

---

### check Contract Tests

#### TC-CHECK-001: Pass on Clean

**Given:** A clean, correct project
**When:** `./check` is run
**Then:** Returns 0 and outputs "PASS"

```sh
./build
./check
test $? -eq 0
./check | grep "^PASS$"
```

#### TC-CHECK-002: Fail on Issues

**Given:** A project with issues (lint errors, failing tests)
**When:** `./check` is run
**Then:** Returns non-zero and lists failures

```sh
# Introduce a lint error
echo "badcode" >> src/temp.py
./check
test $? -ne 0
./check | grep "FAIL"
rm src/temp.py
```

#### TC-CHECK-003: Determinism

**Given:** A project state
**When:** `./check` is run multiple times
**Then:** Same results each time

```sh
./check > results1.txt
./check > results2.txt
diff results1.txt results2.txt
test $? -eq 0
```

#### TC-CHECK-004: Category Selection

**Given:** A project with multiple check categories
**When:** `./check --category <category>` is run
**Then:** Only that category runs

```sh
./check --category lint
# Verify only lint ran, not tests
```

---

### health Contract Tests

#### TC-HEALTH-001: Assessment Completeness

**Given:** A healthy project
**When:** `./health` is run
**Then:** Output includes score, grade, summary, and recommendations

```sh
./health > health-output.txt
grep "Overall:" health-output.txt
grep "Strengths" health-output.txt
grep "Risks" health-output.txt
grep "Recommendations" health-output.txt
```

#### TC-HEALTH-002: Dimension Subcommands

**Given:** A project
**When:** `./health <dimension>` is run
**Then:** Output is specific to that dimension

```sh
./health complexity > complexity.txt
grep "Complexity" complexity.txt
test $? -eq 0
```

#### TC-HEALTH-003: JSON Output

**Given:** `--format json` flag
**When:** `./health --format json` is run
**Then:** Output is valid JSON with expected structure

```sh
./health --format json > health.json
jq '.score' health.json
jq '.grade' health.json
jq '.recommendations' health.json
```

#### TC-HEALTH-004: No Modification

**Given:** A project state
**When:** `./health` is run
**Then:** No files are modified

```sh
find . -type f -exec sha256sum {} \; > before.sum
./health
find . -type f -exec sha256sum {} \; > after.sum
diff before.sum after.sum
test $? -eq 0
```

---

### clean Contract Tests

#### TC-CLEAN-001: Artifact Removal

**Given:** A built project
**When:** `./clean` is run
**Then:** All build artifacts are removed

```sh
./build
./clean
# Verify build artifacts don't exist
test ! -d build/
test ! -d dist/
test ! -d node_modules/
```

#### TC-CLEAN-002: Source Preservation

**Given:** A built project with source files
**When:** `./clean` is run
**Then:** Source files are preserved

```sh
./build
SOURCE_COUNT=$(find src/ -type f | wc -l)
./clean
SOURCE_COUNT_AFTER=$(find src/ -type f | wc -l)
test $SOURCE_COUNT -eq $SOURCE_COUNT_AFTER
```

#### TC-CLEAN-003: Idempotency

**Given:** A clean project
**When:** `./clean` is run twice
**Then:** Both succeed with same result

```sh
./clean
./clean
test $? -eq 0
```

#### TC-CLEAN-004: Rebuildability

**Given:** A cleaned project
**When:** `./build` is run after `./clean`
**Then:** Build succeeds and project works

```sh
./clean
./build
./check
test $? -eq 0
```

---

## Behavior Tests

Behavior tests verify correct operation under various conditions.

### Build Behavior Tests

| Test ID | Description | Expected |
| ------- | ----------- | -------- |
| BB-001 | Build with no network (cached deps) | Success |
| BB-002 | Build with missing compiler | Clear error |
| BB-003 | Build with syntax errors | Clear error |
| BB-004 | Build with lockfile conflict | Clear error |
| BB-005 | Build concurrent invocations | Serialized or safe parallel |

### Run Behavior Tests

| Test ID | Description | Expected |
| ------- | ----------- | -------- |
| RB-001 | Run with invalid config | Clear error |
| RB-002 | Run with missing service | Clear error |
| RB-003 | Run under load | Graceful degradation |
| RB-004 | Run with memory limit | Graceful handling |
| RB-005 | Run restart recovery | Clean restart |

### Check Behavior Tests

| Test ID | Description | Expected |
| ------- | ----------- | -------- |
| CB-001 | Check with flaky tests | Skip or flag |
| CB-002 | Check with timeout | Clear timeout message |
| CB-003 | Check parallel execution | Correct results |
| CB-004 | Check with large codebase | Completes in time |
| CB-005 | Check incremental | Only changed files |

### Health Behavior Tests

| Test ID | Description | Expected |
| ------- | ----------- | -------- |
| HB-001 | Health on empty project | Meaningful assessment |
| HB-002 | Health on large project | Completes in reasonable time |
| HB-003 | Health with missing tools | Graceful degradation |
| HB-004 | Health caching | Subsequent runs faster |
| HB-005 | Health trend accuracy | Accurate comparisons |

### Clean Behavior Tests

| Test ID | Description | Expected |
| ------- | ----------- | -------- |
| CLB-001 | Clean with locked files | Warning, continues |
| CLB-002 | Clean with running process | Warning or process termination |
| CLB-003 | Clean partial (interrupted) | Safe state |
| CLB-004 | Clean different build types | All removed |
| CLB-005 | Clean permissions | Handles permission errors |

---

## Integration Tests

Integration tests verify commands work together correctly.

### Workflow Tests

#### IT-WORK-001: Clean Build Cycle

```sh
./clean
./build
./check
./run &
PID=$!
sleep 2
kill $PID
./clean
```

**Expected:** All commands succeed, no artifacts remain.

#### IT-WORK-002: Development Cycle

```sh
./build
./run --watch &
PID=$!
# Make a change
echo "# change" >> src/module.py
sleep 2  # Wait for rebuild
./check
kill $PID
```

**Expected:** Change detected, rebuild, checks pass.

#### IT-WORK-003: CI Pipeline Simulation

```sh
./clean --deep
./build
./check --all
./health --format json > health.json
test $(jq '.score' health.json) -gt 70
```

**Expected:** Pipeline completes, health score acceptable.

#### IT-WORK-004: Failure Recovery

```sh
# Introduce issue
echo "syntax error" >> src/bad.py
./check
# Verify failure
# Fix issue
rm src/bad.py
./check
# Verify success
```

**Expected:** Check fails, then succeeds after fix.

---

## Performance Tests

Performance tests ensure commands complete in reasonable time.

### Timing Benchmarks

| Command | Project Size | Max Time | Notes |
| ------- | ------------ | -------- | ----- |
| `build` | Small (<10k LOC) | 30s | From clean |
| `build` | Medium (10k-100k LOC) | 120s | From clean |
| `build` | Large (>100k LOC) | 300s | From clean |
| `build` (incremental) | Any | 10s | After clean build |
| `run` (startup) | Any | 5s | To ready state |
| `check` | Small | 10s | All checks |
| `check` | Medium | 60s | All checks |
| `check` | Large | 180s | All checks |
| `health` | Small | 5s | Full assessment |
| `health` | Medium | 30s | Full assessment |
| `health` | Large | 60s | Full assessment |
| `clean` | Any | 5s | Complete clean |

### Performance Test Cases

#### PT-BUILD-001: Clean Build Time

```sh
time ./build
# Assert time < max_time for project size
```

#### PT-BUILD-002: Incremental Build Time

```sh
./build
touch src/file.py
time ./build
# Assert time < 10s
```

#### PT-CHECK-001: Full Check Time

```sh
time ./check --all
# Assert time < max_time for project size
```

#### PT-HEALTH-001: Health Assessment Time

```sh
time ./health
# Assert time < max_time for project size
```

---

## Verification Procedures

### Pre-Release Checklist

Before releasing a project implementing this spec:

1. Run all contract tests: `./tests/contract/all.sh`
2. Run all behavior tests: `./tests/behavior/all.sh`
3. Run all integration tests: `./tests/integration/all.sh`
4. Run all performance tests: `./tests/performance/all.sh`
5. Verify clean checkout builds: `./clean --deep && ./build`
6. Verify CI pipeline passes
7. Generate health report: `./health --format json`

### Continuous Verification

Run these verifications in CI:

```yaml
# CI Pipeline
stages:
  - contract
  - behavior
  - integration
  - performance

contract:
  script: ./tests/contract/all.sh

behavior:
  script: ./tests/behavior/all.sh

integration:
  script: ./tests/integration/all.sh

performance:
  script: ./tests/performance/all.sh
```

---

## Test Reporting

### Test Output Format

Tests should produce TAP-compatible output:

```
TAP version 14
1..5
ok 1 - TC-BUILD-001: Idempotency
ok 2 - TC-BUILD-002: Clean State Requirement
not ok 3 - TC-BUILD-003: Failure Clarity
# Failed: Expected non-zero exit code
ok 4 - TC-BUILD-004: Incremental Build
ok 5 - TC-BUILD-005: Network Isolation
```

### Health Report Format

Health reports should include:

```json
{
  "timestamp": "2025-01-09T12:00:00Z",
  "score": 88,
  "grade": "B",
  "trend": "improving",
  "dimensions": {
    "complexity": {"score": 85, "assessment": "low"},
    "quality": {"score": 92, "assessment": "good"},
    "security": {"score": 78, "assessment": "moderate"}
  },
  "recommendations": [
    "Split auth/ module into smaller units",
    "Update 3 outdated dependencies",
    "Add documentation for 12 public APIs"
  ]
}
```

---

## Anti-patterns

1. **Skipping verification** — All tests must pass before release.
2. **Flaky tests** — Tests must be deterministic.
3. **Slow tests in critical path** — Keep contract tests fast.
4. **Tests that modify project state** — Tests must be isolated.
5. **Tests that require external services** — Mock or stub external dependencies.