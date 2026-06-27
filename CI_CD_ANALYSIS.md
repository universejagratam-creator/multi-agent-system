# 🔄 CI/CD Analysis for Trading - GitHub Actions Pipeline

**Framework:** Multi-Agent System (MAS) with claude-swarm  
**Hardware Target:** Laptop Intel Celeron (2GB RAM) + GitHub Actions Cloud  
**Date:** June 2026

---

## 📋 Table of Contents

- [Why CI/CD for Trading?](#why-cicd-for-trading)
- [Architecture Overview](#architecture-overview)
- [GitHub Actions Workflow Design](#github-actions-workflow-design)
- [Security: GitHub Secrets](#security-github-secrets)
- [Scheduling Strategies](#scheduling-strategies)
- [Cost Analysis](#cost-analysis)
- [Limitations & Risks](#limitations--risks)
- [Hybrid: GitHub Actions + VPS](#hybrid-github-actions--vps)
- [Implementation Guide](#implementation-guide)

---

## Why CI/CD for Trading?

### Problem
Laptop Celeron with 2GB RAM **cannot run** PyTorch RL agents or HyperMamba models locally. These agents require:
- 4-8GB RAM for inference
- 8-16GB RAM for training
- 30+ minutes build time per Docker image
- Continuous uptime for market monitoring

### Solution: GitHub Actions as Free Cloud Compute

| Capability | Local (Celeron) | GitHub Actions |
|------------|----------------|----------------|
| **RAM** | 1.9 GB | 8 GB (free) |
| **CPU** | 2 core @1.1GHz | 4 core @2.5GHz+ |
| **GPU** | None | Optional (paid) |
| **Uptime** | Limited | 6h/job (free), unlimited (self-hosted) |
| **Cost** | Already owned | $0 (2000 min/month) |
| **Scheduling** | Manual | Cron + workflow_dispatch |

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                         HYBRID TRADING SYSTEM                         │
│                                                                      │
│  LOCAL (Celeron 2GB RAM)           CLOUD (GitHub Actions / VPS)      │
│  ┌──────────────────────┐         ┌─────────────────────────────┐   │
│  │  CEO (claude-swarm)  │         │  GitHub Actions Runner      │   │
│  │  Orchestrator        │◄──SSH──►│  ┌───────────────────────┐ │   │
│  │  Task Decomposition  │  or     │  │ Trading RL Agent      │ │   │
│  │  Quality Gate        │  Redis  │  │ PyTorch Training      │ │   │
│  └──────────┬───────────┘  Pub/Sub│  └───────────────────────┘ │   │
│             │                     │  ┌───────────────────────┐ │   │
│  ┌──────────▼───────────┐         │  │ HyperMamba Agent      │ │   │
│  │  CTO Office (JARVIS) │         │  │ Time-Series Predict   │ │   │
│  │  Browser Automation  │         │  └───────────────────────┘ │   │
│  │  OSINT / Research    │         │  ┌───────────────────────┐ │   │
│  └──────────────────────┘         │  │ Report Generator      │ │   │
│                                   │  │ PDF / HTML Output     │ │   │
│  ┌──────────────────────┐         │  └───────────────────────┘ │   │
│  │  Redis (Message Bus) │         └─────────────────────────────┘   │
│  │  Queue & State       │                                           │
│  └──────────────────────┘                                           │
└──────────────────────────────────────────────────────────────────────┘
```

### Communication Flow

1. **CEO (local)** publishes trading task to Redis channel
2. **GitHub Actions trigger** detects Redis event OR scheduled cron
3. **Cloud runner** pulls task, executes trading agent
4. **Results** pushed back to Redis or saved as GitHub Artifact
5. **CEO (local)** reads results, generates report

---

## GitHub Actions Workflow Design

### Workflow 1: Scheduled Trading (Daily)

```yaml
name: Daily Trading Strategy

on:
  schedule:
    # Run at market open: 09:30 UTC (US market)
    - cron: '30 13 * * 1-5'
    # Run at market close: 16:00 UTC
    - cron: '0 20 * * 1-5'
    # Run analysis every 4 hours during active hours
    - cron: '0 */4 * * 1-5'
  workflow_dispatch:
    inputs:
      strategy:
        description: 'Trading strategy to execute'
        required: true
        default: 'conservative'
        type: choice
        options:
          - conservative
          - aggressive
          - arbitrage
      symbol:
        description: 'Trading pair'
        required: true
        default: 'BTC-USD'
      mode:
        description: 'Execution mode'
        required: true
        default: 'paper'
        type: choice
        options:
          - paper
          - dry-run
          - live
```

### Workflow 2: ML Model Training (On-Demand)

```yaml
name: Training Pipeline

on:
  workflow_dispatch:
    inputs:
      model:
        description: 'Model to train'
        required: true
        default: 'behavioral-rl'
        type: choice
        options:
          - behavioral-rl
          - hypermamba
          - ensemble
      epochs:
        description: 'Training epochs'
        required: true
        default: '100'
      data_start:
        description: 'Start date (YYYY-MM-DD)'
        required: false
        default: '2024-01-01'

jobs:
  train:
    runs-on: ubuntu-latest
    container:
      image: mas/cto-trading-rl:latest
    steps:
      - uses: actions/checkout@v4
      - name: Train Model
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          WANDB_API_KEY: ${{ secrets.WANDB_API_KEY }}
          MARKET_DATA_KEY: ${{ secrets.MARKET_DATA_API_KEY }}
        run: |
          python train.py \
            --model ${{ inputs.model }} \
            --epochs ${{ inputs.epochs }} \
            --data-start ${{ inputs.data_start }}
      - name: Upload Model Artifact
        uses: actions/upload-artifact@v4
        with:
          name: trained-model-${{ inputs.model }}
          path: models/
          retention-days: 30
```

### Workflow 3: Backtesting Suite

```yaml
name: Backtesting Suite

on:
  schedule:
    # Run backtest every Sunday
    - cron: '0 0 * * 0'
  workflow_dispatch:

jobs:
  backtest:
    runs-on: ubuntu-latest
    container:
      image: mas/cto-trading-rl:latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Backtest
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          python backtest.py \
            --start-date 2024-01-01 \
            --end-date $(date +%Y-%m-%d) \
            --strategies conservative,aggressive,arbitrage \
            --symbols BTC-USD,ETH-USD,SPY
      - name: Generate Report
        run: python generate_report.py
      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: backtest-report
          path: reports/
```

### Workflow 4: CEO Swarm Task (Manual)

```yaml
name: CEO Agent Swarm Task

on:
  workflow_dispatch:
    inputs:
      task:
        description: 'Task description for CEO agent'
        required: true
        default: 'Analyze current market conditions and provide trading recommendations'

jobs:
  swarm:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Claude Swarm
        run: |
          pip install claude-swarm

      - name: Run Swarm
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude-swarm "${{ inputs.task }}" \
            --max-agents 3 \
            --budget 2.0 \
            --no-ui

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: swarm-results
          path: .claude-swarm/sessions/
```

---

## Security: GitHub Secrets

### Required Secrets

| Secret Name | Source | Required For |
|-------------|--------|-------------|
| `ANTHROPIC_API_KEY` | console.anthropic.com | All agents |
| `WANDB_API_KEY` | wandb.ai | ML experiment tracking |
| `MARKET_DATA_API_KEY` | Provider | Price data |
| `DOCKER_PASSWORD` | Docker Hub | Private registry |
| `DOCKER_USERNAME` | Docker Hub | Private registry |
| `SSH_PRIVATE_KEY` | VPS provider | Hybrid mode |
| `SSH_HOST` | VPS IP address | Hybrid mode |

### How to Set Up

```bash
# Navigate to your GitHub repo → Settings → Secrets and variables → Actions
# Click "New repository secret" for each key

# Or use GitHub CLI:
gh secret set ANTHROPIC_API_KEY < sk-ant-xxx...
gh secret set MARKET_DATA_API_KEY < your-key...
```

### Security Best Practices

1. **Never log API keys** — GitHub Actions redacts secrets from logs automatically
2. **Use environment-specific secrets** — Different keys for dev/staging/prod
3. **Rotate quarterly** — Refresh API keys every 90 days
4. **Audit with CISO Shield** — Run agentshield scan on workflow artifacts
5. **Minimal scope** — Each workflow only accesses secrets it needs

---

## Scheduling Strategies

### For Different Trading Styles

| Trading Style | Cron Schedule | Rationale |
|--------------|---------------|-----------|
| **Swing Trading** | `0 0 * * *` | Daily analysis at midnight UTC |
| **Day Trading** | `30 13 * * 1-5` | 30 min before US market open |
| **Crypto (24/7)** | `0 */4 * * *` | Every 4 hours |
| **Portfolio Rebalance** | `0 0 * * 0` | Weekly on Sunday |
| **Model Retraining** | `0 0 1 * *` | Monthly on 1st |

### Avoiding Rate Limits

GitHub Actions has rate limits:
- **2000 minutes/month** (free)
- **Max job duration:** 6 hours
- **Max concurrent jobs:** 20 (free), 180 (paid)

```yaml
# Calculate your monthly usage:
# Daily swing trade: 1 run/day × 5 min = 150 min/month
# Hourly crypto: 6 runs/day × 10 min = 1800 min/month ❌ EXCEEDED
# Solution: Use self-hosted runner for high-frequency tasks
```

---

## Cost Analysis

### GitHub Actions Free Tier

| Item | Cost | Limit |
|------|------|-------|
| **Compute minutes** | $0 | 2,000 min/month |
| **Storage (artifacts)** | $0 | 500 MB |
| **Concurrent jobs** | $0 | 20 |

**Monthly usage projection:**
```
Daily backtest (1h):         30 runs × 60 min = 1,800 min ❌ EXCEEDED
Swing trade (10 min):        30 runs × 10 min = 300 min ✅
Weekly backtest (30 min):     4 runs × 30 min = 120 min ✅
Manual triggers (15 min):    10 runs × 15 min = 150 min ✅
────────────────────────────────────────────────────────
Total:                                        570 min ✅ (28.5% of quota)
```

### Self-Hosted Runner (VPS)

| Provider | RAM | CPU | Cost/Month | Notes |
|----------|-----|-----|------------|-------|
| **Hetzner** | 4 GB | 2 vCPU | ~$6 | Best price/performance |
| **DigitalOcean** | 4 GB | 2 vCPU | ~$24 | Easy setup |
| **Linode** | 4 GB | 2 vCPU | ~$24 | Stable |
| **Oracle Cloud** | 24 GB | 4 vCPU | **$0** | Free tier (hard to get) |

### Cost Comparison

```
Scenarios                              Cost/Month
───────────────────────────────────────────────────────
Free tier only (2,000 min)              $0
Free + Hetzner self-hosted              $6
Full VPS (DigitalOcean 4GB)            $24
Full VPS (Hetzner) + GitHub runners    $6
Enterprise (AWS Lightsail 8GB)         $80+
```

---

## Limitations & Risks

### GitHub Actions Limitations

| Limitation | Impact | Mitigation |
|-----------|--------|------------|
| **6h max runtime** | Can't run 24/7 agents | Use VPS for continuous tasks |
| **No static IP** | Can't whitelist IP | Use API-based exchanges |
| **Startup delay** | 30-60s cold start | Schedule ahead |
| **Network restrictions** | Can't mine crypto | No ⛏️ anyway |
| **No GPU** | Can't train large models | Use Colab or VPS with GPU |
| **No persistent storage** | Artifacts deleted after 90 days | Download reports |

### Open Alice Integration

Open Alice ([TraderAlice/OpenAlice](https://github.com/TraderAlice/OpenAlice)) is an autonomous AI trading agent for multi-market analysis:
- **Assets:** Stocks, crypto, forex, commodities, macro
- **Stack:** Node.js 22+, pnpm 10+, monorepo
- **Ports:** 47331 (Web UI), 47332 (MCP), 47333 (UTA)
- **GitHub Actions:** `pnpm install` takes ~3-5 min; cache with `actions/setup-node`
- **Secrets required:** `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`
- **Trigger:** `gh workflow run trading.yml -f action=alice`

### Trading-Specific Risks

1. **Latency:** 30-60s startup delay → NOT suitable for HFT
2. **Downtime:** GitHub outages → have fallback strategy
3. **Cost overrun:** 2000 min/month limit → monitor usage
4. **Market gaps:** If job is delayed during volatility
5. **API rate limits:** Multiple runs in parallel could hit exchange limits

---

## Hybrid: GitHub Actions + VPS

Best of both worlds:

```
┌──────────────────────────────────────────────────────────┐
│                    BEST ARCHITECTURE                      │
│                                                          │
│  FREE (GitHub Actions)       $6/MONTH (Hetzner VPS)      │
│  ┌────────────────────┐     ┌───────────────────────┐   │
│  │ Backtesting        │     │ Self-Hosted Runner     │   │
│  │ Report Generation  │     │ Docker Compose Cloud   │   │
│  │ Once-daily tasks   │     │ 24/7 Trading Agents    │   │
│  │ Budget: 500 min    │     │ Unlimited compute      │   │
│  └────────────────────┘     └───────────────────────┘   │
│                                                          │
│  LAPTOP (Local)                                           │
│  ┌────────────────────┐                                   │
│  │ CEO Orchestrator   │  ←  orchestrates everything       │
│  │ JARVIS Automation  │                                   │
│  │ Redis Message Bus  │                                   │
│  └────────────────────┘                                   │
└──────────────────────────────────────────────────────────┘
```

### How They Connect

```yaml
# Local → GitHub Actions: Webhook trigger
# Local → VPS: Redis replication + SSH tunnel
# VPS → GitHub Actions: Self-hosted runner registration
```

---

## Implementation Guide

### Step 1: Set Up GitHub Secrets

```bash
# Install GitHub CLI
brew install gh  # macOS
sudo apt install gh  # Linux

# Login
gh auth login

# Set secrets
gh secret set ANTHROPIC_API_KEY
gh secret set MARKET_DATA_API_KEY
gh secret set WANDB_API_KEY
```

### Step 2: Create Workflow Files

```bash
mkdir -p .github/workflows

# Create the workflow files from templates above
# Or use: gh workflow create
```

### Step 3: Set Up VPS (Optional for Hybrid)

```bash
# On your VPS (Hetzner/DigitalOcean):
ssh root@your-vps-ip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Register as self-hosted runner
# Go to: GitHub repo → Settings → Actions → Runners → New self-hosted runner
# Follow the instructions
```

### Step 4: Connect Local to Cloud

```bash
# Run remote-sync.sh to connect local Redis to cloud
./scripts/remote-sync.sh --setup

# This sets up:
# 1. SSH tunnel to VPS
# 2. Redis replication
# 3. GitHub Actions webhook
```

### Step 5: Monitor & Optimize

```bash
# Check GitHub Actions usage
gh api /users/yourusername/settings/billing/actions

# View workflow runs
gh run list

# Cancel stuck runs
gh run cancel <run-id>
```

---

## Summary

| Strategy | Cost | Reliability | Performance | Best For |
|----------|------|-------------|-------------|----------|
| **Pure GitHub Actions** | $0 | Medium | Good | Occasional backtests, reports |
| **VPS + Self-Hosted** | $6-24/mo | High | Best | 24/7 trading agents |
| **Hybrid (Both)** | $6-24/mo | Very High | Best | Everything |

> **Recommendation for Intel Celeron (2GB RAM):**
> 1. **Free tier** for backtesting and reports → $0
> 2. **Hetzner VPS ($6/mo)** for 24/7 trading agents
> 3. **Local laptop** for CEO orchestrator + JARVIS automation
> 4. **Total cost:** ~$6/month for full enterprise-grade trading system

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [Docker Hub Container Registry](https://hub.docker.com/)
