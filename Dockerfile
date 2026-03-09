FROM ubuntu:22.04

LABEL org.opencontainers.image.title="Rockit Toolchain"
LABEL org.opencontainers.image.description="Pre-built Rockit compiler, runtime, and stdlib"
LABEL org.opencontainers.image.vendor="Dark Matter Tech"

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        clang-15 lld llvm-dev libssl-dev pkg-config git curl ca-certificates && \
    ln -sf /usr/bin/clang-15 /usr/bin/clang && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY rockit-toolchain/bin/rockit /usr/local/bin/rockit
COPY rockit-toolchain/bin/fuel /usr/local/bin/fuel
COPY rockit-toolchain/share/rockit/rockit_runtime.o /usr/local/share/rockit/rockit_runtime.o
COPY rockit-toolchain/share/rockit/stdlib /usr/local/share/rockit/stdlib

RUN chmod +x /usr/local/bin/rockit /usr/local/bin/fuel && rockit version

ENV ROCKIT=/usr/local/bin/rockit
ENV RUNTIME=/usr/local/share/rockit/rockit_runtime.o
ENV STDLIB=/usr/local/share/rockit/stdlib

WORKDIR /workspace
