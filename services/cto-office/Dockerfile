# =============================================================================
#  CTO OFFICE AGENT - JARVIS Automation Platform
#  Repositori: https://github.com/affaan-m/JARVIS
#  Fungsi: Browser automation, OSINT, intelijen personal,
#          investigasi otomatis dengan multi-agent swarm
# =============================================================================
FROM python:3.11-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/JARVIS"
LABEL org.opencontainers.image.description="CTO Office - JARVIS Automation & OSINT Platform"
LABEL agent.role="cto-office"
LABEL agent.name="jarvis"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/JARVIS.git /app/jarvis

WORKDIR /app/jarvis

RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || \
    pip install --no-cache-dir \
    anthropic \
    fastapi \
    uvicorn \
    mediapipe \
    opencv-python-headless \
    numpy \
    pillow \
    requests \
    python-multipart \
    redis

# Install Playwright (browser automation) - lebih ringan & konsisten
RUN pip install --no-cache-dir playwright && \
    playwright install chromium 2>/dev/null || true

# =============================================================================
#  Production stage
# =============================================================================
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/jarvis /app/jarvis

# Copy Playwright browser binaries
COPY --from=builder /root/.cache/ms-playwright /root/.cache/ms-playwright 2>/dev/null || true

# Health server
RUN pip install --no-cache-dir flask
COPY <<'HEALTHPY' /usr/local/bin/health-server.py
#!/usr/bin/env python3
"""Health server for JARVIS container."""
import os
from flask import Flask, jsonify

app = Flask(__name__)
port = int(os.environ.get("SERVICE_PORT", 8081))

@app.route("/health")
def health():
    return jsonify({"status": "ok", "role": "cto-office", "service": "jarvis"})

@app.route("/")
def index():
    return jsonify({
        "service": "CTO Office - JARVIS",
        "status": "running",
        "commands": [
            "docker exec mas-cto-office python investigate.py",
            "curl http://localhost:8081/health"
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port)
HEALTHPY
RUN chmod +x /usr/local/bin/health-server.py

WORKDIR /app/jarvis

VOLUME ["/data", "/config", "/workspace"]

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8081}/health || exit 1

ENV PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright

CMD ["python3", "/usr/local/bin/health-server.py"]
