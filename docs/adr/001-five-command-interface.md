# ADR-001 - Five Command Project Interface

## Status

Accepted

## Context

Every coding project has its own way of being built, run, tested, and maintained. This creates friction when:

- Developers switch between projects
- CI/CD pipelines need to adapt to each project
- Tools need to integrate with multiple projects
- Documentation describes project-specific commands

The industry has partial solutions (Make, npm scripts, cargo, etc.) but no consistent interface across languages and frameworks. Developers learning a new project must discover:

- How do I build this?
- How do I run this?
- How do I test this?
- How do I check the project's health?
- How do I clean up?

## Decision

We define a minimal, consistent five-command interface for all projects:

| Command  | Question                                  |
| -------- | ----------------------------------------- |
| `build`  | Can I prepare the project?                |
| `run`    | Can I use the project?                    |
| `check`  | Is the implementation correct?            |
| `health` | What is the overall state of the project? |
| `clean`  | Can I reset the project?                  |

Each command has defined:

- Purpose
- Responsibilities
- Behavior
- Exit codes
- Output format

This interface is:

1. **Language agnostic** — Works for Go, Python, Rust, JavaScript, etc.
2. **Minimal** — Only five commands for the complete lifecycle
3. **Predictable** — Same semantics everywhere
4. **Extensible** — Subcommands and flags for project-specific needs

## Consequences

### Positive

- Developers can approach any stackable project with confidence
- CI/CD pipelines can use standard commands
- Tools can integrate consistently
- Documentation can focus on project specifics, not command discovery

### Negative

- Requires implementation in each project
- May not map perfectly to all build systems
- Adds a layer of abstraction

### Trade-offs

The consistency benefits outweigh the implementation cost. The interface is simple enough that shell script wrappers can provide compliance even for complex build systems.

## Alternatives Considered

| Option | Pros | Cons | Why Not Selected |
| ------ | ---- | ---- | ---------------- |
| Make (standard targets) | Widely known | Different target names across projects | Inconsistent naming |
| npm scripts (for JS) | Standard in JS ecosystem | JS-specific | Not language agnostic |
| Just (command runner) | Excellent task runner | Not universally adopted | Requires tool adoption |
| Document per-project | Flexible | No consistency | Defeats the purpose |
| Docker Compose | Complete environment | Heavy, overkill for many projects | Not suitable for all cases |

## References

- `docs/specs/interface/commands.md` — Full command specification
- `docs/specs/practices/command-workflow.md` — Workflow patterns
- `docs/specs/quality/command-verification.md` — Verification procedures
- https://12factor.net/ — Twelve-Factor App methodology (factor 10: dev/prod parity)
- https://www.gnu.org/prep/standards/ — GNU Makefile conventions
