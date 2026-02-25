# Stage 1: Build
FROM rust:slim AS builder

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
FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r zeroclaw && \
    useradd -r -u 10001 -g zeroclaw -m -s /sbin/nologin zeroclaw

COPY --from=builder /build/target/release/zeroclaw /usr/local/bin/zeroclaw

RUN mkdir -p /data/workspace && chown -R zeroclaw:zeroclaw /data

RUN mkdir -p /home/zeroclaw/.zeroclaw && chown -R zeroclaw:zeroclaw /home/zeroclaw/.zeroclaw
COPY --chown=zeroclaw:zeroclaw config.toml /home/zeroclaw/.zeroclaw/config.toml
COPY --chown=zeroclaw:zeroclaw entrypoint.sh /usr/local/bin/entrypoint.sh

# Container starts as root; entrypoint fixes /data ownership
# then drops to the zeroclaw user via gosu.

EXPOSE 42617

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:42617/health || exit 1

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/local/bin/zeroclaw", "gateway", "--host", "0.0.0.0"]
