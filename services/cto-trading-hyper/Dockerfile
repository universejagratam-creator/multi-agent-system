# =============================================================================
#  CTO TRADING HYPERMAMBA AGENT - Advanced Time-Series Analysis
#  Repositori: https://github.com/affaan-m/HyperMamba
#  Fungsi: Arsitektur Mamba State Space, Hypernetworks, Meta-Learning,
#          analisis time-series untuk prediksi pasar keuangan
#
#  Catatan: mamba-ssm membutuhkan CUDA GPU. Di CPU-only (Celeron),
#  kita install fallback tanpa akselerasi GPU.
# =============================================================================
FROM python:3.11-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/HyperMamba"
LABEL org.opencontainers.image.description="CTO Trading - HyperMamba Advanced Time-Series"
LABEL agent.role="cto-trading"
LABEL agent.name="hypermamba"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/HyperMamba.git /app/hypermamba

WORKDIR /app/hypermamba

# Install PyTorch (CPU version)
RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

# Install core dependencies
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    matplotlib \
    scikit-learn \
    scipy \
    einops \
    tqdm \
    hydra-core \
    omegaconf \
    fastapi \
    uvicorn \
    pydantic

# Mamba-SSM: hanya install jika ada CUDA, fallback jika tidak
# Di CPU-only (Celeron), mamba-ssm TIDAK bisa digunakan
# Gunakan selective_scan_cpu sebagai alternatif
RUN pip install --no-cache-dir \
    selective-scan-cpu 2>/dev/null || true

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
COPY --from=builder /app/hypermamba /app/hypermamba

# Health server
RUN pip install --no-cache-dir flask
COPY <<'HEALTHPY' /usr/local/bin/health-server.py
#!/usr/bin/env python3
"""Health server for HyperMamba container."""
import os
from flask import Flask, jsonify

app = Flask(__name__)
port = int(os.environ.get("SERVICE_PORT", 8083))

@app.route("/health")
def health():
    return jsonify({"status": "ok", "role": "cto-trading", "service": "hypermamba"})

@app.route("/")
def index():
    return jsonify({
        "service": "CTO Trading - HyperMamba",
        "status": "running",
        "note": "CPU-only mode (mamba-ssm requires CUDA)",
        "commands": [
            "docker exec mas-cto-trading-hyper python train.py",
            "docker exec mas-cto-trading-hyper python predict.py --symbol BTC-USD"
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port)
HEALTHPY
RUN chmod +x /usr/local/bin/health-server.py

WORKDIR /app/hypermamba

VOLUME ["/data", "/config", "/models", "/workspace"]

EXPOSE 8083

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8083}/health || exit 1

CMD ["python3", "/usr/local/bin/health-server.py"]
