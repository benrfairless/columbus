# Multi-stage Dockerfile for building all Columbus components
# Build stage for frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npx tailwindcss -i input.css -o style.css --minify

# Build stage for Go binaries
FROM golang:1.19-alpine AS go-builder
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git gcc musl-dev

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Create frontend templates with CSS
RUN mkdir -p frontend/templates && \
    echo '{{ define "stylecss" }}' > frontend/templates/stylecss.tmpl && \
    echo '<style>' >> frontend/templates/stylecss.tmpl
COPY --from=frontend-builder /app/frontend/style.css /tmp/style.css
RUN cat /tmp/style.css >> frontend/templates/stylecss.tmpl && \
    echo '</style>' >> frontend/templates/stylecss.tmpl && \
    echo '{{ end }}' >> frontend/templates/stylecss.tmpl

# Build all binaries
RUN CGO_ENABLED=1 GOOS=linux go build \
    -tags "netgo,osusergo" \
    -ldflags="-s -w -linkmode external -extldflags '-static'" \
    -o columbus-server \
    ./server/.

RUN CGO_ENABLED=1 GOOS=linux go build \
    -tags "netgo,osusergo" \
    -ldflags="-s -w -linkmode external -extldflags '-static'" \
    -o columbus-scanner \
    ./scanner/.

RUN CGO_ENABLED=1 GOOS=linux go build \
    -tags "netgo,osusergo" \
    -ldflags="-s -w -linkmode external -extldflags '-static'" \
    -o columbus-dns \
    ./dns/.

# Server final stage
FROM alpine:latest AS server
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=go-builder /app/columbus-server .
COPY server/server.docker.conf /etc/columbus/server.conf
EXPOSE 8080
CMD ["./columbus-server", "-config", "/etc/columbus/server.conf"]

# Scanner final stage
FROM alpine:latest AS scanner
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=go-builder /app/columbus-scanner .
COPY scanner/scanner.docker.conf /etc/columbus/scanner.conf
CMD ["./columbus-scanner", "-config", "/etc/columbus/scanner.conf"]

# DNS final stage
FROM alpine:latest AS dns
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=go-builder /app/columbus-dns .
COPY dns/dns.docker.conf /etc/columbus/dns.conf
EXPOSE 1053/udp
EXPOSE 1053/tcp
CMD ["./columbus-dns", "-config", "/etc/columbus/dns.conf"]
