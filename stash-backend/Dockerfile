FROM golang:1.25-alpine AS base

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# --- Development stage ---
FROM base AS dev

RUN go install github.com/air-verse/air@latest

EXPOSE 8080

CMD ["air"]

# --- Production build ---
FROM base AS builder

RUN CGO_ENABLED=0 GOOS=linux go build -o /api ./cmd/api

FROM alpine:3.20

RUN apk add --no-cache ca-certificates

COPY --from=builder /api /api

EXPOSE 8080

ENTRYPOINT ["/api"]
