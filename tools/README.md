# EA-Bot Tools

Automation scripts for compiling, backtesting, and deploying TrendPullbackEA_v1.

## Prerequisites (one-time)

1. **MT5 installed** at `C:\Program Files\MetaTrader 5\`.
2. **Logged into broker** (currently: Exness-MT5Trial17, account 270400992).
3. **History downloaded** for `XAUUSDm` M15+H1 covering your backtest range. Strategy Tester reads from local cache only — it won't download on demand. To preload:
   - Open MT5 → `Ctrl+M` to show Market Watch → right-click → Show All
   - Find `XAUUSDm` → right-click → Chart Window
   - Switch to M15 → press `Home` → wait for "Waiting for update" to clear
   - Repeat for H1
   - Close MT5

   Verify with: `.\check_history.ps1`

## Scripts

### `run_backtest_all.ps1`
Compiles EA, generates 4 `.ini` configs, runs Strategy Tester for each variant, collects HTML reports + CSV trade logs.

```powershell
# Full run: 4 variants x 2020-2024, real ticks (~1-2h)
.\run_backtest_all.ps1

# Smoke test: VARIANT_A only, 2024H1 (~10 min)
.\run_backtest_all.ps1 -SmokeTest

# Custom range / quality
.\run_backtest_all.ps1 -FromDate 2023.01.01 -ToDate 2024.12.31 -Model 1
```

**Important**: MT5 must be CLOSED before running — Strategy Tester needs sole control of `terminal64.exe`.

Outputs go to `..\tests\backtest_reports\<timestamp>\`:
- `Variant_A.htm` ... `Variant_D.htm` — HTML report from tester
- `Variant_A.ini` ... `Variant_D.ini` — config used (for reproducibility)
- `Variant*_*.csv` — trade logs from EA's Logger module
- `summary.txt` — run summary

### `check_history.ps1`
Verifies XAUUSDm history is loaded for the target backtest range.

```powershell
.\check_history.ps1                           # checks 2020-2026
.\check_history.ps1 -FromYear 2023            # custom range
```

## Strategy Tester model values

| Model | Speed | Quality |
|-------|-------|---------|
| 0 (Every tick, generated) | slow | medium |
| 1 (1 minute OHLC) | fast | low-medium |
| 2 (Open prices only) | fastest | low (debug only) |
| 4 (Every tick based on real ticks) | slowest | highest (default) |
