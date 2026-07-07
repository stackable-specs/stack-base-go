# ADR-002 - Adopt Make for Command Runner

## Status

Accepted

## Context

ADR-001 established the five-command interface (`build`, `run`, `check`, `health`, `clean`) as the consistent API for all stackable projects. Now we need to choose how to implement this interface.

The command runner must:
- Provide a consistent entry point for the five commands
- Work across all platforms and languages
- Support composition (commands calling other commands)
- Allow extensibility for project-specific needs
- Be universally available or trivially installable

Options considered:
- **Make** — Standard Unix build tool, Makefile-based
- **Just** — Modern command runner, Justfile-based
- **npm scripts** — JavaScript package.json scripts
- **Shell scripts** — Direct shell implementation
- **Custom binary** — Language-specific CLI tool

## Decision

We adopt **Make** as the standard command runner for implementing the five-command interface.

All projects implementing this spec will provide a `Makefile` at the repository root that implements:
- `make build` → build command
- `make run` → run command
- `make check` → check command
- `make health` → health command
- `make clean` → clean command

The Makefile serves as the canonical interface, delegating to language-specific tooling as needed.

### Implementation Requirements

```makefile
# Minimal Makefile structure
.PHONY: build run check health clean

build:
	# Language-specific build commands

run:
	# Language-specific run commands

check:
	# Language-specific check commands

health:
	# Language-specific health commands

clean:
	# Language-specific clean commands
```

### Conventions

1. **Phony targets** — All five commands are declared `.PHONY` since they don't produce files
2. **Default target** — Running `make` with no target shows help or runs `build`
3. **Quiet by default** — Commands don't echo the Makefile line (use `@` prefix for output)
4. **Idempotent** — Commands can be run multiple times safely
5. **Exit codes** — Commands pass through the underlying tool's exit codes
6. **Environment** — Make inherits the shell environment; no special handling needed

### Extensibility

Projects may add additional targets beyond the five core commands:

```makefile
.PHONY: test lint format

test:
	# Project-specific test target

lint:
	# Project-specific lint target

format:
	# Project-specific format target
```

### Dependencies

Make targets may express dependencies:

```makefile
check: build
	# Run checks after build
```

## Consequences

### Positive

- **Universal availability** — Make is installed by default on macOS, Linux, and most Unix systems
- **Zero dependencies** — No additional tool installation required
- **Proven technology** — Decades of use, well-understood semantics
- **CI/CD integration** — All CI systems support `make` commands
- **Parallel execution** — Make can run independent targets in parallel (`make -j`)
- **Dependency management** — Make's dependency model handles incremental builds naturally
- **Wide tooling support** — IDEs, editors, and tools understand Makefiles

### Negative

- **Makefile syntax** — Tab indentation and Makefile syntax can be confusing
- **Platform differences** — GNU Make vs BSD Make have subtle differences
- **No built-in help** — Unlike `just --list`, no automatic command listing
- **Limited scripting** — Complex logic better suited to external scripts

### Mitigations

- Use `.PHONY` targets consistently
- Include a `help` target for documentation
- Test with both GNU Make and BSD Make when portability matters
- Delegate complex logic to shell scripts called from Make

## Alternatives Considered

| Option | Pros | Cons | Why Not Selected |
| ------ | ---- | ---- | ---------------- |
| **Just** | Modern syntax, built-in help, excellent DX | Requires installation, not universally available | Adoption barrier for new projects |
| **npm scripts** | Standard in JS, package.json integration | JS-specific, limited composability | Not language-agnostic |
| **Shell scripts** | Maximum flexibility, no dependencies | No dependency tracking, inconsistent patterns | Reinventing Make |
| **Custom binary** | Full control, rich features | Language-specific, maintenance overhead | Over-engineering |
| **Task** | Modern Make alternative, YAML-based | Requires Go installation, less common | Adoption barrier |

## References

- **internal** [ADR-001](001-five-command-interface.md) — Five Command Project Interface
- **external** https://www.gnu.org/software/make/ — GNU Make documentation
- **external** https://makefiletutorial.com/ — Makefile tutorial
- **external** https://just.systems/ — Just command runner (considered alternative)
- **external** https://12factor.net/dev-prod-parity — Dev/prod parity principle
