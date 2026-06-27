#!/usr/bin/env bash
# =============================================================================
#  CLOUD-INIT.SH - One-command VPS setup untuk hybrid architecture
#  Menjalankan semua agent berat di cloud VPS
# =============================================================================
#
#  Cara penggunaan:
#    ssh root@VPS_IP 'bash -s' < scripts/cloud-init.sh
#    # Atau download langsung:
#    curl -fsSL https://raw.githubusercontent.com/affaan-m/claude-swarm/main/scripts/cloud-init.sh | bash
#
# =============================================================================

set -euo pipefail

# Color codes digunakan oleh fungsi print di bawah
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

print_step() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# =============================================================================
#  1. SYSTEM UPDATE
# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}MAS Cloud VPS Initialization${NC}"
echo -e "${BLUE}==============================${NC}"
echo ""

echo -e "${BOLD}1/6 Memperbarui sistem...${NC}"
apt-get update -qq && apt-get upgrade -y -qq
print_step "System updated"

# =============================================================================
#  2. INSTALL DOCKER
# =============================================================================
echo ""
echo -e "${BOLD}2/6 Menginstall Docker...${NC}"

if command -v docker &>/dev/null; then
    print_step "Docker sudah terinstall: $(docker --version)"
else
    curl -fsSL https://get.docker.com | sh
    print_step "Docker terinstall: $(docker --version)"
fi

# =============================================================================
#  3. INSTALL DOCKER COMPOSE
# =============================================================================
echo ""
echo -e "${BOLD}3/6 Menginstall Docker Compose...${NC}"

if docker compose version &>/dev/null; then
    print_step "Docker Compose sudah terinstall: $(docker compose version)"
else
    apt-get install -y docker-compose-plugin -qq
    print_step "Docker Compose terinstall"
fi

# =============================================================================
#  4. SETUP SWAP (untuk VPS dengan RAM < 4GB)
# =============================================================================
echo ""
echo -e "${BOLD}4/6 Optimasi swap...${NC}"

total_ram_kb="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
total_ram_gb="$((total_ram_kb / 1024 / 1024))"

if [[ $total_ram_gb -lt 4 ]]; then
    print_warn "RAM ${total_ram_gb}GB — menambah swap 4GB..."
    if ! swapon --show | grep -q /swapfile; then
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        print_step "Swap 4GB diaktifkan"
    else
        print_step "Swap sudah aktif"
    fi
else
    print_step "RAM ${total_ram_gb}GB — swap tidak diperlukan"
fi

# =============================================================================
#  5. CLONE & SETUP MAS PROJECT
# =============================================================================
echo ""
echo -e "${BOLD}5/6 Setup Multi-Agent System...${NC}"

project_dir="/root/multi-agent-system"

if [[ -d "$project_dir" ]]; then
    print_step "Project sudah ada di $project_dir"
    cd "$project_dir"
    git pull --ff-only 2>/dev/null || true
else
    mkdir -p "$project_dir"
    if git clone --depth 1 https://github.com/affaan-m/claude-swarm.git "$project_dir" 2>/dev/null; then
        print_step "Project cloned ke $project_dir"
    else
        print_warn "Clone gagal. Gunakan direktori $project_dir yang sudah ada."
    fi
fi

cd "$project_dir"

# =============================================================================
#  6. BUILD & START HYBRID CONTAINERS
# =============================================================================
echo ""
echo -e "${BOLD}6/6 Build & start hybrid containers...${NC}"
echo ""

echo ""
print_info "CATATAN: Sebelum build, pastikan .env sudah diisi!"
print_info "  nano $project_dir/.env"
print_info "  Minimal: ANTHROPIC_API_KEY"
echo ""
print_info "Atau copy dari lokal:"
print_info "  scp user@laptop:~/multi-agent-system/.env $project_dir/"
echo ""

if [[ -f ".env" ]] && [[ -f "docker-compose.hybrid.yml" ]]; then
    print_info "Membangun image (mungkin memakan waktu 10-30 menit)..."
    docker compose -f docker-compose.hybrid.yml build 2>&1 | tail -10

    print_info "Menjalankan container..."
    docker compose -f docker-compose.hybrid.yml up -d 2>&1 | tail -10

    echo ""
    print_step "Container berjalan!"
    docker compose -f docker-compose.hybrid.yml ps

    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  ✅ VPS CLOUD READY!${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════${NC}"
    echo ""
    echo "  Trading RL:    http://$(curl -s ifconfig.me):8082/health"
    echo "  HyperMamba:    http://$(curl -s ifconfig.me):8083/health"
    echo "  Commerce:      http://$(curl -s ifconfig.me):8084/health"
    echo "  Redis:         port 6380"
    echo ""
    echo "  Untuk konek dari lokal:"
    echo "  ./scripts/remote-sync.sh --tunnel"
    echo ""
else
    print_warn "File .env atau docker-compose.hybrid.yml tidak ditemukan"
    print_info "  Buat .env dulu, lalu jalankan:"
    print_info "  cd $project_dir && docker compose -f docker-compose.hybrid.yml up -d"
fi

echo ""
print_step "Cloud init selesai!"
echo ""
