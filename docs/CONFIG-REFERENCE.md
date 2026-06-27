# JAGRATAM-BINGX Configuration Reference

> **CEO Agent Reference** — Ringkasan konfigurasi dari `C:\Users\Administrator\PROJECT\JAGRATAM-FIXED\config\`
> 
> Sumber: `ai_agents.json`, `ai_trading_controller.json`, `allocation.json`, `guardian_config.json`, `master_config.json`, `strategy_config.json`, `wallet_tracking.json`

---

## 1. AI Agent Pipeline (OpenRouter)

**Pipeline order:** Perplexity → Mirofish → DeepSeek → Claude Audit → QwenCoder → Claude Code

| Agent | Model | Role | Temperature |
|-------|-------|------|-------------|
| Perplexity | `perplexity/sonar-pro` | Researcher (whale, news, sentiment) | 0.3 |
| Mirofish | `mistralai/mistral-large` | Simulator (backtest 50 trades, win rate) | 0.4 |
| DeepSeek | `deepseek/deepseek-chat` | Statistician (drawdown, Kelly, position sizing) | 0.1 |
| Claude Audit | `anthropic/claude-3.5-sonnet` | Senior Risk Auditor (HAK VETO penuh) | 0.2 |
| QwenCoder | `qwen/qwen-2.5-coder-32b-instruct` | Script Generator (Python/Pine) | 0.2 |
| Claude Code | `anthropic/claude-3.5-sonnet` | Final Optimizer & Executor (Ruflo) | 0.1 |

**Pipelines:** `pipeline_copytrade`, `pipeline_robotrade`, `pipeline_whale` — semuanya menggunakan urutan yang sama.

---

## 2. Capital Allocation

| Parameter | Value |
|-----------|-------|
| Total Capital | **$300 USD** |
| Liquid Trading | 70% ($210) |
| Staking | 20% ($60) |
| Farming | 10% ($30) |

**Trading Split ($210):**
- Safe Anchor (Funding Rate Arb): 50% ($105)
- Swing Momentum (Grid 2x): 30% ($63)
- Aggressive Growth (idle): 20% ($42)

---

## 3. Bot Strategy Key Parameters

| Bot | Capital | Leverage | SL | TP | Notes |
|-----|---------|----------|----|----|-------|
| futures_bot | - | 5x | 0.4% | 1.0% | Multi-TF scalper, MACD + EMA |
| dev_bot | $50 | 5x | 0.4% | 1.0% | BTC scalping, RSI(14) + EMA(7,25) |
| arbitrage_bot | - | - | 0.4% | 1.5% | Funding rate + spread |
| whale_bot | $100 | 10x | 0.5% | 1.5% | Min whale $5k, RSI + trend filter |
| copytrade_bot | $90 | - | 0.5% | 1.5% | Top 3 traders, score >= 7 |
| copytrade_combo | $100 | - | 0.5% | 1.5% | Voting, RSI/EMA fallback |
| whale_dev_combo | $200 | - | - | - | 50% whale + 30% arb + 20% dev |
| super_combo_bot | $240 | - | - | - | 6 engines orchestrasi |
| mega_combo_bot | $400 | - | - | - | 9 engines (tercerdas) |
| meme_tracker | $100 | - | 0.15% | 0.3/1.5/5% | 3-tier TP, RSI 35/75 |
| prelisting_meme | $20 | - | 0.5% | 15% | Max hold 30 min |
| staking_bot | $30 | - | - | - | Multi-asset (USDT/BTC/ETH/SOL/DOT) |

---

## 4. AI Trading Controller

| Parameter | Value |
|-----------|-------|
| Enabled | true |
| Check Interval | 15 sec |
| Symbols | BTC, ETH, SOL, BNB, XRP, DOGE, ADA, LINK, DOT, MATIC |
| Capital/Trade | $100 |
| Max Positions | 15 |
| Leverage | 50x |
| Stop Loss | 0.5% |
| Take Profit | 2.0% |
| Auto TP Target | $10 Unrealized PnL |

---

## 5. Guardian & Safety

| Parameter | Value | Fungsi |
|-----------|-------|--------|
| Check Interval | 30s | Monitor bot health |
| Log Stale Threshold | 120s | Detect stuck bots |
| Max Restarts/Hour | 3 | Prevent restart loops |
| Error Spike Threshold | 10 | Trigger alarm |
| Telegram Alert | enabled | Notifikasi error |
| Kill Switch Password | `JAGRATAM_RESET` | Reset darurat |

---

## 6. Wallet Tracking (Whale)

| Wallet | Address | Trust Score |
|--------|---------|-------------|
| Whale_Alpha_1 | `0x85ecf584f25db6b6ef62f47d79e487bf96b2f1d5` | 9/10 |
| Whale_Beta_2 | `0x87f9cd15f5050aeb47e69ba275fbff047404344f` | 8/10 |
| Whale_Gamma_3 | `0x399965e15d4e61e7bda36b0a3d891a1c3b20a768` | 7/10 |

---

## 7. Environment Variables (Required)

| Variable | Source | Required For |
|----------|--------|-------------|
| `BINGX_SPOT_API_KEY` + SECRET | BingX | Spot trading |
| `BINGX_FUTURES_API_KEY` + SECRET | BingX | Futures trading |
| `BINGX_TRANSFER_API_KEY` + SECRET | BingX | Transfer assets |
| `OPENROUTER_API_KEY` | openrouter.ai | All AI agents |
| `WHALE_ALERT_API_KEY` | whale-alert.io | Whale tracking |
| `ETHERSCAN_API_KEY` | etherscan.io | On-chain data |
| `TELEGRAM_BOT_TOKEN` + CHAT_ID | @BotFather | Notifications |

**Mode:** `BINGX_VST_MODE=true` = VST Demo ($100 virtual) | `false` = LIVE

---

---

## 8. BingX Feature Coverage — Robot Mapping

> **Sumber:** `PERBAIKAN ROBOT.docx` — Semua fitur BingX yang sudah / akan dirobotkan

### ✅ Sudah Terrobot

| Fitur BingX | Bot / Workflow | Status |
|-------------|----------------|--------|
| **Futures Perpetual** | `futures_bot`, `dev_bot` | ✅ Active — Scalping Multi-TF |
| **Spot Trading** | `spot_bot` | ✅ Active — DCA Cerdas |
| **Copy Trading (Futures)** | `copytrade_bot`, `copytrade_combo` | ✅ Active — AI Filtered |
| **Copy Trading (Spot)** | `copytrade_bot` | ✅ Active — Spot copy |
| **Futures Grid** | `swing_momentum_strategy` (allocation.json) | ✅ Tercover — Grid 2x Leverage |
| **Lending (Simple Earn)** | `staking_bot` | ✅ Active — Multi-asset staking |
| **Price Analysis** | `trading.yml` → analyze job | ✅ Active — Market analysis |

### 🚧 Dalam Pengembangan / Rencana

| Fitur BingX | Rencana Implementasi | Prioritas |
|-------------|---------------------|-----------|
| **Spot Infinity Grid** | Bot dedicated `infinity_grid_bot` | 🟡 Medium |
| **Martingale (Spot/Futures)** | Modul `martingale_strategy` di strategy_config | 🟡 Medium |
| **Signal Strategy** | Integrasi TradingView webhook → `trading.yml` | 🟢 High |
| **Elite Trader** | Filter lanjutan + scoring dari leaderboard BingX | 🟢 High |
| **Shark Fin** | Bot structured product `shark_fin_bot` | 🔴 Low |
| **Dual Investment** | Bot `dual_investment_bot` — auto-rollover | 🔴 Low |
| **P2P Trading** | Monitor spread P2P → arbitrage bot | 🟡 Medium |
| **Affiliate Program** | Tracking referral + komisi | 🔴 Low |
| **Currency Converter** | API endpoint via Redis | 🔴 Low |

### 🔗 Mapping Workflow vs Bot

```
trading.yml (GitHub Actions)          Lokal (JAGRATAM-FIXED)
├── analyze       ←                  ├── futures_bot / spot_bot
├── alice         ← OpenAlice        ├── arbitrage_bot
├── trade         ←                  ├── whale_bot / copytrade_bot
├── backtest      ←                  ├── dev_bot (scalping)
├── train         ← ML training      ├── meme_sniper / meme_tracker
├── report        ← PDF report       ├── staking_bot / farming_bot
└── security-scan ←                  └── mega_combo / super_combo
```

---

*Generated: 2026-06-28*
