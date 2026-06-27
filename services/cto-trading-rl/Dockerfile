# =============================================================================
#  CTO TRADING RL AGENT - Behavioral Reinforcement Learning
#  Repositori: https://github.com/affaan-m/Behavioral_RL
#  Fungsi: Reinforcement learning dengan bias perilaku manusia,
#          Iowa Gambling Task, Prospect Theory, CVaR risk management
# =============================================================================
FROM python:3.11-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/Behavioral_RL"
LABEL org.opencontainers.image.description="CTO Trading - Behavioral Reinforcement Learning"
LABEL agent.role="cto-trading"
LABEL agent.name="behavioral-rl"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/Behavioral_RL.git /app/behavioral-rl

WORKDIR /app/behavioral-rl

# Install PyTorch (CPU version)
RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

# Install ML dependencies - gym untuk kompatibilitas dengan Behavioral_RL
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    gym \
    matplotlib \
    seaborn \
    scikit-learn \
    scipy \
    tqdm \
    fastapi \
    uvicorn \
    pydantic

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
COPY --from=builder /app/behavioral-rl /app/behavioral-rl

# Health server
RUN pip install --no-cache-dir flask
COPY <<'HEALTHPY' /usr/local/bin/health-server.py
#!/usr/bin/env python3
"""Health server for Behavioral RL container."""
import os
from flask import Flask, jsonify

app = Flask(__name__)
port = int(os.environ.get("SERVICE_PORT", 8082))

@app.route("/health")
def health():
    return jsonify({"status": "ok", "role": "cto-trading", "service": "behavioral-rl"})

@app.route("/")
def index():
    return jsonify({
        "service": "CTO Trading - Behavioral RL",
        "commands": [
            "docker exec mas-cto-trading-rl python train_rl.py",
            "docker exec mas-cto-trading-rl python evaluate.py --symbols BTC-USD"
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port)
HEALTHPY
RUN chmod +x /usr/local/bin/health-server.py

WORKDIR /app/behavioral-rl

VOLUME ["/data", "/config", "/models", "/workspace"]

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8082}/health || exit 1

CMD ["python3", "/usr/local/bin/health-server.py"]
