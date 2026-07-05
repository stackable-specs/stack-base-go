# syntax=docker/dockerfile:1
FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY internal ./internal
COPY src ./src
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app ./src

FROM scratch
WORKDIR /app
COPY --from=builder /out/app /app/app
USER 65532:65532
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=3s --retries=3 CMD ["/app/app", "-healthcheck"]
ENTRYPOINT ["/app/app"]