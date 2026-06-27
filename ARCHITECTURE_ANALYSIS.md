# 🏗 Analisis Arsitektur Multi-Agent System (MAS) untuk RAM 2GB

**Hardware Target:** Intel Celeron N4000 (2 Core @ 1.10 GHz, 1.9GB RAM)  
**Framework:** claude-swarm (CEO) + 6 CTO/CISO Agents  
**Tanggal:** Juni 2026

---

## 📋 Daftar Isi

- [Ringkasan Eksekutif](#ringkasan-eksekutif)
- [Batasan Hardware](#batasan-hardware)
- [Analisis Konsumsi Resource](#analisis-konsumsi-resource)
- [Arsitektur yang Direkomendasikan](#arsitektur-yang-direkomendasikan)
- [Strategi Optimasi](#strategi-optimasi)
- [Mode Operasi](#mode-operasi)
- [Arsitektur Alternatif](#arsitektur-alternatif)
- [Secret Management](#secret-management)
- [Rekomendasi Final](#rekomendasi-final)

---

## Ringkasan Eksekutif

**Kesimpulan utama:** Menjalankan 7 container AI agent secara simultan di laptop dengan **RAM 1.9GB dan CPU 2 core @1.1GHz TIDAK MUNGKIN**. Sistem akan mengalami *Out of Memory (OOM)* dalam hitungan detik.

**Solusi yang direkomendasikan:**
1. **Mode lokal:** Hanya 2-3 container paling esensial (CEO + JARVIS + Redis)
2. **Agent remote:** Container berat (PyTorch, ML) dijalankan di server cloud
3. **Hybrid orchestration:** CEO di lokal, CTO Trading/Commerce di cloud via SSH/API
4. **Secret management:** Docker secrets + file terenkripsi untuk API keys

---

## Batasan Hardware

### Spesifikasi Aktual
```yaml
CPU:    Intel Celeron N4000 @ 1.10 GHz (2 core, 2 thread)
RAM:    1,916,016 kB ≈ 1.87 GB
Swap:   5,505,024 kB ≈ 5.37 GB (jauh lebih lambat dari RAM!)
Disk:   37 GB available / 67 GB total
Arch:   x86_64 (64-bit)
```

### Dampak pada Container
| Keterbatasan | Dampak | Solusi |
|-------------|--------|--------|
| RAM < 2GB | OOM killer akan mematikan container | Limit ketat 128-192m/container |
| CPU 2 core | Paralelisme sangat terbatas | Max 2 container aktif bersamaan |
| Swap 5.5GB | Thrashing jika terlalu banyak swap | Prioritaskan RAM, swap sebagai cadangan |
| Disk < 40GB | Image Docker PyTorch ~3-5GB | Gunakan image minimal (slim/alpine) |
| CPU @1.1GHz | Build image sangat lambat | Gunakan pre-built image jika ada |

### Perbandingan dengan Kebutuhan Ideal
```
Komponen         Ideal           Aktual (Celeron)   Selisih
──────────────────────────────────────────────────────────
RAM              8-16 GB         1.87 GB            ████░░ 23%
CPU Cores        4-8              2                  ██░░░░ 25%
CPU Freq          2.5+ GHz        1.10 GHz           ██░░░░ 44%
Disk             50+ GB free     37 GB free          ██████░ 74%
GPU              CUDA 8GB+        None (CPU only)    ░░░░░░ 0%
```

---

## Analisis Konsumsi Resource

### Per Container

| Agent | Image Size | RAM (idle) | RAM (active) | CPU | Prioritas |
|-------|-----------|-----------|-------------|-----|-----------|
| **CEO** (claude-swarm) | ~400 MB | ~80 MB | ~200 MB | 0.3 | 🔴 WAJIB |
| **CTO Office** (JARVIS) | ~600 MB | ~120 MB | ~350 MB | 0.5 | 🔴 WAJIB |
| **CTO Trading RL** (PyTorch) | ~3.5 GB | ~200 MB | ~800 MB | 1.0 | 🟡 Opsional |
| **CTO Trading Hyper** (Mamba) | ~3.5 GB | ~200 MB | ~800 MB | 1.0 | 🟡 Opsional |
| **CTO Trading Alice** (Node.js) | ~1.2 GB | ~150 MB | ~400 MB | 0.5 | 🟢 Multi-Market |
| **CTO Commerce** (Solana) | ~500 MB | ~100 MB | ~250 MB | 0.3 | 🟢 Ringan |
| **CISO Shield** | ~300 MB | ~60 MB | ~150 MB | 0.2 | 🟢 Ringan |
| **CISO ECC** (Node.js) | ~400 MB | ~80 MB | ~200 MB | 0.3 | 🟢 Ringan |
| **Redis** | ~30 MB | ~10 MB | ~50 MB | 0.05 | 🔴 WAJIB |

### Skenario Operasi

#### ❌ Mode Full (8 container + Redis) — CRASH
```
Total RAM dibutuhkan (idle):  80+120+200+200+150+100+60+80+10  = 1,000 MB
Total RAM dibutuhkan (active): 200+350+800+800+400+250+150+200+50 = 3,200 MB
RAM tersedia:                  1,870 MB
❌ KEKURANGAN: ~1,330 MB → OOM dalam detik
```

#### ⚠️ Mode Lightweight (4 container + Redis) — RISIKO TINGGI
```
Container: CEO + JARVIS + Trading RL + Redis
RAM active total: 200+350+800+50 = 1,400 MB
Swap dibutuhkan:  ~200-400 MB
⚠️ BISA JALAN, TAPI BERAT (tergantung swap aktif)
```

#### ✅ Mode Minimal (3 container + Redis) — STABIL
```
Container: CEO + JARVIS + Redis
RAM active total: 200+350+50 = 600 MB
Sisa RAM:         1,270 MB untuk OS + proses lain
✅ PALING STABIL — ada ruang untuk OS Windows/Linux
```

#### 🟢 Mode Ultra-Minimal (2 container + Redis) — SANGAT STABIL
```
Container: CEO + Redis (JARVIS dimatikan saat tidak dipakai)
RAM active total: 200+50 = 250 MB
Sisa RAM:         1,620 MB
✅ SISA BANYAK — sistem operasi masih responsif
```

---

## Arsitektur yang Direkomendasikan

```
┌──────────────────────────────────────────────────────────┐
│                   LAPTOP INTEL CELERON                    │
│                    RAM: 1.87 GB                           │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │   CEO    │  │ CTO OFF  │  │  Redis   │  (AKTIF)      │
│  │ claude-  │  │ JARVIS   │  │ Message  │               │
│  │ swarm    │  │ Browser  │  │ Broker   │               │
│  │ Port 8080│  │ Port 8081│  │ Port 6379│               │
│  └────┬─────┘  └────┬─────┘  └──────────┘               │
│       │             │                                    │
│       └──────┬──────┘                                    │
│              │ (via Redis pub/sub)                       │
│  ┌───────────▼──────────────────────────────────────┐   │
│  │         REMOTE CLOUD / VPS (8GB+ RAM)            │   │
│  │                                                  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐          │   │
│  │  │ Trading  │ │ Trading  │ │ Commerce │          │   │
│  │  │ RL Agent │ │HyperMamba│ │ AoC Agent│          │   │
│  │  │ PyTorch  │ │  Mamba   │ │  Solana  │          │   │
│  │  └──────────┘ └──────────┘ └──────────┘          │   │
│  │                                                  │   │
│  │  ┌──────────┐ ┌──────────┐                       │   │
│  │  │  CISO    │ │  CISO    │                       │   │
│  │  │ Shield   │ │   ECC    │                       │   │
│  │  └──────────┘ └──────────┘                       │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## Strategi Optimasi

### 1. Resource Limits Ketat

Setiap container HARUS memiliki memory limit. Tanpa limit, satu container bisa memonopoli semua RAM.

```yaml
# docker-compose.yml — WAJIB untuk setiap service
services:
  ceo:
    mem_limit: 128m        # Hard limit — container OOM jika lebih
    mem_reservation: 64m   # Soft limit — jaminan minimal
    cpus: 0.25             # Max 25% dari 1 core
    pids_limit: 50         # Batasi jumlah proses
    oom_kill_disable: false # Biarkan OOM killer bekerja
```

### 2. Image Minimal

| Base Image | Size | RAM Base | Cocok Untuk |
|-----------|------|---------|------------|
| `python:3.11-slim` | ~120 MB | ~30 MB | CEO, Trading |
| `python:3.11-alpine` | ~50 MB | ~20 MB | CISO (jika kompatibel) |
| `node:20-slim` | ~180 MB | ~40 MB | ECC |
| `redis:7-alpine` | ~30 MB | ~5 MB | ✅ Redis |
| `python:3.11` (full) | ~900 MB ❌ | ~80 MB | Hindari! |

### 3. Swap Optimization

```bash
# Cek status swap
sudo swapon --show

# Jika perlu tambah swap (hanya untuk Linux)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Persisten di /etc/fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Set swappiness rendah (0 = seminimal mungkin)
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
```

### 4. Docker Build Optimization

```bash
# Build serial (TIDAK parallel! — untuk Celeron)
docker compose build              # ✅ serial — aman
docker compose build --parallel   # ❌ parallel — OOM!

# Cache mount untuk mempercepat build
# Tambahkan di Dockerfile:
# RUN --mount=type=cache,target=/root/.cache/pip pip install ...
```

### 5. CPU Throttling

```yaml
# Celeron hanya punya 2 core. Jangan oversubscribe.
# Total CPU limit semua container TIDAK boleh > 1.5 core

ceo:              cpus: 0.25   # 25% core
cto-office:       cpus: 0.5    # 50% core  
redis:            cpus: 0.05   # 5% core
────────────────────────────────────────
Total digunakan:  cpus: 0.8    # 80% dari 1 core ✅
Sisa untuk OS:    cpus: 1.2    # OS masih responsif ✅
```

### 6. Docker Daemon Configuration

```json
// /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "5m",
    "max-file": "2"
  },
  "experimental": true,
  "fixed-cidr-v6": "",
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "default-shm-size": "64m"
}
```

---

## Mode Operasi Detail

### ✅ Mode Minimal (REKOMENDASI UTAMA)

```bash
./setup.sh --minimal
```

```yaml
Container: ceo (128m) + cto-office (128m) + redis (32m)
Total RAM: ~288 MB idle | ~600 MB active
💡 Sisa RAM: ~1.27 GB untuk OS
🎯 Paling stabil untuk coding & browsing
```

### 🟢 Mode Ultra-Minimal (ALTERNATIF)

```bash
# Hanya CEO + Redis
docker compose -f docker-compose.minimal.yml up -d ceo redis
```

```yaml
Container: ceo (128m) + redis (32m)
Total RAM: ~160 MB idle | ~250 MB active  
💡 Sisa RAM: ~1.62 GB — sistem terasa ringan
```

### 🔄 Mode Hybrid (SOLUSI TERBAIK UNTUK PRODUKSI)

Arsitektur hybrid membagi beban antara lokal dan cloud:

```yaml
# Lokal (Celeron 2GB):
# - CEO: orchestrator ringan
# - JARVIS: browser automation (ringan)
# - Redis: message broker
# Total: ~600 MB

# Cloud/VPS (8GB+ RAM, GPU opsional):
# - Trading RL: training & inference PyTorch
# - HyperMamba: time-series prediction
# - Open Alice: multi-market analysis & trading
# - Commerce: e-commerce + blockchain
# - CISO Shield + ECC: security
```

**Komunikasi lokal → cloud:**
1. CEO publish task ke Redis channel
2. Redis replicator sync ke cloud Redis
3. Cloud agents consume task, publish hasil
4. CEO consume hasil dari cloud

```bash
# Di cloud (VPS):
git clone https://github.com/affaan-m/claude-swarm
docker compose -f docker-compose.yml up -d \
  cto-trading-rl cto-trading-hyper \
  cto-trading-alice cto-commerce \
  ciso-shield ciso-ecc
```

---

## Arsitektur Alternatif

### Alternatif 1: Tanpa Docker Sama Sekali

Jika Docker terlalu berat (daemon Docker sendiri makan ~200MB RAM), jalankan agent langsung:

```bash
# Pasang claude-swarm langsung (tanpa Docker)
pip install claude-swarm
claude-swarm "Tugas Anda"

# Python virtual environment lebih ringan dari container
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Pro:** ✅ Hemat ~200MB RAM (tanpa Docker daemon)  
**Kontra:** ❌ Isolasi kurang, setup lebih manual

### Alternatif 2: Podman sebagai Alternatif Docker

```bash
# Podman lebih ringan karena tanpa daemon
sudo apt install podman podman-compose
podman compose up -d
```

**Pro:** ✅ Daemonless, lebih hemat RAM  
**Kontra:** ❌ Kompatibilitas belum 100%, Windows tidak support

### Alternatif 3: Orchestrator Manual dengan Tmux

```bash
# Jalankan agent di session tmux terpisah
tmux new-session -d -s ceo 'claude-swarm --watch'
tmux new-session -d -s jarvis 'python jarvis/main.py'
```

**Pro:** ✅ Sangat ringan, kontrol penuh  
**Kontra:** ❌ Manual, tidak ada auto-restart

### Alternatif 4: Remote Agent via SSH

```yaml
# CEO lokal mengirim task ke remote agent via SSH:
alias remote-trade='ssh user@vps "docker exec mas-cto-trading-rl python train.py"'
```

**Pro:** ✅ Container berat tidak makan RAM lokal  
**Kontra:** ❌ Butuh koneksi internet stabil

### Alternatif 5: GitHub Actions / CI/CD Pipeline

Gunakan GitHub Actions untuk menjalankan task berat:

```yaml
# .github/workflows/trading.yml
on: [workflow_dispatch]
jobs:
  trading:
    runs-on: ubuntu-latest
    steps:
      - run: docker run mas/cto-trading-rl python train.py
```

**Pro:** ✅ Gratis (2000 menit/bulan), cloud dengan RAM 8GB  
**Kontra:** ❌ Tidak real-time, delay beberapa detik

---

## Secret Management

### Arsitektur Secret Management

```
┌─────────────────────────────────────────────────┐
│               MAS SECRET SYSTEM                  │
│                                                  │
│  Production:      Development:                   │
│  ┌────────────┐   ┌────────────────────────┐    │
│  │ Vault/     │   │ Docker Compose Secrets │    │
│  │ Cloud KMS  │   │ (/run/secrets/)        │    │
│  └────────────┘   └────────────────────────┘    │
│        │                    │                     │
│        └────────┬───────────┘                    │
│                 │                                 │
│        ┌────────▼────────┐                        │
│        │ Health Server   │                        │
│        │ membaca secrets │                        │
│        │ dari file atau  │                        │
│        │ environment     │                        │
│        └─────────────────┘                        │
└─────────────────────────────────────────────────┘
```

### Tingkat Keamanan

| Level | Metode | Keamanan | Cocok Untuk |
|-------|--------|----------|-------------|
| 🟢 **Dasar** | `.env` file | Rendah | Development lokal |
| 🟡 **Sedang** | Docker secrets (`/run/secrets/`) | Sedang | Production kecil |
| 🟠 **Tinggi** | File terenkripsi (SOPS/dotenvx) | Tinggi | Team development |
| 🔴 **Maksimal** | HashiCorp Vault / AWS Secrets Manager | Sangat Tinggi | Enterprise |

### Implementasi: Docker Secrets (Non-Swarm)

```yaml
# docker-compose.override.yml
secrets:
  anthropic_key:
    file: ./secrets/ANTHROPIC_API_KEY
  openai_key:
    file: ./secrets/OPENAI_API_KEY

services:
  ceo:
    secrets:
      - anthropic_key
      - openai_key
    # Container membaca dari /run/secrets/anthropic_key
```

### Implementasi: Encrypted Secrets dengan SOPS

```bash
# Install SOPS + Age
brew install sops age    # macOS
# Atau download dari GitHub Releases

# Generate key pair
age-keygen -o ~/.config/sops/age/keys.txt

# Enkripsi file secrets
sops --encrypt --age $(cat ~/.config/sops/age/keys.txt | grep -oP 'public key: \K(.*)') \
  secrets.enc.env > secrets.enc.env

# Dekripsi saat runtime
sops --decrypt secrets.enc.env > .env
```

### Best Practices Secret Management

1. **Jangan commit secrets ke git** — sudah di .gitignore
2. **Gunakan file-based secrets** — lebih aman dari env vars
3. **Rotasi secrets berkala** — ganti API key tiap 90 hari
4. **Minimal privilege** — setiap container hanya punya secrets yang diperlukan
5. **Audit log** — CISO Shield mendeteksi hardcoded secrets
6. **File permission** — `chmod 600` untuk file secrets

---

## Rekomendasi Final

### Timeline Implementasi Bertahap

```mermaid
graph LR
    A[Fase 1: Minimal] --> B[Fase 2: Hybrid]
    B --> C[Fase 3: Full Cloud]
    
    A: Mode minimal lokal (CEO + JARVIS + Redis)
    B: CEO lokal + agent berat di cloud/VPS
    C: Semua agent di cloud, laptop hanya terminal
```

### Fase 1: Immediate (Hari 1-7)
```bash
# Jalankan mode minimal
./setup.sh --minimal
```
✅ **3 container — stabil di 2GB RAM**  
✅ **Bisa coding & browsing bersamaan**  
✅ **Semua API key via secrets**

### Fase 2: Hybrid (Minggu 2-4)
```yaml
# CEO di lokal, agent berat di VPS murah ($5-10/bulan)
# VPS: DigitalOcean/Linode 2GB RAM cukup untuk agent tambahan
```
✅ **Agent berat tidak bebani RAM lokal**  
✅ **Skalabilitas: tambah VPS sesuai kebutuhan**

### Fase 3: Optimal (Bulan 2+)
```yaml
# Upgrade hardware atau gunakan cloud sepenuhnya
# Rekomendasi VPS: 8GB RAM, 4 CPU, $20-40/bulan
```
✅ **Semua agent jalan simultan**  
✅ **GPU untuk training model**  
✅ **High availability**

### Kesimpulan

> **Untuk laptop Intel Celeron N4000 dengan RAM 1.9GB:**
> 
> **🏆 Rekomendasi #1:** Mode minimal — CEO + JARVIS + Redis (stabil)
> 
> **🥈 Rekomendasi #2:** Mode hybrid — CEO lokal, agent berat di cloud
> 
> **🥉 Rekomendasi #3:** Ultra-minimal — CEO + Redis (sangat ringan)
> 
> **❌ JANGAN:** Mode full — pasti OOM!
> 
> **🔐 Secret management:** Wajib menggunakan Docker secrets untuk API key

---

## Referensi

- [Docker Resource Constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Docker Compose Secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Linux Swap Documentation](https://www.kernel.org/doc/Documentation/cgroup-v1/memory.txt)
- [SOPS - Mozilla](https://github.com/getsops/sops)
- [Docker Daemon Configuration](https://docs.docker.com/engine/daemon/)
