# Usage
We use a decoupled, highly secure two-container architecture. The LLM runs in an isolated server container 
with GPU access, while the agents run in a stripped-down, completely unprivileged sandbox.

### 1. Create the internal Podman network
```bash
podman network create ai-net
```

### 2. Build the Agent Sandbox (7-Day UV Constraint)
To build with a **relative** date (dynamic, invalidates cache):
```bash
podman build --build-arg CUTOFF_DATE="$(date -d '7 days ago' -u +'%Y-%m-%dT%H:%M:%SZ')" \
  -t ghcr.io/dimhara/agentic-sandbox:latest -f Containerfile.agent .
```

To build with an **absolute** date (static, preserves cache locally):
```bash
podman build --build-arg CUTOFF_DATE="2026-05-01T00:00:00Z" \
  -t ghcr.io/dimhara/agentic-sandbox:latest -f Containerfile.agent .
```

### 3. Run the LLM Server (GPU / Vulkan Accelerated)
```bash
podman run -d --rm --name llm-server \
  --network ai-net \
  --device /dev/dri \
  -v /path/to/your/models:/models:ro \
  ghcr.io/dimhara/llama-vulkan-server:latest \
  llama-server -m /models/qwen3.5-moe.gguf --host 0.0.0.0 --port 8080 --jinja
```

### 4. Run the Agentic Sandbox
Ensure an init.sh exists in your current directory to load keys, aliases and git config.

```bash
podman run -it --rm --name agent-sandbox -v $(pwd):/home/agent/workspace:U \
  --network ai-net \
  ghcr.io/dimhara/agentic-sandbox:latest
```

The ~agent/.bashrc will source workspace/init.sh  (as well as init_gui.sh in the case of agent_vlc).
See example under init_examples.

init.sh looks like this:

```bash
# Git
git config --global user.name "Alice"
git config --global user.email "alice@local"

# LLM Keys
export OPENAI_API_BASE="http://llm-server:8080/v1"
export OPENAI_API_KEY="sk-no-key-required"

# Aliases
alias ll="ls -la"
```
