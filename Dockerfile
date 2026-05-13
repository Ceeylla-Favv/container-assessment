# -----------------------------
# Stage 1: Build the Go app
# -----------------------------
FROM golang:1.25.1-alpine AS builder

# Install git
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go.mod and go.sum first (better caching)
COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the application source code
COPY Server/MuchToDo/ .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main ./cmd/api

# -----------------------------
# Stage 2: Lightweight runtime
# -----------------------------
FROM alpine:3.21

# Install certificates + wget for healthcheck
RUN apk add --no-cache ca-certificates wget

# Create non-root user
RUN adduser -D appuser

WORKDIR /app

# Copy built binary
COPY --from=builder /app/main .

# Change ownership
RUN chown appuser:appuser /app/main

# Use non-root user
USER appuser

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget --spider --quiet http://localhost:8080/health || exit 1

# Run app
CMD ["./main"]