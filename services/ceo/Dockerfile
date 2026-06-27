# =============================================================================
#  CEO AGENT - Claude Swarm Orchestrator
#  Repositori: https://github.com/affaan-m/claude-swarm
#  Fungsi: Memecah tugas kompleks, mengoordinasikan agent paralel,
#          quality gate dengan Opus, visualisasi terminal real-time
# =============================================================================
FROM python:3.11-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/claude-swarm"
LABEL org.opencontainers.image.description="CEO Agent - Multi-agent orchestration for Claude Code"
LABEL agent.role="ceo"
LABEL agent.name="claude-swarm"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/claude-swarm.git /app/claude-swarm

WORKDIR /app/claude-swarm

RUN pip install --no-cache-dir -e ".[dev]"

# =============================================================================
#  Production stage
# =============================================================================
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/claude-swarm /app/claude-swarm

# Health server untuk menjaga container tetap hidup & merespon healthcheck
RUN pip install --no-cache-dir flask
COPY <<'HEALTHPY' /usr/local/bin/health-server.py
#!/usr/bin/env python3
"""Long-running health server for CEO container."""
import os, signal, subprocess, sys
from flask import Flask, jsonify

app = Flask(__name__)
port = int(os.environ.get("SERVICE_PORT", 8080))

@app.route("/health")
def health():
    return jsonify({"status": "ok", "role": "ceo", "service": "claude-swarm"})

@app.route("/")
def index():
    return jsonify({
        "service": "CEO Agent - Claude Swarm",
        "status": "running",
        "commands": [
            "docker exec mas-ceo claude-swarm --help",
            "docker exec mas-ceo claude-swarm \"your task here\""
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port)
HEALTHPY
RUN chmod +x /usr/local/bin/health-server.py

WORKDIR /workspace

VOLUME ["/workspace", "/data", "/config"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8080}/health || exit 1

# Long-running process: health server
# Pengguna menjalankan claude-swarm via: docker exec mas-ceo claude-swarm <task>
CMD ["python3", "/usr/local/bin/health-server.py"]
