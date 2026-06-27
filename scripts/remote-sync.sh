#!/usr/bin/env bash
# =============================================================================
#  REMOTE-SYNC.SH - Local to Cloud Synchronization Tool
#  Menghubungkan laptop Celeron (local) dengan VPS/GitHub Actions (cloud)
# =============================================================================
#
#  Fitur:
#    - SSH tunnel untuk Redis replication
#    - Docker image sync dari local ke cloud
#    - File workspace sync (bidirectional)
#    - Health check kedua environment
#
#  Cara penggunaan:
#    chmod +x scripts/remote-sync.sh
#    ./scripts/remote-sync.sh --setup       # First-time setup
#    ./scripts/remote-sync.sh --status      # Check connection status
#    ./scripts/remote-sync.sh --sync        # Sync workspace files
#    ./scripts/remote-sync.sh --tunnel      # Start SSH tunnel
#    ./scripts/remote-sync.sh --deploy      # Deploy cloud containers
#    ./scripts/remote-sync.sh --stop        # Stop all connections
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Konfigurasi (bisa di-override via .env)
SSH_HOST="${SSH_HOST:-}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
CLOUD_DIR="${CLOUD_DIR:-/root/multi-agent-system}"
REDIS_LOCAL_PORT="${REDIS_LOCAL_PORT:-6379}"
REDIS_CLOUD_PORT="${REDIS_CLOUD_PORT:-6380}"

# =============================================================================
#  FUNGSI
# =============================================================================

print_step() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

check_config() {
    if [[ -z "$SSH_HOST" ]]; then
        print_error "SSH_HOST belum di-set!"
        print_info "Set environment variable atau buat .env:"
        echo "  export SSH_HOST=123.456.789.0"
        echo "  export SSH_USER=root"
        exit 1
    fi
}

setup_ssh_key() {
    echo ""
    echo -e "${BOLD}🔑 Setup SSH Key untuk akses VPS...${NC}"
    echo ""

    if [[ ! -f ~/.ssh/id_rsa ]]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
        print_step "SSH key dibuat di ~/.ssh/id_rsa"
    else
        print_step "SSH key sudah ada"
    fi

    echo ""
    print_info "Copy public key ke VPS:"
    echo "  ssh-copy-id ${SSH_USER}@${SSH_HOST}"
    echo "  # atau manual: cat ~/.ssh/id_rsa.pub | ssh ${SSH_USER}@${SSH_HOST} 'cat >> ~/.ssh/authorized_keys'"
    echo ""
}

sync_files() {
    echo ""
    echo -e "${BOLD}📁 Sync workspace files ke cloud...${NC}"
    echo ""

    check_config
    local sync_dirs=("workspace" "data" "config" "secrets" "services")

    for dir in "${sync_dirs[@]}"; do
        if [[ -d "$PROJECT_DIR/$dir" ]]; then
            print_info "Sync $dir/ ke cloud..."
            rsync -avz --progress -e "ssh -p $SSH_PORT" \
                "$PROJECT_DIR/$dir/" \
                "${SSH_USER}@${SSH_HOST}:${CLOUD_DIR}/$dir/"
            print_step "$dir/ synced"
        fi
    done

    # Sync docker-compose files
    rsync -avz -e "ssh -p $SSH_PORT" \
        "$PROJECT_DIR/docker-compose.hybrid.yml" \
        "$PROJECT_DIR/.env" \
        "${SSH_USER}@${SSH_HOST}:${CLOUD_DIR}/"

    print_step "Sync selesai!"
    echo ""
}

start_tunnel() {
    echo ""
    echo -e "${BOLD}🔗 Memulai SSH Tunnel (Redis replication)...${NC}"
    echo ""

    check_config

    # Cek apakah tunnel sudah jalan
    if pgrep -f "autossh.*${SSH_HOST}" &>/dev/null; then
        print_step "SSH tunnel sudah aktif"
        return
    fi

    # Pastikan autossh terinstall
    if ! command -v autossh &>/dev/null; then
        print_info "Menginstall autossh..."
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install autossh
        elif [[ "$(uname)" == "Linux" ]]; then
            sudo apt install -y autossh
        fi
    fi

    # Tunnel: forward port Redis cloud ke local
    # Format: -R [bind_address:]port:host:hostport
    autossh -M 0 \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes" \
        -N \
        -R "${REDIS_CLOUD_PORT}:localhost:${REDIS_LOCAL_PORT}" \
        "${SSH_USER}@${SSH_HOST}" \
        -p "$SSH_PORT" &

    local pid=$!
    sleep 2

    if kill -0 $pid 2>/dev/null; then
        print_step "SSH tunnel aktif (PID: $pid)"
        print_info "Redis cloud → local: port ${REDIS_CLOUD_PORT} → ${REDIS_LOCAL_PORT}"
        echo "$pid" > /tmp/mas-tunnel.pid
    else
        print_error "Gagal membuat SSH tunnel!"
        print_info "Cek: ssh ${SSH_USER}@${SSH_HOST} -p ${SSH_PORT}"
    fi
    echo ""
}

deploy_cloud() {
    echo ""
    echo -e "${BOLD}🚀 Deploy container ke cloud...${NC}"
    echo ""

    check_config

    # Sync files dulu
    sync_files

    # Eksekusi docker compose di remote
    print_info "Menjalankan container di cloud VPS..."
    ssh "${SSH_USER}@${SSH_HOST}" -p "$SSH_PORT" bash -s << 'REMOTESCRIPT'
        set -euo pipefail
        CLOUD_DIR="${CLOUD_DIR:-/root/multi-agent-system}"
        cd "\$CLOUD_DIR"
        echo "Directory: \$(pwd)"

        if ! command -v docker &>/dev/null; then
            echo "Menginstall Docker..."
            curl -fsSL https://get.docker.com | sh
        fi

        docker compose -f docker-compose.hybrid.yml build
        docker compose -f docker-compose.hybrid.yml up -d

        echo "=== Status ==="
        docker compose -f docker-compose.hybrid.yml ps

        echo "=== Resource Usage ==="
        docker stats --no-stream
REMOTESCRIPT

    echo ""
    print_step "Deploy selesai!"
    echo ""
}

check_status() {
    echo ""
    echo -e "${BOLD}📊 Status Hybrid Connection${NC}"
    echo ""

    # Cek local Redis
    if command -v redis-cli &>/dev/null; then
        local redis_ping
        redis_ping=$(redis-cli -p "$REDIS_LOCAL_PORT" ping 2>/dev/null || echo "FAIL")
        if [[ "$redis_ping" == "PONG" ]]; then
            print_step "Local Redis: ✅ RUNNING (port $REDIS_LOCAL_PORT)"
        else
            print_warn "Local Redis: ⚠️  NOT RESPONDING"
        fi
    fi

    # Cek SSH tunnel
    if pgrep -f "autossh.*${SSH_HOST}" &>/dev/null; then
        print_step "SSH Tunnel: ✅ ACTIVE"
    else
        print_warn "SSH Tunnel: ❌ NOT ACTIVE"
    fi

    # Cek VPS (jika reachable)
    if [[ -n "$SSH_HOST" ]]; then
        if ssh -o ConnectTimeout=5 "${SSH_USER}@${SSH_HOST}" -p "$SSH_PORT" "echo OK" 2>/dev/null; then
            print_step "VPS Connection: ✅ REACHABLE"

            # Cek cloud containers
            echo ""
            echo -e "${BOLD}Cloud Containers:${NC}"
            ssh "${SSH_USER}@${SSH_HOST}" -p "$SSH_PORT" \
                "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'No containers running'"
        else
            print_warn "VPS Connection: ❌ UNREACHABLE"
            print_info "  Cek: ssh ${SSH_USER}@${SSH_HOST} -p ${SSH_PORT}"
        fi
    else
        print_warn "SSH_HOST tidak dikonfigurasi"
        print_info "  Set: export SSH_HOST=123.456.789.0"
    fi

    echo ""
}

stop_tunnel() {
    echo ""
    echo -e "${BOLD}🛑 Menghentikan semua koneksi...${NC}"
    echo ""

    # Stop SSH tunnel
    if [[ -f /tmp/mas-tunnel.pid ]]; then
        kill "$(cat /tmp/mas-tunnel.pid)" 2>/dev/null || true
        rm -f /tmp/mas-tunnel.pid
    fi
    pkill -f "autossh.*${SSH_HOST}" 2>/dev/null || true

    print_step "SSH tunnel dihentikan"
    echo ""
}

# =============================================================================
#  MAIN
# =============================================================================
main() {
    echo ""
    echo -e "${BOLD}${BLUE}MAS Hybrid Connection Tool${NC}"
    echo -e "${BLUE}Local ↔ Cloud Synchronization${NC}"
    echo ""

    case "${1:-}" in
        --setup)     setup_ssh_key ;;
        --sync)      sync_files ;;
        --tunnel)    start_tunnel ;;
        --deploy)    deploy_cloud ;;
        --status)    check_status ;;
        --stop)      stop_tunnel ;;
        --help|-h)
            echo "Penggunaan: $0 [OPTIONS]"
            echo ""
            echo "  --setup    Setup SSH key untuk akses VPS"
            echo "  --sync     Sync workspace files ke cloud"
            echo "  --tunnel   Start SSH tunnel (Redis replication)"
            echo "  --deploy   Deploy container ke cloud (sync + build + up)"
            echo "  --status   Cek status koneksi hybrid"
            echo "  --stop     Stop SSH tunnel"
            echo "  --help     Tampilkan bantuan ini"
            echo ""
            echo "Environment variables:"
            echo "  SSH_HOST        VPS IP address (wajib)"
            echo "  SSH_USER        SSH user (default: root)"
            echo "  SSH_PORT        SSH port (default: 22)"
            echo "  CLOUD_DIR       Direktori project di VPS"
            echo "  REDIS_LOCAL_PORT Port Redis local (default: 6379)"
            echo "  REDIS_CLOUD_PORT Port Redis cloud (default: 6380)"
            exit 0 ;;
        "")
            check_status
            exit 0 ;;
        *)
            print_error "Opsi tidak dikenal: $1"
            echo "Gunakan --help untuk bantuan."
            exit 1 ;;
    esac
}

main "$@"
