# =============================================================================
#  CISO SECURITY AGENT - ECC (Everything Claude Code)
#  Repositori: https://github.com/affaan-m/ECC
#  Fungsi: Agent Harness Operating System, manajemen skill & memori
#          agen AI secara terpusat, guardrails & policy enforcement
# =============================================================================
FROM node:20-slim AS builder

LABEL org.opencontainers.image.source="https://github.com/affaan-m/ECC"
LABEL org.opencontainers.image.description="CISO Security - Everything Claude Code Agent Harness"
LABEL agent.role="ciso"
LABEL agent.name="ecc"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/affaan-m/ECC.git /app/ecc

WORKDIR /app/ecc

RUN npm ci 2>/dev/null || npm install
RUN npm run build 2>/dev/null || true

# =============================================================================
#  Production stage
# =============================================================================
FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/ecc /app/ecc
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# Health server (Node.js built-in - tanpa dependensi eksternal)
COPY <<'HEALTHJS' /usr/local/bin/health-server.js
#!/usr/bin/env node
const http = require("http");
const port = parseInt(process.env.SERVICE_PORT || "8086");

const server = http.createServer((req, res) => {
    const data = req.url === "/health"
        ? { status: "ok", role: "ciso", service: "ecc" }
        : { service: "CISO Security - ECC", status: "running" };
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(data));
});

server.listen(port, () => {
    console.log(`ECC health server running on port ${port}`);
});
HEALTHJS
RUN chmod +x /usr/local/bin/health-server.js

WORKDIR /app/ecc

VOLUME ["/data", "/config", "/workspace"]

EXPOSE 8086

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8086}/health || exit 1

CMD ["node", "/usr/local/bin/health-server.js"]
