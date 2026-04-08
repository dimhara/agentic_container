# Usage
We use a decoupled, highly secure two-container architecture. The LLM runs in an isolated server container with GPU access, while the agents run in a stripped-down, completely unprivileged sandbox.

### 1. Create the internal Podman network
```bash
podman network create ai-net
```

### 2. Run the LLM Server (GPU / Vulkan Accelerated)
```bash
podman run -d --rm --name llm-server \
  --network ai-net \
  --device /dev/dri \
  -v /path/to/your/models:/models:ro \
  ghcr.io/dimhara/llama-vulkan-server:latest \
  llama-server -m /models/qwen3.5-moe.gguf --host 0.0.0.0 --port 8080 --jinja
```


### 3. Run the Agentic Sandbox (Highly Hostile, No GPU Access)
```bash
podman run -it --rm --name agent-sandbox \
  --network ai-net \
  -e OPENAI_API_BASE=http://llm-server:8080/v1 \
  -e OPENAI_API_KEY=sk-no-key-required \
  ghcr.io/dimhara/agentic-sandbox:latest
```


