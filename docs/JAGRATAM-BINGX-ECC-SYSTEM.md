# JAGRATAM-BINGX | Everything Claude Code (ECC) Engine — by Affaan Mustafa

## SYSTEM PROFILE (RTK ENG)
ECC v2.0.0 | 262 Skills | 64 Sub-Agents | 84 Commands | Cross-harness: Claude Code, Codex, Cursor, OpenCode, Gemini
Pipeline: [Perplexity + Telegram Intel+Hyperliquid] -> Mirofish -> DeepSeek -> ClaudeSonnet -> QwenCoder -> Codex
* THROTTLE CONFIG: MAX 3 BOTS ACTIVE PARALLEL | GC_INTERVAL: 30s *

## ECC SKILLS TERINSTAL
- **jagratam-security-review** — Keamanan trading bot (API keys, kill switch, drawdown, input validation)
- **jagratam-verification-loop** — 6-fase testing pipeline (env, market, trade, risk, bots, report)
- **jagratam-coding-standards** — Standarisasi kode Python/TypeScript untuk semua bot
- **jagratam-api-connector** — Builder konektor API exchange

## LIVE MEMORY CONSTRAINTS (ERR-FIX FORMAT)
- [ERR] CPU_OVERLOAD -> [FIX] py scripts/master_runner.py --throttle 15
- [ERR] RAM_LEAK -> [FIX] Execute ECC memory-optimization skill (sys.gc() + cache clear)
- [ERR] SYSTEM_LAG -> [FIX] Change ACTIVE status to 3 primary bots only (Whale, Arb, Copy)

# JAGRATAM PRO V4.2 — ARSITEKTUR BOT SUPER AGRESIF (RTK)

## 🎯 STRATEGI UTAMA: "THE $10 PROFIT HARVESTER"
Sistem ini dirancang untuk memaksimalkan frekuensi profit dan meminimalkan resiko floating loss yang berkepanjangan dengan aturan baku:
1.  **Target Profit:** Setiap kali **Unrealized PnL** gabungan mencapai **$10**, sistem memicu mode "Harvest".
2.  **Surgical Exit:** Sistem HANYA menutup posisi yang sedang profit. Posisi yang sedang rugi (floating loss) **DIBIARKAN** tetap terbuka untuk menunggu pembalikan harga (recovery).
3.  **Auto-Withdrawal:** Profit bersih $10 langsung dipindahkan ke **Wallet Balance (Spot)** untuk diamankan dari margin call atau drawdown lebih lanjut.
4.  **Instant Re-Order:** Setelah profit diamankan, bot segera mencari peluang baru untuk melakukan **OPEN ORDER** tanpa jeda.

## 🤖 STATUS BOT SAAT INI (18 ACTIVE BOTS)
Masing-masing bot bekerja secara paralel dan menyetor ke target gabungan $10:

### ⚡ Trading Active (High Frequency)
- **futures_bot:** Scalping agresif Multi-TF dengan trailing stop.
- **arbitrage_bot:** Memanen funding rate dan spread antar pair secara cepat.
- **dev_bot:** Scalping BTC khusus dengan leverage 5x (Super Agresif).
- **spot_bot:** DCA Cerdas untuk aset blue-chip.

### 🐋 Whale & CopyTrade (Smart Money)
- **whale_bot:** Mengikuti pergerakan dompet besar (Inflow/Outflow).
- **copytrade_bot:** AI-Filtered Copy Trade (Mencuplik 3 trader terbaik BingX).
- **copytrade_combo:** Voting strategi dari 3 master trader.
- **whale_copytrade_bot:** Mengikuti order spesifik dari Whale yang terdeteksi.

### 💎 Meme & Prelisting (High Reward)
- **meme_sniper_bot (New & Old):** Mendeteksi koin micin baru sebelum pump besar.
- **meme_tracker_bot:** Mengikuti momentum koin yang sedang viral (PEPE, SHIB, DOGE).
- **prelisting_meme_bot:** Sniper koin yang akan segera listing di exchange besar.

### 🔗 Combo Engines (Multi-Strategy)
- **whale_dev_combo_bot:** Gabungan sinyal Whale + Dev Scalping.
- **super_combo_bot:** 6 mesin trading bekerja dalam satu orkestrasi.
- **mega_combo_bot:** Mesin tercerdas JAGRATAM (9 engine) dengan modal $400.
- **hybrid_bot:** Menyeimbangkan resiko antara Spot dan Futures secara dinamis.

### 💰 Passive Earn (Stable Yield)
- **staking_bot:** Mengunci aset untuk APY optimal.
- **farming_bot:** Memanen yield dari liquidity pool.
- **mining_bot:** Simulasi/Real mining dengan auto-compound 100%.

## 🛠️ KONFIGURASI SUPER JENIUS (RTK)
- **Profit Taker:** `core/auto_profit.py` → Target $10, Interval 10s.
- **API Limiter:** 10 requests / 10 detik (Mencegah Ban API BingX).
- **AI Orchestrator:** Kontrol hirarki dari Perplexity (Riset) hingga Ruflo (Eksekusi).

## 🚀 CARA MENJALANKAN (MODE SUPER AGRESIF)
```bash
# 1. Pastikan saldo VST/Live tersedia (> $100 disarankan)
# 2. Jalankan Master Runner
./jalankan-semua.ps1
# 3. Monitor PnL Target di auto_profit.log
tail -f logs/auto_profit.log
```

**FILOSOFI:** *"Lebih baik profit $10 seratus kali sehari daripada menunggu profit $1000 yang tidak kunjung datang."*

---

### 📚 Referensi Terkait

| Dokumen | Isi |
|---------|-----|
| [CONFIG-REFERENCE.md](CONFIG-REFERENCE.md) | Detail konfigurasi: AI pipeline, capital allocation, bot parameters, env vars, BingX feature mapping |
| [ARCHITECTURE_ANALYSIS.md](../ARCHITECTURE_ANALYSIS.md) | Analisis arsitektur RAM 2GB, mode operasi hybrid |
| [CI_CD_ANALYSIS.md](../CI_CD_ANALYSIS.md) | CI/CD pipeline untuk trading dengan GitHub Actions |
| [trading.yml](../.github/workflows/trading.yml) | GitHub Actions workflow — 8 jobs: analyze, trade, alice, backtest, dll |
