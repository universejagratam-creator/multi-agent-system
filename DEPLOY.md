# 🚀 DEPLOY.md - Panduan Deploy VPS Hybrid Architecture

**Deploy agent berat (Trading RL, HyperMamba, Commerce, CISO) ke cloud VPS**  
**Laptop lokal tetap menjalankan CEO + JARVIS + Redis**

---

## 📋 Daftar Isi

- [Pilih VPS Provider](#1-pilih-vps-provider)
- [Setup VPS](#2-setup-vps)
- [Clone Project ke VPS](#3-clone-project-ke-vps)
- [Konfigurasi Environment](#4-konfigurasi-environment)
- [Deploy Container](#5-deploy-container)
- [Setup Redis Replication (Opsional)](#6-setup-redis-replication-opsional)
- [Koneksi dari Lokal ke Cloud](#7-koneksi-dari-lokal-ke-cloud)
- [Monitoring](#8-monitoring)
- [Troubleshooting](#9-troubleshooting)

---

## 1. Pilih VPS Provider

| Provider | RAM/CPU | Harga/Bulan | Setup | GPU |
|----------|---------|-------------|-------|-----|
| **Hetzner** ⭐ | 4GB/2vCPU | ~$6 | SSH key | ❌ |
| **Hetzner** | 8GB/4vCPU | ~$12 | SSH key | ❌ |
| **DigitalOcean** | 4GB/2vCPU | ~$24 | Password/SSH | ❌ |
| **Linode** | 4GB/2vCPU | ~$24 | SSH key | ❌ |
| **Oracle Cloud** 🆓 | 24GB/4vCPU | **$0** | Kredit card | ❌ |
| **AWS Lightsail** | 4GB/2vCPU | ~$20 | AWS account | ❌ |
| **Vultr** | 4GB/2vCPU | ~$24 | SSH key | ❌ |
| **MassiveGRID** | 4GB/2vCPU+GPU | ~$12 | Crypto payment | ✅ GPU |

> **Rekomendasi:** Hetzner CX22 ($6/bulan) atau Oracle Cloud Free Tier ($0/bulan)

---

## 2. Setup VPS

### 2.1 SSH Key Setup (Lokal)

```bash
# Generate SSH key (jika belum punya)
ssh-keygen -t ed25519 -f ~/.ssh/mas-vps -N ""

# Copy public key ke VPS
ssh-copy-id -i ~/.ssh/mas-vps.pub root@VPS_IP_ADDRESS

# Test koneksi
ssh -i ~/.ssh/mas-vps root@VPS_IP_ADDRESS "echo OK"
```

### 2.2 Auto-Setup dengan cloud-init.sh

```bash
# Method 1: SSH + pipe
cat scripts/cloud-init.sh | ssh root@VPS_IP_ADDRESS 'bash -s'

# Method 2: Copy dulu, lalu jalankan
scp scripts/cloud-init.sh root@VPS_IP_ADDRESS:/tmp/
ssh root@VPS_IP_ADDRESS "bash /tmp/cloud-init.sh"

# Method 3: Remote sync tool
./scripts/remote-sync.sh --deploy
```

### 2.3 Manual Setup (Jika Auto-Setup Gagal)

```bash
# SSH ke VPS
ssh root@VPS_IP_ADDRESS

# Update system
apt-get update -qq && apt-get upgrade -y -qq

# Install Docker
curl -fsSL https://get.docker.com | sh

# Verify
docker --version
docker compose version

# Add swap (jika RAM < 4GB)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

---

## 3. Setup Open Alice (Multi-Market Agent)

Open Alice adalah AI trading agent yang bisa handle saham, crypto, forex, komoditas, dan makro.

### 3.1 Setup di VPS

Open Alice sudah terintegrasi di `docker-compose.hybrid.yml`. Saat deploy, container akan:
1. Clone dari [github.com/TraderAlice/OpenAlice](https://github.com/TraderAlice/OpenAlice)
2. Build dengan multi-stage Docker build (2 stage)
3. Jalankan pada port 47331 (Web UI), 47332 (MCP), 47333 (UTA)

```bash
# Setelah deploy (lihat bagian 3):
docker compose -f docker-compose.hybrid.yml up -d cto-trading-alice

# Dapatkan admin token untuk login pertama
sleep 10
docker logs mas-hybrid-alice 2>&1 | grep -A1 'admin token'
# Buka browser: http://VPS_IP:47331
# Masukkan admin token

# Auth agent CLI di dalam container
docker exec -it mas-hybrid-alice claude
# Ikuti instruksi login
```

### 3.2 Markets Supported

| Market | Status | Broker |
|--------|--------|--------|
| Stocks | ✅ | Alpaca, IBKR |
| Crypto | ✅ | Binance (CCXT), Alpaca Crypto |
| Forex | ✅ | OANDA, Alpaca Forex |
| Commodities | ✅ | Alpaca |
| Macro | ✅ | TraderHub, FRED, Yahoo Finance |

## 4. Clone Project ke VPS

```bash
# Gunakan rsync (lebih cepat dari scp — skip .git, workspace, data)
rsync -avz --exclude '.git' --exclude 'workspace' --exclude 'data' \
  multi-agent-system/ root@VPS_IP_ADDRESS:/root/multi-agent-system/

# Atau clone langsung dari VPS (lebih cepat untuk pertama kali)
ssh root@VPS_IP_ADDRESS
git clone --depth 1 https://github.com/affaan-m/claude-swarm.git /root/multi-agent-system
```

---

## 5. Konfigurasi Environment

```bash
# Copy template .env
cp .env.hybrid.example .env

# Edit .env dengan API key
nano .env
```

**.env minimal yang harus diisi:**
```bash
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WANDB_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MARKET_DATA_API_KEY=xxxxxxxxxxxxxxxx
SOLANA_PRIVATE_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Konfigurasi Redis replication (jika ingin sync dengan lokal)
REDIS_MASTER_HOST=xxx.xxx.xxx.xxx   # IP laptop lokal
REDIS_MASTER_PORT=6379
```

---

## 6. Deploy Container

### 6.1 Build & Start (Pertama Kali)

```bash
# Di VPS, di direktori project
cd /root/multi-agent-system

# Build image (membutuhkan 10-30 menit)
docker compose -f docker-compose.hybrid.yml build

# Start container
docker compose -f docker-compose.hybrid.yml up -d

# Cek status
docker compose -f docker-compose.hybrid.yml ps
```

### 6.2 Verifikasi Container Berjalan

```bash
# Cek health semua agent
curl http://localhost:9090/status

# Atau cek individual
curl http://localhost:47331/health  # Open Alice (Web UI)
curl http://localhost:47332/mcp     # Open Alice (MCP endpoint)
curl http://localhost:8082/health   # Trading RL
curl http://localhost:8083/health   # HyperMamba
curl http://localhost:8084/health   # Commerce
curl http://localhost:8085/health   # CISO Shield
curl http://localhost:8086/health   # CISO ECC
```

### 6.3 Restart Container

```bash
docker compose -f docker-compose.hybrid.yml restart
```

### 6.4 Update Container

```bash
# Pull latest source
git pull

# Rebuild & restart
docker compose -f docker-compose.hybrid.yml build
docker compose -f docker-compose.hybrid.yml up -d
```

---

## 7. Setup Redis Replication (Opsional)

Redis replication menghubungkan Redis di cloud dengan Redis di laptop lokal.

### 7.1 Di Laptop Lokal

```bash
# Pastikan Redis lokal berjalan
docker exec mas-redis redis-cli ping
# Harus: PONG

# Cek IP lokal
ip addr show | grep inet
# Catat IP lokal (misal: 192.168.1.10)
```

### 7.2 Di VPS

```bash
# Edit .env
nano .env

# Set REDIS_MASTER_HOST ke IP lokal
REDIS_MASTER_HOST=192.168.1.10
REDIS_MASTER_PORT=6379

# Restart Redis replica
docker compose -f docker-compose.hybrid.yml up -d redis-replica

# Verifikasi
docker exec mas-hybrid-redis redis-cli info replication
# Harus: role:slave
```

### 7.3 SSH Tunnel (Jika VPS Tidak Bisa Akses Langsung ke Lokal)

```bash
# Di laptop lokal
./scripts/remote-sync.sh --tunnel
```

---

## 8. Koneksi dari Lokal ke Cloud

### 8.1 Via Remote Sync Tool

```bash
# Setup koneksi
export SSH_HOST=VPS_IP_ADDRESS
export SSH_USER=root

# Cek status
./scripts/remote-sync.sh --status

# Deploy penuh (sync files + build + start)
./scripts/remote-sync.sh --deploy

# Sync workspace files saja
./scripts/remote-sync.sh --sync
```

### 8.2 Via SSH Langsung

```bash
# Jalankan task trading di cloud dari lokal
ssh root@VPS_IP_ADDRESS "docker exec mas-hybrid-trading-rl python train.py"

# Buat alias untuk kemudahan
alias cloud-trade='ssh root@VPS_IP_ADDRESS "docker exec mas-hybrid-trading-rl python trade.py --symbol BTC-USD --mode paper"'
```

### 8.3 Via GitHub Actions

Lihat [.github/workflows/trading.yml](.github/workflows/trading.yml) untuk workflow otomatis.

```bash
# Trigger dari lokal
gh workflow run trading.yml -f action=analyze -f symbol=BTC-USD
```

---

## 9. Monitoring

### 9.1 Cek Status Semua Container

```bash
# Di VPS
docker compose -f docker-compose.hybrid.yml ps

# Resource usage
docker stats --no-stream

# Log agent
docker compose -f docker-compose.hybrid.yml logs -f cto-trading-alice
docker compose -f docker-compose.hybrid.yml logs -f cto-trading-rl
docker compose -f docker-compose.hybrid.yml logs -f cto-trading-hyper
```

### 9.2 Cek Koneksi Hybrid

```bash
# Dari laptop lokal
./scripts/remote-sync.sh --status

# Output:
# Local Redis: ✅ RUNNING (port 6379)
# SSH Tunnel: ✅ ACTIVE
# VPS Connection: ✅ REACHABLE
# Cloud Containers:
#   mas-hybrid-trading-rl     Up 2 hours
#   mas-hybrid-trading-hyper  Up 2 hours
#   mas-hybrid-commerce       Up 2 hours
```

### 9.3 Health Check Aggregator

```bash
# Endpoint tunggal untuk cek semua agent
curl http://VPS_IP_ADDRESS:9090/status
# {"service":"hybrid-mas","containers":["alice","trading-rl","hypermamba","commerce","shield","ecc"]}

# Cek health individual
curl http://VPS_IP_ADDRESS:9090/health/alice
curl http://VPS_IP_ADDRESS:9090/health/rl
curl http://VPS_IP_ADDRESS:9090/health/hyper
curl http://VPS_IP_ADDRESS:9090/health/commerce
```

---

## 10. Troubleshooting

### Container Tidak Start

```bash
# Cek log
docker compose -f docker-compose.hybrid.yml logs cto-trading-rl

# Restart
docker compose -f docker-compose.hybrid.yml restart cto-trading-rl

# Rebuild jika perlu
docker compose -f docker-compose.hybrid.yml build cto-trading-rl
```

### OOM (Out of Memory)

```bash
# Gejala: Container exit code 137
# Solusi: Limit memory lebih rendah
nano docker-compose.hybrid.yml
# Ubah: mem_limit: 1g → mem_limit: 512m

# Atau tambah swap
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### Redis Replication Gagal

```bash
# Cek koneksi
docker exec mas-hybrid-redis redis-cli ping

# Cek log
docker compose -f docker-compose.hybrid.yml logs redis-replica

# Pastikan REDIS_MASTER_HOST bisa diakses dari VPS
telnet REDIS_MASTER_HOST REDIS_MASTER_PORT
# Jika tidak, gunakan SSH tunnel: ./scripts/remote-sync.sh --tunnel
```

### Docker Daemon Crash

```bash
# Restart Docker
systemctl restart docker

# Mulai ulang container
docker compose -f docker-compose.hybrid.yml up -d
```

### Update Image

```bash
# Pull perubahan terbaru
cd /root/multi-agent-system
git pull

# Rebuild ulang
docker compose -f docker-compose.hybrid.yml build

# Restart
docker compose -f docker-compose.hybrid.yml up -d
```

---

> **📚 Baca juga:** [ARCHITECTURE_ANALYSIS.md](ARCHITECTURE_ANALYSIS.md) untuk analisis resource  
> **🔐 Baca juga:** [CI_CD_ANALYSIS.md](CI_CD_ANALYSIS.md) untuk GitHub Actions pipeline  
> **📖 Baca juga:** [README.md](README.md) untuk dokumentasi lengkap sistem
