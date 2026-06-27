# 🤖 Multi-Agent System (MAS) Ecosystem

**Framework:** `claude-swarm` sebagai CEO Agent  
**Arsitek:** Affaan Mustafa  
**Hardware Target:** Intel Celeron N4000 (2 Core, 1.9GB RAM)

---

## 📋 Dokumentasi

| Dokumen | Deskripsi |
|---------|-----------|
| **README.md** | Dokumentasi utama ini |
| **ARCHITECTURE_ANALYSIS.md** | Analisis arsitektur untuk RAM 2GB, optimasi resource, mode operasi |
| **CI_CD_ANALYSIS.md** | Analisis CI/CD untuk trading dengan GitHub Actions |
| **DEPLOY.md** | Panduan step-by-step deploy VPS hybrid |

## 📋 Daftar Isi

- [Arsitektur](#-arsitektur)
- [Struktur Organisasi AI](#-struktur-organisasi-ai)
- [Mode Operasi](#-mode-operasi)
- [Hybrid Architecture](#-hybrid-architecture)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Secret Management](#-secret-management)
- [Prasyarat Sistem](#-prasyarat-sistem)
- [Quick Start](#-quick-start)
- [Cara Penggunaan](#-cara-penggunaan)
- [Cara Deploy ke VPS](#-cara-deploy-ke-vps)
- [Struktur File](#-struktur-file)
- [Troubleshooting](#-troubleshooting)

---

## 🏗 Arsitektur

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          FULL ARCHITECTURE (8+2 Container)               │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    CEO AGENT (Port 8080)                          │   │
│  │              claude-swarm - Multi-agent Orchestrator              │   │
│  │         Task Decomposition -> Parallel Execution -> Quality Gate  │   │
│  └──────────────┬──────────────┬──────────────┬─────────────────────┘   │
│                  │              │              │                          │
│     ┌────────────▼──┐  ┌───────▼────────┐  ┌─▼──────────────────┐       │
│     │ CTO Office    │  │ CTO Trading    │  │ CTO Commerce       │       │
│     │ JARVIS        │  │ Behavioral RL  │  │ Agent of Commerce  │       │
│     │ Port 8081     │  │ Port 8082      │  │ Port 8084          │       │
│     └────────────────┘  └───────┬────────┘  └────────────────────┘       │
│                                  │                                        │
│     ┌────────────────┐  ┌───────▼────────┐  ┌────────────────┐          │
│     │ HyperMamba     │  │ CISO Shield    │  │ CISO ECC       │          │
│     │ Port 8083      │  │ Port 8085      │  │ Port 8086      │          │
│     └────────────────┘  └────────────────┘  └────────────────┘          │
│                                                                          │
│     ┌────────────────┐  ┌────────────────┐                               │
│     │ Redis (Broker) │  │ Watchtower     │                               │
│     │ Port 6379      │  │ Auto-Update    │                               │
│     └────────────────┘  └────────────────┘                               │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 🧠 Struktur Organisasi AI

| Layer | Role | Agent | Repositori | Port | Fungsi Utama |
|-------|------|-------|------------|------|-------------|
| **CEO** | Orchestrator | Claude Swarm | [claude-swarm](https://github.com/affaan-m/claude-swarm) | 8080 | Task decomposition, parallel execution, quality gate |
| **CTO Office** | Automation | JARVIS | [JARVIS](https://github.com/affaan-m/JARVIS) | 8081 | Browser automation, OSINT, intelligence |
| **CTO Trading** | RL Trading | Behavioral RL | [Behavioral_RL](https://github.com/affaan-m/Behavioral_RL) | 8082 | RL trading with Prospect Theory & CVaR |
| **CTO Trading** | Time-Series | HyperMamba | [HyperMamba](https://github.com/affaan-m/HyperMamba) | 8083 | State Space Models for prediction |
| **CTO Trading** | Multi-Market | Open Alice | [OpenAlice](https://github.com/TraderAlice/OpenAlice) | 47331-3 | Stocks, crypto, forex, commodities, macro |
| **CTO Commerce** | E-commerce | Agent of Commerce | [agentofcommerce](https://github.com/affaan-m/agentofcommerce) | 8084 | Autonomous commerce + smart contracts |
| **CISO** | Security | AgentShield | [agentshield](https://github.com/affaan-m/agentshield) | 8085 | AI agent config security scanner |
| **CISO** | Governance | ECC | [ECC](https://github.com/affaan-m/ECC) | 8086 | Policy enforcement, skill & memory mgmt |
| **Infra** | Message Bus | Redis | redis:7-alpine | 6379 | Pub/sub antar agent |
| **Infra** | Updates | Watchtower | containrrr/watchtower | - | Auto-update containers |

---

## ⚙️ Mode Operasi

| Mode | Container | RAM Dibutuhkan | Cocok Untuk |
|------|-----------|---------------|-------------|
| **Full** | Semua 8 + Redis + Watchtower | **>= 8GB** | Server/VPS kelas atas |
| **Lightweight** | CEO + JARVIS + Trading RL + Redis | **>= 4GB** | Laptop mid-range |
| **Minimal** ⭐ | CEO + JARVIS + Redis | **>= 2GB** | **Intel Celeron (paling stabil)** |
| **Ultra-Minimal** | CEO + Redis | **>= 1.5GB** | Laptop sangat terbatas |
| **Hybrid** 🔥 | CEO+JARVIS lokal, sisanya di cloud | **~600MB lokal** | **Celeron + VPS $6/bulan** |

> 🏆 **Rekomendasi untuk Intel Celeron (1.9GB RAM):** Mode Hybrid

---

## 🔄 Hybrid Architecture

Arsitektur hybrid membagi beban antara laptop lokal dan cloud VPS untuk mengatasi keterbatasan RAM 2GB.

### Diagram Hybrid

```
┌─────────────────────────┐     ┌──────────────────────────────┐
│     LAPTOP CELERON       │     │      CLOUD VPS ($6/bln)      │
│     RAM: 1.9 GB          │     │      RAM: 4-8 GB             │
│                          │     │                              │
│  CEO (claude-swarm)      │     │  Trading RL (PyTorch)        │
│  CTO Office (JARVIS)     │◄───►│  HyperMamba (SSM)           │
│  Redis (Message Bus)     │SSH  │  Open Alice (Node.js)        │
│                          │Tunnel│  Commerce (Solana)           │
│                          │     │  CISO Shield + ECC          │
│  Total: ~600MB RAM       │     │                              │
└─────────────────────────┘     └──────────────────────────────┘
         │                              │
         └────────── Redis Pub/Sub ─────┘
```

### File Hybrid

| File | Deskripsi |
|------|-----------|
| `docker-compose.hybrid.yml` | Docker Compose untuk cloud VPS (9 services, ~390 baris) |
| `scripts/cloud-init.sh` | One-command VPS setup (Docker + swap + clone) |
| `scripts/remote-sync.sh` | Local-to-cloud sync tool (SSH tunnel, rsync, deploy) |
| `.env.hybrid.example` | Template konfigurasi hybrid |
| `config/nginx-hybrid.conf` | Health check aggregator |
| `DEPLOY.md` | Panduan deploy step-by-step |

### Biaya

```
Laptop (sudah punya):               $0
GitHub Actions (free tier):         $0  (2,000 min/bulan)
VPS Hetzner (4GB RAM):              ~$6/bulan
-----------------------------------------------
Total:                              ~$6/bulan
```

> 📖 **Baca selengkapnya:** [ARCHITECTURE_ANALYSIS.md](ARCHITECTURE_ANALYSIS.md)

---

## 🔄 CI/CD Pipeline

Gunakan GitHub Actions sebagai cloud compute gratis untuk menjalankan agent berat (Trading RL, HyperMamba, dll).

### Workflows

| Workflow | Trigger | Fungsi |
|----------|---------|--------|
| **trading.yml** | Schedule + manual | Market analysis, Open Alice multi-market, trade execution, backtest, ML training, security scan (7 jobs) |
| **ci.yml** | Push + PR | Validasi YAML, ShellCheck, compose lint, secret validation |

### GitHub Actions vs VPS

| Aspek | GitHub Actions (Free) | VPS ($6/bulan) |
|-------|----------------------|----------------|
| **RAM** | 8 GB | 4-8 GB |
| **CPU** | 4 core @2.5GHz+ | 2-4 vCPU |
| **Uptime** | 6h/job, 2000 min/bln | 24/7 |
| **Biaya** | $0 | ~$6/bln |
| **Cocok** | Backtest, laporan, training | Real-time trading, 24/7 agents |

> 📖 **Baca selengkapnya:** [CI_CD_ANALYSIS.md](CI_CD_ANALYSIS.md)

---

## 🔐 Secret Management

### Tingkat Keamanan

| Level | Metode | Keamanan | Use Case |
|-------|--------|----------|----------|
| 🟢 Dasar | `.env` file | Rendah | Development lokal |
| 🟡 Sedang | Docker secrets (`/run/secrets/`) | Sedang | Production kecil |
| 🟠 Tinggi | File terenkripsi (SOPS/dotenvx) | Tinggi | Team development |
| 🔴 Maksimal | HashiCorp Vault | Sangat Tinggi | Enterprise |

### Quick Setup

```bash
# 1. Isi API key di .env
nano .env

# 2. Generate file secrets (ekstrak dari .env ke ./secrets/)
./setup.sh --secrets

# 3. Jalankan dengan secrets aktif
docker compose up -d  # otomatis baca docker-compose.override.yml

# 4. Container membaca dari /run/secrets/<NAMA>
```

> 🔒 File secrets di-mount sebagai file, bukan env vars. Tidak muncul di `docker inspect`.

---

## ✅ Prasyarat Sistem

| Komponen | Minimal | Rekomendasi |
|----------|---------|-------------|
| **CPU** | 2 Core | 4+ Core |
| **RAM** | 2GB (mode minimal) | 8GB (mode full) |
| **Disk** | 10GB free | 20GB+ free |
| **Docker** | v20.10+ | v24.0+ |
| **Docker Compose** | v2.0+ | v2.20+ |
| **Git** | v2.0+ | v2.30+ |
| **OS** | Linux/WSL2/macOS | Linux (Ubuntu 22.04+) |

---

## 🚀 Quick Start

### Mode Minimal (Stabil untuk Celeron 2GB)

```bash
# 1. Masuk ke direktori
cd multi-agent-system

# 2. Setup otomatis
chmod +x setup.sh
./setup.sh --minimal

# 3. Edit API Key
nano .env   # isi ANTHROPIC_API_KEY

# 4. Aktifkan secret management
./setup.sh --secrets

# 5. Verifikasi
./setup.sh --status
```

### Mode Hybrid (Rekomendasi Terbaik)

```bash
# LOKAL: Jalankan minimal mode
./setup.sh --minimal

# LOKAL: Setup SSH key ke VPS
./scripts/remote-sync.sh --setup

# VPS: Setup otomatis (copy-paste command ini di VPS)
cat scripts/cloud-init.sh | ssh root@VPS_IP 'bash -s'

# LOKAL: Deploy container ke VPS
./scripts/remote-sync.sh --deploy

# LOKAL: Cek koneksi
./scripts/remote-sync.sh --status
```

> 📖 **Baca selengkapnya:** [DEPLOY.md](DEPLOY.md)

---

## 💻 Cara Penggunaan

### Via CLI ke CEO

```bash
docker exec mas-ceo claude-swarm "Analisis portofolio kripto"
docker exec mas-ceo claude-swarm --dry-run "Apa yang perlu ditingkatkan?"
```

### Via GitHub Actions

```bash
# Trigger workflow dari lokal
gh workflow run trading.yml -f action=analyze -f symbol=BTC-USD

# Lihat hasil
gh run list
gh run view
```

### Via API Endpoints

```bash
curl http://localhost:8080/health    # CEO
curl http://localhost:8081/health    # CTO Office
curl http://VPS_IP:9090/status      # Hybrid health aggregator
```

### Redis Pub/Sub (Komunikasi antar-agent)

```bash
# Subscribe
docker exec mas-redis redis-cli SUBSCRIBE "agent:ceo:commands"

# Publish task ke cloud agent
docker exec mas-redis redis-cli PUBLISH "agent:trading:commands" \
  '{"task": "analyze", "symbol": "BTC-USD"}'
```

---

## 🚀 Cara Deploy ke VPS

**Lihat panduan lengkap:** [DEPLOY.md](DEPLOY.md)

```bash
# TL;DR — 3 langkah cepat:
# 1. Setup VPS
ssh root@VPS_IP 'bash -s' < scripts/cloud-init.sh

# 2. Kirim project (rsync lebih cepat dari scp — skip .git, workspace, data)
rsync -avz --exclude '.git' --exclude 'workspace' --exclude 'data' \
  . root@VPS_IP:/root/multi-agent-system/

# 3. Deploy containers
ssh root@VPS_IP "cd /root/multi-agent-system && \
  docker compose -f docker-compose.hybrid.yml up -d"
```

---

## 📁 Struktur File Lengkap

```
multi-agent-system/
├── README.md                       # Dokumentasi utama
├── ARCHITECTURE_ANALYSIS.md        # Analisis arsitektur RAM 2GB
├── CI_CD_ANALYSIS.md               # Analisis CI/CD trading
├── DEPLOY.md                       # Panduan deploy VPS
│
├── docker-compose.yml              # Full mode (7 container + 2 infra)
├── docker-compose.lightweight.yml  # Lightweight (CEO + JARVIS + RL + Redis)
├── docker-compose.minimal.yml      # Minimal (CEO + JARVIS + Redis) ⭐
├── docker-compose.hybrid.yml       # Hybrid cloud (5 agent berat)
├── docker-compose.override.yml     # Secret management (Docker secrets)
│
├── setup.sh                        # Setup otomatis lokal
├── .env.example                    # Template API Key
├── .env.hybrid.example             # Template konfigurasi hybrid
│
├── config/
│   ├── swarm.yaml                  # Konfigurasi agent utk claude-swarm
│   ├── ecc-policy.yaml             # Policy keamanan ECC
│   └── nginx-hybrid.conf           # Nginx health check aggregator
│
├── services/
│   ├── ceo/Dockerfile              # Claude Swarm CEO Orchestrator
│   ├── cto-office/Dockerfile       # JARVIS Automation
│   ├── cto-trading-rl/Dockerfile   # Behavioral RL (PyTorch)
│   ├── cto-trading-hyper/Dockerfile # HyperMamba (Mamba SSM)
│   ├── cto-trading-alice/Dockerfile# Open Alice (Multi-Market Trading)
│   ├── cto-commerce/Dockerfile     # Agent of Commerce (Solana)
│   ├── ciso-shield/Dockerfile      # AgentShield Security
│   └── ciso-ecc/Dockerfile         # ECC Agent Harness
│
├── scripts/
│   ├── remote-sync.sh              # Sync tool lokal <-> cloud
│   └── cloud-init.sh               # One-command VPS setup
│
├── .github/workflows/
│   ├── trading.yml                 # Trading pipeline (7 jobs: +Open Alice)
│   └── ci.yml                      # CI validation pipeline (7 jobs)
│
├── secrets/                        # API key files (gitignored)
├── workspace/                      # Shared workspace (bind mount)
├── data/                           # Data persisten
└── logs/                           # Log files
```

**Total: ~24 file, ~4,100 baris konfigurasi & dokumentasi**

---

## 🔧 Troubleshooting

### Container OOM (Exit code 137)

```bash
# Kurangi jumlah container atau turunkan memory limit
./setup.sh --minimal

# Atau tambah swap (Linux)
sudo fallocate -l 4G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```

### Build Lambat di Celeron

```bash
# Build satu per satu (serial)
docker compose build ceo
docker compose build cto-office
```

### GitHub Actions Workflow Gagal

```bash
# Cek log
gh run view --log

# Trigger ulang
gh run rerun

# Cek usage
gh api /users/yourusername/settings/billing/actions
```

### Redis Connection Refused (Hybrid)

```bash
# Pastikan Redis lokal jalan
docker exec mas-redis redis-cli ping

# Cek SSH tunnel
./scripts/remote-sync.sh --status

# Restart tunnel
./scripts/remote-sync.sh --stop
./scripts/remote-sync.sh --tunnel
```

---

## 📜 Lisensi

MIT — [Affaan Mustafa](https://x.com/affaanmustafa)

## 🙏 Acknowledgments

- [Claude Agent SDK](https://github.com/anthropics/claude-agent-sdk-python)
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code)
- [Browser Use](https://github.com/browser-use/browser-use)
- [Cerebral Valley x Anthropic Hackathon](https://cerebralvalley.ai/hackathons/claude-code-hackathon-aaHFuycPfjQa5dNaxZpU)
