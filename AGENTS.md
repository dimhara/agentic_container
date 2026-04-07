# 🤖 AGENTS.md - System Context and Architecture Directives

**ATTENTION LLM / AI ASSISTANT:**
If you are reading this file, you have been tasked with maintaining, updating, or debugging this repository. This document outlines the strict architectural, security, and design principles of this project. **You must adhere to these rules when generating new code or suggesting changes.**

## 🎯 Project Purpose
This repository builds and deploys an ultra-secure, highly optimized container sandbox for running Agentic LLMs (like `aider` and `opencode`) alongside local inference (`llama.cpp` with Vulkan acceleration). 

Because AI agents write and execute arbitrary code, the build and run environments are treated as **highly hostile**. 

---

## 🛡️ Security & Supply Chain Directives
When updating dependencies or build scripts, you must maintain the following security measures:

1. **Host Isolation via Rootless Podman:**
   - We use Podman instead of Docker. Podman's daemonless architecture and user namespaces provide rootless isolation *during the build phase*. If a compromised package attempts a supply chain attack during installation, it is trapped inside the transient build container's unprivileged namespace.
   - **Do not** introduce instructions that require root access on the host or assume a Docker daemon is running.

2. **The 7-Day Zero-Day Defense (`uv`):**
   - We use `uv` (by Astral) instead of `pip` for all Python dependencies.
   - **CRITICAL:** We enforce a dynamic 7-day release-age constraint during the build step using `uv pip install --exclude-newer "$CUTOFF_DATE"`. 
   - This physically prevents the build pipeline from pulling compromised dependencies (zero-day supply chain attacks) published to PyPI within the last week. 
   - **Do not remove this flag.** If a new package version is requested, wait 7 days.

3. **No Node.js / NPM / Bun:**
   - Although OpenCode is distributed via npm/bun, we **do not** use JavaScript package managers. OpenCode is fundamentally a compiled Go binary.
   - We use the standalone bash installation script (`curl | bash`) to download the Go binary directly. This prevents adding 100MB+ of Node/JS runtime bloat to the final image.

4. **Least Privilege Runtime:**
   - The final stage of the `Containerfile` creates and switches to an unprivileged `agent` user.
   - **Do not** leave the final image running as `root`.

---

## 🏗️ Architecture: Multi-Stage Build constraints
The `Containerfile` relies on a strict two-stage process to keep the final image tiny while supporting heavy C++ GPU compilation.

* **STAGE 1 (Builder):**
  - Installs massive dependencies: GCC, Clang, CMake, Vulkan SDKs.
  - Compiles `llama.cpp` from source with `-DGGML_VULKAN=ON`.
  - Sets up the `uv` virtual environment and downloads Python packages.
* **STAGE 2 (Final Sandbox):**
  - Uses a minimal Python base image.
  - Installs *only* the lightweight Vulkan runtime drivers (`libvulkan1`), not the SDK.
  - Copies *only* the compiled binaries (`/usr/local/bin/llama-*`) and the `/opt/venv` folder from Stage 1.
  - **Rule:** Never install build tools (like `build-essential` or `cmake`) in Stage 2.

---

## 🚀 CI/CD Constraints (GitHub Actions)
- The pipeline uses standard GitHub-hosted `ubuntu-latest` runners. 
- **Note on GPUs:** The CI runner does *not* need a GPU to compile Vulkan support; it only needs the Vulkan headers/SDK. 
- To minimize CI/CD supply chain risks, we prefer using the native, pre-installed `podman` CLI commands in bash scripts over third-party GitHub Actions, authenticating natively via the transient `GITHUB_TOKEN`.

---

## 💻 Local Runtime Instructions (Context)
When generating documentation or run commands for the human user, remember that the container requires hardware access for Vulkan acceleration. 

The standard run command must map the GPU devices and execute rootless:
```bash
podman run -it --rm \
  --device /dev/dri \
  ghcr.io/OWNER/agentic-sandbox:latest
```

## ✅ Maintenance Checklist for Future LLMs:
- [ ] Did you use `uv` instead of `pip`?
- [ ] Is the `--exclude-newer` 7-day cutoff still intact?
- [ ] Are new C++ dependencies kept strictly in the `builder` stage?
- [ ] Is the final container running as the `agent` user?
- [ ] Did you avoid introducing `node`, `npm`, or `bun`?

