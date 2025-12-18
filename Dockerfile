# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod files first for better caching
COPY config.yaml go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /coinops ./cmd/coinops

# Runtime stage - distroless static image for Go binaries
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy with proper ownership for nonroot user (UID 65532)
COPY --from=builder --chown=nonroot:nonroot /coinops /app/coinops
COPY --from=builder --chown=nonroot:nonroot /app/config.yaml /app/config.yaml

EXPOSE 3000

ENTRYPOINT ["/app/coinops"]
CMD ["serve", "--host", "0.0.0.0", "--config", "/app/config.yaml"]
