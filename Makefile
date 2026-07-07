APP := bin/app
COVERAGE_FILE := coverage.out
COVERAGE_THRESHOLD := 80
GO_PACKAGES := ./...
PYTHON ?= python3

.DEFAULT_GOAL := help

.PHONY: help build run check health clean install install-tools fmt fmt-check vet lint test coverage vuln docker-build compose-config tidy

help: ## Show available commands
	@echo "Core commands:"
	@echo "  make build    Build the service binary"
	@echo "  make run      Run the service"
	@echo "  make check    Run all local quality gates"
	@echo "  make health   Show repository health"
	@echo "  make clean    Remove generated artifacts"
	@echo
	@echo "Utility commands:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z_-]+:.*## / && $$1 !~ /^(help|build|run|check|health|clean)$$/ {printf "  make %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Core: build the service binary (spec: interface/commands.md)
	@CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o $(APP) ./src
	@echo "Project is ready to run."

run: build ## Core: run the service (spec: interface/commands.md)
	@echo "Project is running."
	@./$(APP)

check: fmt-check vet lint test coverage vuln ## Core: run all local quality gates (spec: interface/commands.md)
	@echo "PASS"

health: ## Core: show repository health (spec: interface/commands.md)
	@$(PYTHON) scripts/health.py

clean: ## Core: remove generated artifacts (spec: interface/commands.md)
	@rm -rf bin $(COVERAGE_FILE) coverage.html
	@echo "Project is clean."

install: install-tools ## Install development tools and git hooks
	pre-commit install
	pre-commit install --hook-type commit-msg

install-tools: ## Install pinned Go development tools
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
	go install golang.org/x/vuln/cmd/govulncheck@v1.1.4

fmt: ## Format Go files (spec: go.md:2-3)
	gofmt -w .
	goimports -w .

fmt-check: ## Check Go formatting without modifying files
	@test -z "$$(gofmt -l .)" || { gofmt -l .; exit 1; }
	@test -z "$$(goimports -l .)" || { goimports -l .; exit 1; }

vet: ## Run go vet (spec: go.md:15)
	go vet $(GO_PACKAGES)

lint: ## Run golangci-lint (spec: go.md:16)
	golangci-lint run $(GO_PACKAGES)

test: ## Run tests with race detection (spec: go.md:12)
	go test -race $(GO_PACKAGES)

coverage: ## Enforce application line coverage (spec: unit-testing.md:15)
	go test -race -coverpkg=./internal/... -coverprofile=$(COVERAGE_FILE) ./tests/...
	@coverage=$$(go tool cover -func=$(COVERAGE_FILE) | awk '/^total:/ {gsub("%", "", $$3); print $$3}'); \
	awk -v coverage="$$coverage" -v threshold="$(COVERAGE_THRESHOLD)" 'BEGIN { \
		printf "Total coverage: %.1f%% (minimum: %.1f%%)\n", coverage, threshold; \
		exit !(coverage >= threshold) \
	}'

vuln: ## Scan dependencies for known vulnerabilities
	govulncheck $(GO_PACKAGES)

docker-build: ## Build the production container with BuildKit
	DOCKER_BUILDKIT=1 docker build --tag stack-base-go:local .

compose-config: ## Validate Compose configuration
	docker compose config --quiet

tidy: ## Tidy and verify Go modules (spec: go.md:17)
	go mod tidy
	git diff --exit-code -- go.mod go.sum
