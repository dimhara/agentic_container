# ==========================================
# STAGE 1: Builder (Heavy dependencies)
# ==========================================
FROM python:3.12-slim AS builder

# Install heavy C++ compilers, Vulkan SDKs, and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git curl ca-certificates \
    libvulkan-dev glslc

# 1. Build llama.cpp with Vulkan support
WORKDIR /build
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git . && \
    cmake -B build -DGGML_VULKAN=ON && \
    cmake --build build --config Release -j$(nproc)

# 2. Setup uv (Astral's fast Python package manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. Create a virtual environment and install Python agents
ENV VIRTUAL_ENV=/opt/venv
RUN uv venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Supply Chain Protection: Calculate the date 7 days ago (RFC 3339 format) 
# and use uv's --exclude-newer to block zero-day compromised packages.
# We also pass CMAKE_ARGS to ensure llama-cpp-python gets Vulkan bindings.
RUN export CUTOFF_DATE=$(date -d '7 days ago' -u +'%Y-%m-%dT%H:%M:%SZ') && \
    echo "Building with PyPI cutoff date: $CUTOFF_DATE" && \
    CMAKE_ARGS="-DGGML_VULKAN=on" uv pip install --exclude-newer "$CUTOFF_DATE" \
    aider-chat \
    llama-cpp-python

# ==========================================
# STAGE 2: Final Agent Sandbox (Lightweight)
# ==========================================
FROM python:3.12-slim

# Install ONLY the runtime requirements (Vulkan drivers, git for aider, curl for opencode)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libvulkan1 vulkan-tools curl ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

# 1. Copy over the isolated Python environment (contains Aider)
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 2. Copy over the compiled llama.cpp Vulkan binaries
COPY --from=builder /build/build/bin/llama-* /usr/local/bin/

# 3. Install OpenCode directly via its standalone binary script (No npm/bun required)
RUN curl -fsSL https://opencode.ai/install | bash

# 4. Create an unprivileged user for standard operations (Security Best Practice)
RUN useradd -m -s /bin/bash agent
USER agent
WORKDIR /home/agent

# Default command (can be overridden when you run podman)
CMD ["/bin/bash"]

