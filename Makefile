# Help text as a multi-line variable
define HELP_TEXT
# CoinOps Makefile

This Makefile automates common development tasks. If you're new to Make, just
type `make` followed by a target name. For example: `make build` or `make test`.

## Quick Start

| Command        | What it does                                      |
|----------------|---------------------------------------------------|
| `make`         | Build the application (same as `make build`)      |
| `make run`     | Build and start the server on port 3000           |
| `make test`    | Run all tests                                     |
| `make help`    | Show this help message                            |

## All Available Commands

### Building

| Command              | What it does                                           |
|----------------------|--------------------------------------------------------|
| `make build`         | Compile the app for your current OS/architecture       |
| `make build-release` | Same as build, but optimized (smaller binary)          |
| `make build-linux`   | Cross-compile for Linux (x86_64/amd64)                 |
| `make build-linux-arm64` | Cross-compile for Linux (ARM64, e.g. Raspberry Pi) |
| `make build-all`     | Build for all supported platforms at once              |

### Running & Testing

| Command      | What it does                                             |
|--------------|----------------------------------------------------------|
| `make run`   | Build the app, then start the HTTP server                |
| `make test`  | Run the test suite with verbose output                   |

### Docker

| Command            | What it does                                        |
|--------------------|-----------------------------------------------------|
| `make docker-build`| Build a Docker image tagged with the version        |

### Code Quality

| Command      | What it does                                             |
|--------------|----------------------------------------------------------|
| `make fmt`   | Auto-format all Go code (fixes style issues)             |
| `make lint`  | Run the linter to check for common mistakes              |

### Utilities

| Command      | What it does                                             |
|--------------|----------------------------------------------------------|
| `make deps`  | Download and tidy Go module dependencies                 |
| `make clean` | Delete all compiled binaries                             |
| `make version` | Show the version, commit, and date that will be embedded |

## How Versioning Works

When you build, the Makefile automatically embeds version info from git:
- **Version**: From `git describe --tags` (e.g., `v1.2.3` or `abc1234`)
- **Commit**: The short git commit hash
- **Commit Date**: The timestamp of that commit (for reproducible builds)

You can override the version: `make build VERSION=v2.0.0`

## Tips for Make Beginners

- **Tab characters matter**: If you edit this file, use tabs (not spaces) for indentation
- **Running multiple targets**: `make clean build` runs clean, then build
- **Parallel builds**: `make -j4 build-all` runs up to 4 jobs in parallel
- **Verbose mode**: `make --debug build` shows what Make is doing internally
endef
export HELP_TEXT

# Show help
.PHONY: help
help:
	@echo "$$HELP_TEXT"

# Build variables
BINARY_NAME=coinops
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
# Use git commit timestamp for reproducible builds (not build time)
COMMIT_DATE=$(shell git log -1 --format=%cI 2>/dev/null || echo "unknown")

# Ldflags to inject version information
VERSION_LDFLAGS=-X pahg-template/internal/version.Version=$(VERSION) \
	-X pahg-template/internal/version.Commit=$(COMMIT) \
	-X pahg-template/internal/version.CommitDate=$(COMMIT_DATE)

# Build the binary
.PHONY: build
build:
	@echo "Building $(BINARY_NAME) $(VERSION) ($(COMMIT))..."
	go build -ldflags "$(VERSION_LDFLAGS)" -o $(BINARY_NAME) ./cmd/coinops

# Build with optimizations (smaller binary)
.PHONY: build-release
build-release:
	@echo "Building $(BINARY_NAME) $(VERSION) ($(COMMIT)) for release..."
	CGO_ENABLED=0 go build -ldflags "-s -w $(VERSION_LDFLAGS)" -o $(BINARY_NAME) ./cmd/coinops

# Cross-compile for Linux (amd64)
.PHONY: build-linux
build-linux:
	@echo "Cross-compiling $(BINARY_NAME) $(VERSION) for linux/amd64..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w $(VERSION_LDFLAGS)" -o $(BINARY_NAME)-linux-amd64 ./cmd/coinops

# Cross-compile for Linux (arm64)
.PHONY: build-linux-arm64
build-linux-arm64:
	@echo "Cross-compiling $(BINARY_NAME) $(VERSION) for linux/arm64..."
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "-s -w $(VERSION_LDFLAGS)" -o $(BINARY_NAME)-linux-arm64 ./cmd/coinops

# Cross-compile for all supported platforms
.PHONY: build-all
build-all: build-linux build-linux-arm64
	@echo "Built binaries for all platforms"

# Run the application
.PHONY: run
run: build
	./$(BINARY_NAME) serve

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning..."
	rm -f $(BINARY_NAME) $(BINARY_NAME)-linux-amd64 $(BINARY_NAME)-linux-arm64

# Show version information
.PHONY: version
version:
	@echo "Version: $(VERSION)"
	@echo "Commit: $(COMMIT)"
	@echo "Commit Date: $(COMMIT_DATE)"

# Build Docker image (version info auto-detected from git)
.PHONY: docker-build
docker-build:
	@echo "Building Docker image (version auto-detected from git)..."
	docker build \
		-t $(BINARY_NAME):$(VERSION) \
		-t $(BINARY_NAME):latest \
		.

# Run tests
.PHONY: test
test:
	go test -v ./...

# Install dependencies
.PHONY: deps
deps:
	go mod download
	go mod tidy

# Format code
.PHONY: fmt
fmt:
	go fmt ./...

# Run linter
.PHONY: lint
lint:
	golangci-lint run

# Default target
.DEFAULT_GOAL := build
