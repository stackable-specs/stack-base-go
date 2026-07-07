# Architectural Decision Records

This directory holds MADR-format records for this stack.
Format and lifecycle rules: [`docs/specs/practices/madr.md`](../specs/practices/madr.md).

ADR-001 and ADR-002 are the foundational decisions inherited from
[`stack-base`](https://github.com/stackable-specs/stack-base). All subsequent
ADRs extend that command interface and Make-based runner.

## Index

| ADR | Title | Status |
| --- | ----- | ------ |
| [001](001-five-command-interface.md) | Five Command Project Interface | Accepted |
| [002](002-adopt-make-for-command-runner.md) | Adopt Make for Command Runner | Accepted |
| [003](003-go-language.md) | Go as Primary Language | Accepted |
| [004](004-docker-github-actions.md) | Docker and GitHub Actions for Delivery | Accepted |
| [005](005-development-practices.md) | Development Practices (MADR, BDR, TDD, Git, Conventional Commits) | Accepted |
| [006](006-unit-testing.md) | Unit Testing as Quality Gate | Accepted |
| [007](007-dependency-management.md) | Dependency Management Policy | Accepted |

## Authoring

Copy [`000-template.md`](000-template.md), assign the next monotonic number, and open a PR.
