# Stage 1: Build
FROM rust:1.84-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --depth 1 https://github.com/zeroclaw-labs/zeroclaw.git .

RUN cargo build --release

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r zeroclaw && \
    useradd -r -u 10001 -g zeroclaw -s /sbin/nologin zeroclaw

COPY --from=builder /build/target/release/zeroclaw /usr/local/bin/zeroclaw

RUN mkdir -p /data/workspace && chown -R zeroclaw:zeroclaw /data

USER zeroclaw

EXPOSE 42617

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:42617/health || exit 1

CMD ["/usr/local/bin/zeroclaw", "gateway"]
