# Build stage
FROM golang:1.23-alpine AS builder

# Build arguments for version information
ARG VERSION=dev
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

WORKDIR /app

# Copy go mod files first for better caching
COPY config.yaml go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary with version information
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w \
    -X pahg-template/internal/version.Version=${VERSION} \
    -X pahg-template/internal/version.Commit=${COMMIT} \
    -X pahg-template/internal/version.BuildDate=${BUILD_DATE}" \
    -o /coinops ./cmd/coinops

# Runtime stage - distroless static image for Go binaries
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy with proper ownership for nonroot user (UID 65532)
COPY --from=builder --chown=nonroot:nonroot /coinops /app/coinops
COPY --from=builder --chown=nonroot:nonroot /app/config.yaml /app/config.yaml

EXPOSE 3000

ENTRYPOINT ["/app/coinops"]
CMD ["serve", "--host", "0.0.0.0", "--config", "/app/config.yaml"]
