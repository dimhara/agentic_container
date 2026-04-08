# 🤖 AGENTS.md - System Context and Architecture Directives

**ATTENTION LLM / AI ASSISTANT:**
If you are reading this file, you have been tasked with maintaining, updating, or debugging this repository. This document outlines the strict architectural, security, and design principles of this project. **You must adhere to these rules when generating new code or suggesting changes.**

## 🎯 Project Purpose
This repository builds and deploys an ultra-secure, decoupled container architecture for running Agentic LLMs (like `aider` and `opencode`) against local inference (`llama.cpp` with Vulkan acceleration). 

Because AI agents write and execute arbitrary code, the build and run environments are treated as **highly hostile**. To mitigate risks, the project is strictly divided into two containers:
1. **The Inference Server:** Holds the GPU access and serves an OpenAI-compatible API.
2. **The Agent Sandbox:** A completely unprivileged, isolated environment with no hardware access.

---

## 🛡️ Security & Supply Chain Directives
When updating dependencies or build scripts, you must maintain the following security measures:

1. **Decoupled Least Privilege (Hardware Isolation):**
   - The agent sandbox container must **never** require `--device /dev/dri`. GPU access is strictly limited to the `llama-server` container.
   - The agent sandbox runs entirely as an unprivileged `agent` user.

2. **Host Isolation via Rootless Podman:**
   - We use Podman instead of Docker for user namespaces and rootless isolation *during the build phase*.
   - **Do not** introduce instructions that require root access on the host or assume a Docker daemon is running.

3. **The 7-Day Zero-Day Defense (`uv`):**
   - We use `uv` (by Astral) instead of `pip` for Python dependencies in the agent container.
   - **CRITICAL:** We enforce a dynamic 7-day release-age constraint during the build step using `uv pip install --exclude-newer "$CUTOFF_DATE"`. 
   - **Do not remove this flag.** If a new package version is requested, wait 7 days.

4. **No Node.js / NPM / Bun / Python C++ Wrappers:**
   - We **do not** use JavaScript package managers. OpenCode is installed via its standalone bash script (`curl | bash`).
   - We **do not** use `llama-cpp-python`. We rely exclusively on the native C++ `llama-server` binary for inference.

---

## 🏗️ Architecture constraints
We use two separate build files:

* **`Containerfile.server`:**
  - **Builder Stage:** Installs heavy C++ tools, Vulkan SDKs, and compiles `llama.cpp`.
  - **Final Stage:** Contains ONLY the `llama-server` binary and runtime Vulkan drivers. No Python needed.
* **`Containerfile.agent`:**
  - **Builder Stage:** Uses `uv` to install `aider-chat` safely.
  - **Final Stage:** Minimal Python image. Copies the `uv` venv, installs `opencode`, and creates the `agent` user. Contains zero Vulkan or compilation tools.

---

## 🚀 CI/CD Constraints (GitHub Actions)
- The pipeline uses standard GitHub-hosted `ubuntu-latest` runners. 
- To minimize CI/CD supply chain risks, we use native `podman` CLI commands in bash scripts to build and push both images, authenticating via the transient `GITHUB_TOKEN`.

## ✅ Maintenance Checklist for Future LLMs:
- [ ] Is the architecture maintained strictly as two separate containers?
- [ ] Did you avoid introducing `llama-cpp-python`?
- [ ] Did you use `uv` instead of `pip`?
- [ ] Is the `--exclude-newer` 7-day cutoff still intact?
- [ ] Is the agent container running as the `agent` user?
- [ ] Did you avoid introducing `node`, `npm`, or `bun`?

