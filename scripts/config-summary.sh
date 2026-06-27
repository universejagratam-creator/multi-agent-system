#!/usr/bin/env bash
# =============================================================================
#  CONFIG-SUMMARY.SH — Auto-summary Config untuk CEO Agent
#  Membaca config JAGRATAM terbaru dan publish ke Redis untuk CEO
# =============================================================================
#  Cara penggunaan:
#    chmod +x scripts/config-summary.sh
#    ./scripts/config-summary.sh              # Publish ke Redis lokal
#    ./scripts/config-summary.sh --stdout      # Cetak ke terminal saja
#    ./scripts/config-summary.sh --watch       # Monitoring loop (30s interval)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REDIS_CHANNEL="agent:ceo:config-update"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

print_step() { echo -e "${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# ── Baca konfigurasi terbaru ──────────────────────────────────────────
gather_summary() {
    local config_dir="$PROJECT_DIR/../JAGRATAM-FIXED/config"
    local mas_dir="$PROJECT_DIR"

    # Deteksi mode dari .env
    local mode="unknown"
    if [ -f "$config_dir/.env" ]; then
        if grep -q "BINGX_VST_MODE=true" "$config_dir/.env" 2>/dev/null; then
            mode="VST_DEMO"
        elif grep -q "BINGX_VST_MODE=false" "$config_dir/.env" 2>/dev/null; then
            mode="LIVE"
        fi
    fi

    # Baca jumlah total capital dari allocation.json
    local capital="?"
    if [ -f "$config_dir/allocation.json" ]; then
        capital=$(python3 -c "import json; d=json.load(open('$config_dir/allocation.json')); print(d.get('total_capital','?'))" 2>/dev/null || echo "?")
    fi

    # Baca bot aktif dari strategy_config.json
    local active_bots="?"
    if [ -f "$config_dir/strategy_config.json" ]; then
        active_bots=$(python3 -c "
import json
d=json.load(open('$config_dir/strategy_config.json'))
bots = [k for k in d.keys() if k.endswith('_bot') or k.endswith('_combo')]
print(', '.join(sorted(bots)))
" 2>/dev/null || echo "?")
    fi

    # Cek status Guardian
    local guardian_status="?"
    if [ -f "$config_dir/guardian_config.json" ]; then
        guardian_status=$(python3 -c "
import json
d=json.load(open('$config_dir/guardian_config.json'))
auto_restart = d.get('enable_auto_restart', '?')
telegram = d.get('enable_telegram', '?')
print(f'auto_restart={auto_restart}, telegram={telegram}')
" 2>/dev/null || echo "?")
    fi

    # Cek running Docker containers (jika ada)
    local docker_status="not_available"
    if command -v docker &>/dev/null; then
        docker_status=$(docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ', ' || echo "none")
    fi

    # Build summary JSON
    python3 -c "
import json, datetime
summary = {
    'type': 'config_summary',
    'timestamp': '$TIMESTAMP',
    'source': 'JAGRATAM-FIXED/config/',
    'mode': '$mode',
    'capital_usd': $capital,
    'guardian': '$guardian_status',
    'active_bots': '$active_bots',
    'docker_containers': '$docker_status',
    'config_files': {
        'ai_pipeline': 'config/ai_agents.json',
        'trading_controller': 'config/ai_trading_controller.json',
        'allocation': 'config/allocation.json',
        'guardian': 'config/guardian_config.json',
        'master': 'config/master_config.json',
        'strategy': 'config/strategy_config.json',
        'wallets': 'config/wallet_tracking.json',
        'env': 'config/.env'
    },
    'reference_docs': {
        'system_spec': 'docs/JAGRATAM-BINGX-ECC-SYSTEM.md',
        'config_ref': 'docs/CONFIG-REFERENCE.md'
    },
    'workflows': {
        'ci': '.github/workflows/ci.yml',
        'trading': '.github/workflows/trading.yml'
    }
}
print(json.dumps(summary, indent=2))
"
}

# ── Kirim ke Redis ────────────────────────────────────────────────────
publish_redis() {
    local summary="$1"
    if command -v redis-cli &>/dev/null; then
        if redis-cli -p "${REDIS_PORT:-6379}" PUBLISH "$REDIS_CHANNEL" "$summary" &>/dev/null; then
            print_step "Summary published ke Redis channel: $REDIS_CHANNEL"
        else
            print_warn "Redis tidak reachable di port ${REDIS_PORT:-6379}"
        fi
    else
        print_warn "redis-cli tidak ditemukan — skip publish"
    fi
}

# ── MAIN ──────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}${BLUE}MAS Config Summary Tool${NC}"
    echo -e "${BLUE}Publish config status ke CEO agent via Redis${NC}"
    echo ""

    case "${1:-}" in
        --stdout)
            gather_summary
            ;;
        --watch)
            print_info "Monitoring mode — every 30s..."
            while true; do
                echo ""
                echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Gathering config..."
                local summary
                summary=$(gather_summary)
                publish_redis "$summary"
                sleep 30
            done
            ;;
        *)
            local summary
            summary=$(gather_summary)
            echo "$summary" | python3 -m json.tool 2>/dev/null || echo "$summary"
            echo ""
            publish_redis "$summary"
            print_step "Done"
            echo ""
            ;;
    esac
}

main "$@"
