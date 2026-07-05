# stack-base-go

A Go base template project following the stackable-specs methodology.

## Architecture

This project is organized with layered specifications where each layer answers exactly one question about the system:

| Layer | Question | Spec |
|-------|----------|------|
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
│       ├── practices/
│       ├── quality/
│       └── security/
├── src/                   # Application source
├── tests/                 # Automated tests
├── verify/                # Smoke/post-deploy verification
├── CLAUDE.md              # AI agent context (Claude Code)
├── AGENTS.md              # Generic AI agent context
├── .cursorrules           # Cursor IDE rules
├── go.mod                 # Go module definition
├── Makefile               # Common commands
└── README.md
```

## Key Commands

| Command | Description | Spec Reference |
|---------|-------------|----------------|
| `make test` | Run tests | `quality/unit-testing.md` |
| `make lint` | Run linters | `language/go.md` |
| `make fmt` | Format code | `language/go.md:2` |
| `make vet` | Run go vet | `language/go.md:15` |
| `make build` | Build binary | — |

## Quality Gates

- **Format**: `gofmt` passes (zero diffs)
- **Vet**: `go vet ./...` passes
- **Lint**: `golangci-lint` passes
- **Test**: `go test -race -coverprofile=coverage.out ./...`
- **Coverage**: ≥80% (configurable)

## Specs

All specs are in `docs/specs/`. Each file defines rules for a specific layer:

- **Language**: `language/go.md` — Go idioms, formatting, module hygiene
- **Practices**: `practices/*.md` — ADRs, BDRs, TDD, git workflow
- **Quality**: `quality/unit-testing.md` — Test scope and naming
- **Security**: `security/dependency-management.md` — Dependency policy
- **Delivery**: `delivery/*.md` — Docker and CI/CD conventions

## Workflow

1. Check relevant specs before making changes
2. Write tests first (TDD: `practices/tdd.md`)
3. Run quality gates before committing
4. Reference specs in commit messages and PRs

## Getting Started

1. Write ADR-001 selecting any additional platform/framework decisions
2. Copy additional specs from [stackable-specs/specs](https://github.com/stackable-specs/specs) as needed
3. Configure tooling per the language/platform specs
4. Add quality gates that enforce spec rules

## Spec-to-Enforcement Traceability

| Spec Rule | Enforcement |
|-----------|-------------|
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