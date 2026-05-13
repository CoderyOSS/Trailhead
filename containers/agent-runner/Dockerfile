FROM rust:1.82-bookworm AS builder
WORKDIR /build
COPY . .
RUN cargo build --release -p agent-runner

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/target/release/agent-runner /usr/local/bin/agent-runner
ENTRYPOINT ["agent-runner"]
