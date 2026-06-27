# =============================================================================
#  CTO TRADING ALICE - Open Alice Autonomous AI Trading Agent
#  Repositori: https://github.com/TraderAlice/OpenAlice
#  Fungsi: Full-stack AI trading agent for stocks, crypto, forex,
#          commodities, and macro analysis.
#          Handles research -> position entry -> risk mgmt -> monitoring
# =============================================================================

# ---------------------------------------------------------------------------
#  Stage 1: Builder - Clone & Build Open Alice
# ---------------------------------------------------------------------------
FROM node:22-trixie AS builder

LABEL org.opencontainers.image.source="https://github.com/TraderAlice/OpenAlice"
LABEL org.opencontainers.image.description="CTO Trading Alice - Open Alice Multi-Market Trading Agent"
LABEL agent.role="cto-trading"
LABEL agent.name="open-alice"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN npm install -g pnpm@latest

WORKDIR /app

# Clone Open Alice repository
RUN git clone --depth 1 https://github.com/TraderAlice/OpenAlice.git /app/openalice

WORKDIR /app/openalice

# Install dependencies and build
RUN pnpm install --frozen-lockfile
RUN pnpm build

# ---------------------------------------------------------------------------
#  Stage 2: Production - Runtime
# ---------------------------------------------------------------------------
FROM node:22-trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm for production
RUN npm install -g pnpm@latest

# Copy built artifacts from builder
COPY --from=builder /app/openalice /app/openalice

WORKDIR /app/openalice

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

# Set environment defaults
ENV NODE_ENV=production
ENV OPENALICE_HOME=/data
ENV HOME=/data/home
ENV OPENALICE_BIND_HOST=0.0.0.0
ENV OPENALICE_WEB_PORT=47331
ENV OPENALICE_MCP_PORT=47332
ENV OPENALICE_UTA_PORT=47333

# Health server untuk healthcheck Docker dan integrasi MAS (Node.js native, no Python needed)
COPY <<'HEALTHJS' /usr/local/bin/health-server.mjs
import http from 'node:http';
import { execSync } from 'node:child_process';

const PORT = parseInt(process.env.SERVICE_PORT || '47331', 10);
const WEB_PORT = parseInt(process.env.OPENALICE_WEB_PORT || '47331', 10);
const MCP_PORT = parseInt(process.env.OPENALICE_MCP_PORT || '47332', 10);
const UTA_PORT = parseInt(process.env.OPENALICE_UTA_PORT || '47333', 10);

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');

  if (req.url === '/health') {
    // Check if Open Alice node process is running
    let aliceRunning = false;
    try {
      const result = execSync('pgrep -af "node.*dist"', { timeout: 3000, encoding: 'utf8' });
      aliceRunning = result.split('\n').length > 2;
    } catch (e) { /* process not found */ }

    res.writeHead(200);
    res.end(JSON.stringify({
      status: aliceRunning ? 'ok' : 'degraded',
      role: 'cto-trading',
      service: 'open-alice',
      agent: 'Open Alice - Multi-Market Trading Agent',
      ports: { web: WEB_PORT, mcp: MCP_PORT, uta: UTA_PORT },
      markets: ['stocks', 'crypto', 'forex', 'commodities', 'macro'],
      alice_process: aliceRunning ? 'running' : 'checking'
    }));
  } else if (req.url === '/markets') {
    res.writeHead(200);
    res.end(JSON.stringify({
      stocks: { status: 'supported', brokers: ['Alpaca', 'IBKR (via Alpaca)'] },
      crypto: { status: 'supported', brokers: ['Binance (via CCXT)', 'Alpaca Crypto'] },
      forex: { status: 'supported', brokers: ['OANDA', 'Alpaca Forex'] },
      commodities: { status: 'supported', brokers: ['Alpaca'] },
      macro: { status: 'supported', data_sources: ['TraderHub', 'FRED', 'Yahoo Finance'] }
    }));
  } else {
    res.writeHead(200);
    res.end(JSON.stringify({
      service: 'CTO Trading Alice - Open Alice',
      status: 'running',
      description: 'Autonomous AI trading agent for multi-market analysis and execution',
      markets: ['stocks', 'crypto', 'forex', 'commodities', 'macro'],
      endpoints: ['GET /health - Health check', 'GET /markets - Markets info', 'GET / - This page']
    }));
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[health-server] listening on http://0.0.0.0:${PORT}`);
});
HEALTHJS

# Data volume for persistence (config, workspaces, auth tokens)
VOLUME ["/data"]

EXPOSE 47331 47332 47333

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-47331}/health || exit 1

# Start Open Alice via pnpm dev (orchestrator mode)
# Note: First boot generates admin token printed to stdout
# Login: docker logs mas-hybrid-alice | grep -A1 'admin token'
# Auth agent: docker exec -it mas-hybrid-alice claude
CMD ["sh", "-c", "node /usr/local/bin/health-server.mjs & pnpm start"]
