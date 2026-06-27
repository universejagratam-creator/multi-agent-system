# =============================================================================
#  CTO COMMERCE AGENT - Agent of Commerce
#  Repositori: https://github.com/affaan-m/agentofcommerce
#  Fungsi: Cetak biru e-commerce otonom dengan agent swarm,
#          smart contracts, manajemen inventaris & transaksi on-chain
# =============================================================================
FROM python:3.11-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/agentofcommerce"
LABEL org.opencontainers.image.description="CTO Commerce - Agent of Commerce Ecosystem"
LABEL agent.role="cto-commerce"
LABEL agent.name="agentofcommerce"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/agentofcommerce.git /app/commerce

WORKDIR /app/commerce

RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    pydantic \
    python-multipart \
    httpx \
    redis \
    sqlalchemy \
    aiosqlite \
    jinja2 \
    aiofiles

# Solana SDK - coba install, fallback jika gagal
RUN pip install --no-cache-dir solana solders 2>/dev/null || true
RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || true

# =============================================================================
#  Production stage
# =============================================================================
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/commerce /app/commerce

# Health server
RUN pip install --no-cache-dir flask
COPY <<'HEALTHPY' /usr/local/bin/health-server.py
#!/usr/bin/env python3
"""Health server for Commerce container."""
import os
from flask import Flask, jsonify

app = Flask(__name__)
port = int(os.environ.get("SERVICE_PORT", 8084))

@app.route("/health")
def health():
    return jsonify({"status": "ok", "role": "cto-commerce", "service": "agentofcommerce"})

@app.route("/")
def index():
    return jsonify({
        "service": "CTO Commerce - Agent of Commerce",
        "status": "running",
        "commands": [
            "curl http://localhost:8084/health",
            "docker exec mas-cto-commerce python manage.py"
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port)
HEALTHPY
RUN chmod +x /usr/local/bin/health-server.py

WORKDIR /app/commerce

VOLUME ["/data", "/config", "/workspace"]

EXPOSE 8084

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8084}/health || exit 1

CMD ["python3", "/usr/local/bin/health-server.py"]
