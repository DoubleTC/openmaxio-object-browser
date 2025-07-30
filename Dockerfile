# Stage 1: Build frontend with Yarn using Node 18 on Alpine
FROM node:20-alpine AS web-builder

WORKDIR /app

# Install required build tools
RUN apk add --no-cache git make

# Clone repo and checkout version
RUN git clone https://github.com/OpenMaxIO/openmaxio-object-browser.git .
WORKDIR /app/web-app
RUN git checkout v1.7.6

# Bật corepack và cài đúng yarn 4.4.0
RUN corepack enable && corepack prepare yarn@4.4.0 --activate

# Install dependencies and build frontend
RUN yarn install && yarn build

# Stage 2: Build console binary using Go
FROM golang:1.23-alpine AS console-builder

WORKDIR /src

# Install dependencies
RUN apk add --no-cache make git

# Copy source code from web-builder
COPY --from=web-builder /app /src

# Build console binary
RUN make console

# Stage 3: Final lightweight runtime image
FROM alpine:latest

# Add CA certs for TLS support
RUN apk add --no-cache ca-certificates

# Copy only the built binary
COPY --from=console-builder /src/console /console

# Set default MinIO server (can override with ENV)
ENV CONSOLE_MINIO_SERVER=http://minio:9000

# Expose port
EXPOSE 9090

# Run the console server
ENTRYPOINT ["/console", "server"]
