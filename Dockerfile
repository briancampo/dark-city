# ==============================================================================
# Multi-Stage Dockerfile for Dark City Server
# ==============================================================================

# --- Stage 1: Build & Compilation ---
FROM rust:1-slim-bookworm AS builder

WORKDIR /app

# Install build prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy workspace definition and dependencies
COPY Cargo.toml Cargo.lock ./
COPY xtask/ ./xtask/
COPY crates/ ./crates/

# Build release binary for dark_city_server
RUN cargo build --release -p dark_city_server

# --- Stage 2: Minimal Production Runtime ---
FROM debian:bookworm-slim AS runtime

# Install minimal runtime dependencies (CA certificates, OpenSSL, curl for health checks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create unprivileged system group and user
RUN groupadd -g 10001 darkcity && \
    useradd -u 10001 -g darkcity -d /home/darkcity -m -s /bin/sh darkcity

WORKDIR /home/darkcity

# Copy binary from builder stage
COPY --from=builder --chown=darkcity:darkcity /app/target/release/dark_city_server /usr/local/bin/dark_city_server
RUN chmod 0755 /usr/local/bin/dark_city_server

# Default environment configuration
ENV SERVER_HOST=0.0.0.0 \
    SERVER_PORT=8080 \
    RUST_LOG=info

# Switch to unprivileged user
USER 10001:10001

# Expose HTTP & WebSocket port
EXPOSE 8080

# Health check configuration
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://127.0.0.1:${SERVER_PORT}/health || exit 0

# Launch server
ENTRYPOINT ["/usr/local/bin/dark_city_server"]
