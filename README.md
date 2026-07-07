# stack-base-go

A Go base template project following the stackable-specs methodology.

This repository implements the foundational command interface from
[`stack-base`](https://github.com/stackable-specs/stack-base): every project
exposes `build`, `run`, `check`, `health`, and `clean` through `make`.

## Architecture

This project is organized with layered specifications where each layer answers exactly one question about the system:

| Layer | Question | Spec |
|-------|----------|------|
| `interface` | How do developers interact with it? | Five-command interface |
| `language` | What is it written in? | Go |
| `platform` | Where does it run? | (TBD by ADR) |
| `delivery` | How is it shipped? | Docker, GitHub Actions |
| `practices` | How do we work? | MADR, BDR, TDD, Git, Conventional Commits |
| `quality` | How do we enforce? | Unit Testing |
| `security` | What must never break trust? | Dependency Management |

## Repository Layout

```
.
├── .github/workflows/     # CI/CD pipelines
├── docs/
│   ├── adr/               # Architectural Decision Records
│   ├── bdr/               # Behavior Decision Records
│   └── specs/             # Layered specifications
│       ├── delivery/
│       ├── interface/
│       ├── practices/
│       ├── quality/
│       └── security/
├── scripts/               # Project support scripts
├── src/                   # Application source
├── tests/                 # Automated tests
├── CLAUDE.md              # AI agent context (Claude Code)
├── AGENTS.md              # Generic AI agent context
├── go.mod                 # Go module definition
├── Makefile               # Common commands
└── README.md
```

## Key Commands

The five core commands are the primary project interface:

| Command | Description | Spec Reference |
|---------|-------------|----------------|
| `make build` | Build the service binary | `interface/commands.md`, ADR-001 |
| `make run` | Build and run the service | `interface/commands.md`, ADR-001 |
| `make check` | Run all deterministic quality gates | `interface/commands.md`, `quality/command-verification.md` |
| `make health` | Show repository health and quality issues | `interface/commands.md` |
| `make clean` | Remove generated artifacts | `interface/commands.md` |

Utility targets such as `make test`, `make lint`, `make fmt`, `make vet`,
`make coverage`, and `make vuln` support `make check`.

## Quality Gates

- **Format**: `gofmt` passes (zero diffs)
- **Vet**: `go vet ./...` passes
- **Lint**: `golangci-lint` passes
- **Test**: `go test -race ./...`
- **Coverage**: ≥80% (configurable)
- **Security**: `govulncheck ./...` passes

## Specs

All specs are in `docs/specs/`. Each file defines rules for a specific layer:

- **Language**: `language/go.md` — Go idioms, formatting, module hygiene
- **Interface**: `interface/commands.md` — Five-command project interface
- **Practices**: `practices/*.md` — ADRs, BDRs, TDD, git workflow
- **Quality**: `quality/unit-testing.md` — Test scope and naming
- **Quality**: `quality/command-verification.md` — Command contract verification
- **Security**: `security/dependency-management.md` — Dependency policy
- **Delivery**: `delivery/*.md` — Docker and CI/CD conventions

## stack-base Implementation

This project backfills the foundational stack-base decisions:

| ADR | Decision | Implementation |
|-----|----------|----------------|
| ADR-001 | Five Command Project Interface | `Makefile` exposes `build`, `run`, `check`, `health`, `clean` |
| ADR-002 | Adopt Make for Command Runner | The root `Makefile` is the canonical command runner |

The copied stack-base specs live under `docs/specs/interface/`,
`docs/specs/practices/command-workflow.md`, and
`docs/specs/quality/command-verification.md`.

## Workflow

1. Check relevant specs before making changes, starting with `interface/commands.md`
2. Write tests first (TDD: `practices/tdd.md`)
3. Run `make check` before committing
4. Reference specs in commit messages and PRs

## Getting Started

1. Run `make build`
2. Run `make health`
3. Run `make check`
4. Run `make run`

## Spec-to-Enforcement Traceability

| Spec Rule | Enforcement |
|-----------|-------------|
| `interface/commands.md` | Five primary Make targets |
| `command-verification.md` | CI validates the five-command interface |
| `go.md:2` | `gofmt` in pre-commit + CI |
| `go.md:3` | `goimports` in pre-commit + CI |
| `go.md:12` | `go test -race` in CI |
| `go.md:15` | `go vet ./...` in pre-commit + CI |
| `go.md:16` | `staticcheck` via golangci-lint |
| `go.md:17` | Git track `go.mod` + `go.sum` |
| `unit-testing.md` | `go test -coverprofile` with ≥80% threshold |
| `conventional-commits.md` | commitlint in pre-commit + CI |

## License

MIT
