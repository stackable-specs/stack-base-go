# Project: stack-base-go

Go base template following the stackable-specs methodology.

## Architecture

Layered specifications where each spec answers exactly one question about the system. See CLAUDE.md for full details.

Foundational ADRs:
- **ADR-001**: Five Command Project Interface
- **ADR-002**: Adopt Make for Command Runner

## Key Commands

| Command | Description | Spec Reference |
|---------|-------------|----------------|
| `make build` | Build the service binary | `commands.md`, ADR-001 |
| `make run` | Build and run the service | `commands.md`, ADR-001 |
| `make check` | All quality gates | `commands.md`, `command-verification.md` |
| `make health` | Repository health summary | `commands.md` |
| `make clean` | Remove generated artifacts | `commands.md` |

Utility targets include `make test`, `make lint`, `make fmt`, `make vet`, `make coverage`, and `make vuln`.

## Quality Gates

- `gofmt` passes
- `go vet ./...` passes
- `golangci-lint run` passes
- `go test -race ./...` passes
- Coverage ≥80%

## Specs

All specs are in `docs/specs/`. Check relevant specs before making changes.

## Workflow

1. Check relevant specs in `docs/specs/`, starting with `docs/specs/interface/commands.md`
2. Write tests first (TDD)
3. Run `make check` before committing
4. Reference specs in commit messages
