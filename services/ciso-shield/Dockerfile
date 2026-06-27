# =============================================================================
#  CISO SECURITY AGENT - AgentShield
#  Repositori: https://github.com/affaan-m/agentshield
#  Fungsi: Pemindai keamanan untuk konfigurasi agen AI,
#          deteksi hardcoded secrets, MCP audit, supply chain security
# =============================================================================
FROM python:3.11-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/agentshield"
LABEL org.opencontainers.image.description="CISO Security - AgentShield AI Agent Scanner"
LABEL agent.role="ciso"
LABEL agent.name="agentshield"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/agentshield.git /app/agentshield

WORKDIR /app/agentshield

RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    pydantic \
    pyyaml \
    rich \
    click \
    bandit \
    safety

RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || true
RUN pip install --no-cache-dir -e . 2>/dev/null || true

# =============================================================================
#  Production stage
# =============================================================================
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/agentshield /app/agentshield

# Health server untuk menjaga container tetap hidup
RUN pip install --no-cache-dir flask
COPY <<'HEALTHPY' /usr/local/bin/health-server.py
#!/usr/bin/env python3
"""Long-running health server for AgentShield container."""
import os, subprocess
from flask import Flask, jsonify

app = Flask(__name__)
port = int(os.environ.get("SERVICE_PORT", 8085))

@app.route("/health")
def health():
    return jsonify({"status": "ok", "role": "ciso", "service": "agentshield"})

@app.route("/")
def index():
    return jsonify({
        "service": "CISO Agent - AgentShield",
        "status": "running",
        "commands": [
            "docker exec mas-ciso-shield agentshield --help",
            "docker exec mas-ciso-shield agentshield scan /workspace",
            "docker exec mas-ciso-shield agentshield scan --all --format html"
        ]
    })

@app.route("/scan")
def run_scan():
    result = subprocess.run(
        ["agentshield", "scan", "/workspace", "--format", "json"],
        capture_output=True, text=True, timeout=60
    )
    return jsonify({
        "stdout": result.stdout,
        "stderr": result.stderr[-500:],
        "returncode": result.returncode
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port)
HEALTHPY
RUN chmod +x /usr/local/bin/health-server.py

WORKDIR /app/agentshield

VOLUME ["/data", "/config", "/workspace"]

EXPOSE 8085

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8085}/health || exit 1

CMD ["python3", "/usr/local/bin/health-server.py"]
