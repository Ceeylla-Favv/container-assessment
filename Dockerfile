# ============================================
# STAGE 1: BUILD
# ============================================
FROM golang:1.23-alpine AS builder

# go.mod lists go 1.25.1 which is not yet released.
# golang:1.23-alpine is the latest stable — update when 1.25 is out.

RUN apk add --no-cache git

# Create non-root user for security
RUN adduser -D -g '' appuser

WORKDIR /app


COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./

RUN go mod download

# Copy all source code from Server/MuchToDo/ into /app
# So /app/cmd/api/main.go, /app/internal/... etc.
COPY Server/MuchToDo/ .

# Build binary from the cmd/api package (where main.go lives)
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/

# ============================================
# STAGE 2: FINAL MINIMAL IMAGE
# ============================================
FROM alpine:latest

RUN apk --no-cache add ca-certificates wget

COPY --from=builder /etc/passwd /etc/passwd

WORKDIR /app

# Copy only the compiled binary — no source code in final image
COPY --from=builder /app/main .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./main"]