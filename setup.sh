#!/usr/bin/env bash
# =============================================================================
#  SETUP.SH - Multi-Agent System (MAS) Ecosystem Installer
#  Otomatisasi: Docker network, .env & secrets init, build & start
# =============================================================================
#
#  Cara penggunaan:
#    chmod +x setup.sh
#    ./setup.sh                     # Auto-detect (default lightweight)
#    ./setup.sh --lightweight       # Mode hemat resource (4 container)
#    ./setup.sh --minimal           # Mode minimal (3 container) ⭐
#    ./setup.sh --full              # Mode lengkap (9 container)
#    ./setup.sh --secrets           # Generate file secrets dari .env
#    ./setup.sh --status            # Cek status semua container
#    ./setup.sh --stop              # Stop semua container
#    ./setup.sh --clean             # Hapus semua container & volumes
#    ./setup.sh --help              # Tampilkan bantuan
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
#  KONSTANTA & WARNA
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MAS_MODE="${MAS_MODE:-lightweight}"

# Daftar secrets yang akan diekstrak dari .env
SECRET_VARS=(
    "ANTHROPIC_API_KEY"
    "OPENAI_API_KEY"
    "GEMINI_API_KEY"
    "EXA_API_KEY"
    "GITHUB_TOKEN"
    "WANDB_API_KEY"
    "MARKET_DATA_API_KEY"
    "SOLANA_PRIVATE_KEY"
)

# =============================================================================
#  FUNGSI-FUNGSI
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo '  __  __    _    ____ ___ _   _    _____ ___  ____   ___  _   _ _____ '
    echo ' |  \/  |  / \  / ___|_ _| \ | |  |  ___/ _ \|  _ \ / _ \| \ | | ____|'
    echo ' | |\/| | / _ \| |    | ||  \| |  | |_ | | | | |_) | | | |  \| |  _|  '
    echo ' | |  | |/ ___ \ |___ | || |\  |  |  _|| |_| |  _ <| |_| | |\  | |___ '
    echo ' |_|  |_/_/   \_\____|___|_| \_|  |_|   \___/|_| \_\\___/|_| \_|_____|'
    echo '                                                                      '
    echo -e "${NC}"
    echo -e "${BOLD}Multi-Agent System (MAS) Ecosystem Installer${NC}"
    echo -e "${BLUE}Framework: claude-swarm (CEO) + 6 CTO/CISO Agents${NC}"
    echo -e "${YELLOW}By: Affaan Mustafa${NC}"
    echo ""
}

print_step() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# =============================================================================
#  CHECK PREREQUISITES
# =============================================================================
check_prerequisites() {
    echo ""
    echo -e "${BOLD}🔍 Memeriksa Prasyarat...${NC}"
    echo ""

    if command -v docker &> /dev/null; then
        print_step "Docker terinstall: $(docker --version)"
    else
        print_error "Docker tidak ditemukan! Install Docker terlebih dahulu."
        print_info "Kunjungi: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if docker compose version &> /dev/null; then
        print_step "Docker Compose terinstall: $(docker compose version)"
    elif command -v docker-compose &> /dev/null; then
        print_step "Docker Compose terinstall: $(docker-compose --version)"
    else
        print_error "Docker Compose tidak ditemukan!"
        exit 1
    fi

    if command -v git &> /dev/null; then
        print_step "Git terinstall: $(git --version)"
    else
        print_error "Git tidak ditemukan!"
        exit 1
    fi

    # Cek RAM
    local total_ram_kb
    if [[ "$(uname)" == "Darwin" ]]; then
        total_ram_kb=$(sysctl hw.memsize | awk '{print $2/1024}')
    elif [[ "$(uname)" == "Linux" ]]; then
        total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    else
        total_ram_kb=0
    fi
    local total_ram_gb=$((total_ram_kb / 1024 / 1024))

    echo ""
    if [[ $total_ram_gb -lt 2 ]]; then
        print_warn "RAM terdeteksi: ${total_ram_gb}GB (SANGAT TERBATAS)"
        print_warn "CPU Intel Celeron N4000 hanya memiliki ~1.9GB RAM"
        print_info ""
        print_info "  full          → 7 container (butuh ≥8GB RAM)       ❌"
        print_info "  lightweight   → 4 container (butuh ≥4GB RAM)       ⚠️"
        print_info "  minimal       → 3 container (butuh ≥2GB RAM)       ✅"
        print_info ""
        if [[ "$MAS_MODE" == "full" ]]; then
            print_warn "Mode full TIDAK DISARANKAN! Beralih ke minimal? [Y/n]"
            read -r response
            [[ ! "$response" =~ ^[nN] ]] && MAS_MODE="minimal"
        fi
    elif [[ $total_ram_gb -lt 4 ]]; then
        print_warn "RAM terdeteksi: ${total_ram_gb}GB — rekomendasi: lightweight"
    else
        print_step "RAM terdeteksi: ${total_ram_gb}GB — mode full bisa dicoba"
    fi

    local avail_disk_kb
    avail_disk_kb=$(df "$SCRIPT_DIR" | awk 'NR==2 {print $4}')
    local avail_disk_gb=$((avail_disk_kb / 1024 / 1024))
    print_step "Ruang disk tersedia: ${avail_disk_gb}GB"
    echo ""
}

# =============================================================================
#  SETUP DOCKER NETWORK
# =============================================================================
setup_docker_network() {
    echo ""
    echo -e "${BOLD}🌐 Memeriksa Docker Network...${NC}"
    echo ""

    local network_name="${MAS_NETWORK_NAME:-mas-net}"

    if docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"; then
        print_step "Network '$network_name' sudah ada"
    else
        print_info "Membuat network '$network_name'..."
        docker network create \
            --driver bridge \
            --subnet 172.28.0.0/16 \
            --gateway 172.28.0.1 \
            --label "project=mas-ecosystem" \
            "$network_name"
        print_step "Network '$network_name' berhasil dibuat"
    fi
    echo ""
}

# =============================================================================
#  INITIALIZE .ENV
# =============================================================================
init_env() {
    echo ""
    echo -e "${BOLD}🔑 Inisialisasi File .env...${NC}"
    echo ""

    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            print_step "File .env dibuat dari .env.example"
            print_warn "⚠️  FILE .env MASIH MENGGUNAKAN PLACEHOLDER!"
            print_warn "EDIT .env dan isi API Key yang valid!"
            echo ""
            print_info "Minimal: ANTHROPIC_API_KEY → https://console.anthropic.com/"
            echo ""
        else
            print_error ".env.example tidak ditemukan!"
            exit 1
        fi
    else
        print_step "File .env sudah ada"
    fi
    echo ""
}

# =============================================================================
#  INITIALIZE SECRET FILES (Docker Secrets)
#  Ekstrak nilai dari .env ke file individual di ./secrets/
#  Container membaca dari /run/secrets/<NAMA_VARIABEL>
# =============================================================================
init_secrets() {
    echo ""
    echo -e "${BOLD}🔒 Inisialisasi File Secrets...${NC}"
    echo ""

    mkdir -p secrets

    if [[ ! -f .env ]]; then
        print_warn "File .env tidak ditemukan. Jalankan 'init_env' dulu."
        print_info "Lewati init_secrets..."
        touch secrets/.gitkeep
        echo ""
        return
    fi

    local found=0
    for var in "${SECRET_VARS[@]}"; do
        # Ekstrak nilai dari .env (hapus tanda kutip)
        local value
        value=$(grep "^${var}=" .env 2>/dev/null | head -1 | sed 's/^[^=]*=//' | sed "s/^['\"]//;s/['\"]$//")

        # Validasi: nilai tidak boleh placeholder, kosong, atau default template
    # Placeholder patterns yang dikenal:
    #   - sk-ant-xxx...  (placeholder Anthropic)
    #   - sk-xxx...      (placeholder OpenAI)
    #   - xxxxxxxx...    (nilai tidak diisi)
    #   - YOUR_...       (belum diisi)
    #   - changeme       (default)
    #   - ghp_xxx...     (placeholder GitHub)
    local is_placeholder=false
    if [[ -z "$value" ]]; then
        is_placeholder=true
    elif [[ "$value" == "changeme" || "$value" == "CHANGEME" ]]; then
        is_placeholder=true
    elif [[ "$value" =~ ^YOUR_ ]]; then
        is_placeholder=true
    elif [[ "$value" =~ ^sk-[a-z]+-xxx ]]; then
        is_placeholder=true
    elif [[ "$value" =~ ^ghp_xxx ]]; then
        is_placeholder=true
    elif [[ "$value" =~ ^[[:space:]]*$ ]]; then
        is_placeholder=true
    fi

    if ! $is_placeholder; then
        printf '%s' "$value" > "secrets/${var}"
        chmod 600 "secrets/${var}"
        print_step "secrets/${var} — OK"
        found=$((found + 1))
    fi
    done

    if [[ $found -eq 0 ]]; then
        print_warn "Tidak ada secrets valid ditemukan di .env"
        print_info "Isi API Key di .env dulu, lalu jalankan: ./setup.sh --secrets"
        print_info "Atau buat manual: echo 'sk-ant-xxx' > secrets/ANTHROPIC_API_KEY"
    else
        print_step "${found} file secrets berhasil dibuat di ./secrets/"
        print_info "Secrets akan di-mount ke container sebagai /run/secrets/<NAMA>"
        print_info "Gunakan docker-compose.override.yml untuk mengaktifkan secret mode"
    fi

    touch secrets/.gitkeep
    echo ""
}

# =============================================================================
#  CREATE DIRECTORY STRUCTURE
# =============================================================================
create_directories() {
    echo ""
    echo -e "${BOLD}📁 Membuat Struktur Direktori...${NC}"
    echo ""

    mkdir -p workspace data config logs secrets

    if [[ ! -f config/swarm.yaml ]]; then
        cat > config/swarm.yaml << 'SWAMYAML'
swarm:
  name: multi-agent-ecosystem
  max_concurrent: 2
  budget_usd: 5.0
  model: opus

agents:
  cto-office:
    description: JARVIS automation & OSINT platform
    model: haiku
    tools: [Read, Write, Bash, Edit]
    prompt: |
      You are the CTO Office Agent (JARVIS).
      Handle automation, OSINT, browser tasks, and intelligence gathering.

  cto-trading-rl:
    description: Behavioral RL for trading
    model: haiku
    tools: [Read, Write, Bash]
    prompt: |
      You are the CTO Trading Agent (Behavioral RL).
      Execute RL-based trading with risk management (CVaR, Prospect Theory).

  cto-trading-hyper:
    description: HyperMamba time-series analysis
    model: haiku
    tools: [Read, Write, Bash]
    prompt: |
      You are the CTO Trading Agent (HyperMamba).
      Analyze market time-series using State Space Models.

  cto-commerce:
    description: Agent of Commerce
    model: haiku
    tools: [Read, Write, Bash]
    prompt: |
      You are the CTO Commerce Agent.
      Manage e-commerce, inventory, and blockchain transactions.

  ciso-shield:
    description: AgentShield security auditor
    model: haiku
    tools: [Read, Grep, Glob]
    prompt: |
      You are the CISO Security Agent (AgentShield).
      Audit agent configs for secrets, MCP vulnerabilities.

  ciso-ecc:
    description: ECC Agent Harness OS
    model: haiku
    tools: [Read, Write, Bash]
    prompt: |
      You are the CISO Security Agent (ECC).
      Enforce policies, manage skills & memory.

connections:
  - from: ceo
    to: [cto-office, cto-trading-rl, cto-trading-hyper, cto-commerce]
  - from: [cto-office, cto-trading-rl, cto-trading-hyper, cto-commerce]
    to: [ciso-shield, ciso-ecc]
SWAMYAML
        print_step "config/swarm.yaml dibuat"
    fi

    if [[ ! -f config/ecc-policy.yaml ]]; then
        cat > config/ecc-policy.yaml << 'ECCPOLICY'
policy:
  version: "1.0"
  name: "mas-security-policy"
  restrictions:
    allowed_commands:
      - "git"  - "python"  - "pip"  - "npm"  - "node"
      - "curl" - "mkdir"  - "ls"  - "cat"  - "echo"
      - "cp"   - "mv"     - "rm"  - "python3"
    blocked_commands:
      - "sudo"  - "rm -rf /"  - "chmod 777"
      - "dd"    - "mkfs"      - "reboot"  - "shutdown"
  network:
    allowed_origins:
      - "*.github.com"  - "*.anthropic.com"
      - "api.openai.com"  - "api.exa.ai"
    blocked_origins:
      - "*.darkweb.*"  - "*.onion"
  audit:
    enabled: true
    log_level: info
    sensitive_patterns:
      - "sk-ant-*"  - "sk-*"  - "ghp_*"  - "AKIA*"
ECCPOLICY
        print_step "config/ecc-policy.yaml dibuat"
    fi

    touch secrets/.gitkeep workspace/.gitkeep data/.gitkeep logs/.gitkeep
    print_step "Struktur direktori siap"
    echo ""
}

# =============================================================================
#  BUILD & START CONTAINERS
# =============================================================================
build_and_start() {
    echo ""
    echo -e "${BOLD}🐳 Membangun & Menjalankan Container...${NC}"
    echo ""

    local compose_file="docker-compose.yml"
    local compose_opts=""

    if [[ "$MAS_MODE" == "lightweight" ]]; then
        compose_file="docker-compose.lightweight.yml"
        print_info "Mode: LIGHTWEIGHT (4 container)"
    elif [[ "$MAS_MODE" == "minimal" ]]; then
        compose_file="docker-compose.minimal.yml"
        print_info "Mode: MINIMAL (3 container)"
    else
        print_info "Mode: FULL (9 container — butuh RAM besar!)"
    fi

    if [[ ! -f "$compose_file" ]]; then
        print_error "File $compose_file tidak ditemukan!"
        exit 1
    fi

    # Aktifkan secret management jika file secrets tersedia
    if ls secrets/ANTHROPIC_API_KEY &>/dev/null 2>&1 && [[ -f docker-compose.override.yml ]]; then
        compose_opts="-f docker-compose.override.yml"
        print_info "Secret management AKTIF (file-based secrets di /run/secrets/)"
    fi

    print_info "Membangun image (SERIAL — menghindari OOM pada Celeron)..."
    docker compose -f "$compose_file" $compose_opts build 2>&1 | tail -5

    print_info "Menjalankan container..."
    docker compose -f "$compose_file" $compose_opts up -d 2>&1 | tail -10

    echo ""
    print_info "Build selesai! Tunggu 10-30 detik agar healthcheck lulus."
    echo ""
}

# =============================================================================
#  CHECK STATUS
# =============================================================================
check_status() {
    echo ""
    echo -e "${BOLD}📊 Status Container MAS${NC}"
    echo ""

    local compose_file="docker-compose.yml"
    [[ -f "docker-compose.lightweight.yml" ]] && compose_file="docker-compose.lightweight.yml"

    docker compose -f "$compose_file" ps --all
    echo ""
    echo -e "${BOLD}Penggunaan Resource:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || true

    echo ""
    echo -e "${BOLD}Secret Status:${NC}"
    if [[ -f "secrets/ANTHROPIC_API_KEY" ]]; then
        print_step "Secrets: ${BOLD}AKTIF${NC} (${GREEN}$(ls -1 secrets/ | wc -l) file${NC})"
    else
        print_warn "Secrets: ${BOLD}TIDAK AKTIF${NC}"
        print_info "  Jalankan: ./setup.sh --secrets"
    fi
    echo ""
}

# =============================================================================
#  STOP CONTAINERS
# =============================================================================
stop_containers() {
    echo ""
    echo -e "${BOLD}🛑 Menghentikan Container...${NC}"
    echo ""
    for f in docker-compose.yml docker-compose.lightweight.yml docker-compose.minimal.yml; do
        docker compose -f "$f" down 2>/dev/null || true
    done
    print_step "Semua container dihentikan"
    echo ""
}

# =============================================================================
#  CLEAN UP
# =============================================================================
clean_up() {
    echo ""
    echo -e "${BOLD}🧹 Membersihkan Semua Resource...${NC}"
    echo ""
    print_warn "Ini akan menghapus SEMUA container, volume, data, DAN secrets!"
    print_warn "Lanjutkan? [y/N]"
    read -r response

    if [[ "$response" =~ ^[yY] ]]; then
        stop_containers
        docker volume rm mas_workspace mas_data mas_models mas_redis_data 2>/dev/null || true
        docker network rm "${MAS_NETWORK_NAME:-mas-net}" 2>/dev/null || true
        docker rmi mas/ceo mas/cto-office mas/cto-trading-rl mas/cto-trading-hyper mas/cto-commerce mas/ciso-shield mas/ciso-ecc 2>/dev/null || true
        # Hapus secrets (tapi tanya dulu)
        print_warn "Hapus juga file secrets di ./secrets/? [y/N]"
        read -r del_secrets
        [[ "$del_secrets" =~ ^[yY] ]] && rm -rf secrets && print_step "Secrets dihapus"
        print_step "Semua resource dihapus"
    fi
    echo ""
}

# =============================================================================
#  PRINT SUMMARY
# =============================================================================
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}══════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  ✅  SETUP MAS SELESAI!${NC}"
    echo -e "${BOLD}${GREEN}══════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Mode:${NC}      ${MAS_MODE}"
    echo ""
    echo -e "  ${BOLD}Akses Agent:${NC}"
    echo -e "  CEO (claude-swarm):       http://localhost:${CEO_PORT:-8080}"
    echo -e "  CTO Office (JARVIS):     http://localhost:${CTO_OFFICE_PORT:-8081}"
    echo -e "  CTO Trading (RL):        http://localhost:${CTO_TRADING_RL_PORT:-8082}"
    echo -e "  CTO Trading (HyperMamba): http://localhost:${CTO_TRADING_HYPER_PORT:-8083}"
    echo -e "  CTO Commerce (AoC):      http://localhost:${CTO_COMMERCE_PORT:-8084}"
    echo -e "  CISO Shield:             http://localhost:${CISO_SHIELD_PORT:-8085}"
    echo -e "  CISO ECC:                http://localhost:${CISO_ECC_PORT:-8086}"
    echo ""
    echo -e "  ${BOLD}Jalankan swarm via CEO:${NC}"
    echo -e '  docker exec mas-ceo claude-swarm "Tugas Anda"'
    echo ""
    echo -e "  ${BOLD}Secret Management:${NC}"
    if [[ -f "secrets/ANTHROPIC_API_KEY" ]]; then
        echo -e "  ${GREEN}✅ AKTIF${NC} — ${BOLD}$(ls -1 secrets/ | wc -l)${NC} secrets terpasang"
    else
        echo -e "  ${YELLOW}⏸️  TIDAK AKTIF${NC}"
        echo -e "  Jalankan: ${BOLD}./setup.sh --secrets${NC} untuk mengaktifkan"
    fi
    echo ""
    echo -e "  ${YELLOW}⚠️  JANGAN LUPA:${NC}"
    echo -e "  1. Edit ${BOLD}.env${NC} dan isi ANTHROPIC_API_KEY"
    echo -e "  2. Jalankan ${BOLD}./setup.sh --secrets${NC} untuk amankan API key"
    echo -e "  3. Baca ${BOLD}ARCHITECTURE_ANALYSIS.md${NC} untuk optimasi RAM 2GB"
    echo ""
}

# =============================================================================
#  MAIN
# =============================================================================
main() {
    print_banner

    case "${1:-}" in
        --status|-s)   check_status; exit 0 ;;
        --stop|-S)     stop_containers; exit 0 ;;
        --secrets)     init_env; init_secrets; exit 0 ;;
        --clean|-c)    clean_up; exit 0 ;;
        --help|-h)
            echo "Penggunaan: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --lightweight  Mode hemat resource (CEO + JARVIS + RL + Redis)"
            echo "  --minimal      Mode minimal (CEO + JARVIS + Redis) ⭐ PALING STABIL"
            echo "  --full         Mode lengkap (semua 7 container)"
            echo "  --secrets      Generate file secrets dari .env ke ./secrets/"
            echo "  --status, -s   Cek status container"
            echo "  --stop, -S     Stop semua container"
            echo "  --clean, -c    Hapus semua resource"
            echo "  --help, -h     Tampilkan bantuan ini"
            echo ""
            echo "Dokumentasi tambahan:"
            echo "  ARCHITECTURE_ANALYSIS.md  — Analisis arsitektur untuk RAM 2GB"
            echo "  README.md                  — Dokumentasi lengkap"
            exit 0 ;;
        --lightweight) MAS_MODE="lightweight" ;;
        --minimal)     MAS_MODE="minimal" ;;
        --full)        MAS_MODE="full" ;;
        "")            ;; # auto-detect
        *) print_error "Opsi tidak dikenal: $1"; echo "Gunakan --help"; exit 1 ;;
    esac

    check_prerequisites
    setup_docker_network
    init_env
    create_directories
    init_secrets
    build_and_start
    print_summary
}

main "$@"
