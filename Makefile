# stack-base-go Makefile
# Each command references its governing spec

.PHONY: help test lint fmt vet build clean coverage

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Quality gates (spec: quality/unit-testing.md)
test: ## Run tests with race detection (spec: go.md:12, unit-testing.md)
	go test -race ./...

coverage: ## Run tests with coverage report (spec: unit-testing.md)
	go test -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

# Linting (spec: language/go.md)
fmt: ## Format code with gofmt (spec: go.md:2)
	gofmt -w .
	goimports -w .

vet: ## Run go vet (spec: go.md:15)
	go vet ./...

lint: ## Run golangci-lint (spec: go.md:16)
	golangci-lint run ./...

# Build (spec: delivery/docker.md)
build: ## Build binary
	go build -o bin/app ./src

clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out coverage.html

# Development
tidy: ## Tidy modules (spec: go.md:17)
	go mod tidy

# Pre-commit checks (all specs)
check: fmt vet lint test ## Run all quality gates
	@echo "All checks passed"