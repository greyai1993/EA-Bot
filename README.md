# XAUUSD Multi-Strategy EA v1

## Project Overview

**Project Type:** Research/Backtest Framework (NOT production money bot)  
**Goal:** Validate strategy edge through data before deploying live  
**Symbol:** XAUUSD (Gold)  
**Timeframes:** M15 (entry) + H1 (trend)  
**Broker:** Exness Vietnam  

## Quick Start

1. **Read Documentation:**
   - `docs/PROJECT_BRIEF.md` - Full context and strategy overview
   - `docs/TECHNICAL_SPEC.md` - Detailed technical specifications
   - `docs/BACKTEST_PROTOCOL.md` - Testing methodology
   - `docs/PARAMETER_REFERENCE.md` - All input parameters

2. **Development Workflow:**
   - Phase 1: Build EA framework (Week 1-2)
   - Phase 2: Backtest 4 variants 2020-2024 (Week 3)
   - Phase 3: Forward test demo (Week 4-7)
   - Phase 4: Live micro deployment (Week 8+)

3. **Critical Reminders:**
   - Default trading mode: `MODE_ALERTS_ONLY` (no real trades until validated)
   - Anti-overfitting: Train 2020-2023, validate 2024
   - Pass criteria: WR >45%, PF >1.3, DD <25%, Sharpe >0.5
   - If all 4 variants fail backtest → STOP project

## Repository Structure

```
EA-Bot/
├── README.md                          # This file
├── docs/
│   ├── PROJECT_BRIEF.md              # Full context & mindset
│   ├── TECHNICAL_SPEC.md             # Code specifications
│   ├── BACKTEST_PROTOCOL.md          # Testing guide
│   └── PARAMETER_REFERENCE.md        # All Inp* variables
├── src/
│   ├── TrendPullbackEA_v1.mq5       # Main EA (to be built)
│   └── include/
│       ├── RiskManager.mqh           # (to be built)
│       ├── StrategyVariants.mqh      # (to be built)
│       ├── CircuitBreaker.mqh        # (to be built)
│       └── Logger.mqh                # (to be built)
└── tests/
    └── backtest_reports/             # Backtest results storage
```

## Strategy Variants

This EA tests 4 automated strategy variants:

- **Variant A:** Pure EMA Pullback (baseline)
- **Variant B:** EMA + Supply/Demand Proxy
- **Variant C:** EMA + Trendline Proxy
- **Variant D:** Full Hybrid (all filters combined)

## Success Criteria

### Phase 1: Backtest (Week 1-3)
✅ At least 1 variant must achieve:
- Win rate >45%
- Profit Factor >1.3
- Max Drawdown <25%
- Sharpe ratio >0.5
- Minimum 150 trades

### Phase 2: Demo Forward (Week 4-7)
✅ Match backtest metrics ±15%
✅ Max DD <20%
✅ Stable monthly returns

### Phase 3: Live Micro (Week 8+)
✅ +3-8%/month sustained for 3 months
✅ Max DD <15%

## Important Notes

⚠️ **This is a research framework, NOT a money-making bot**
- Phase 1 focuses on validating edge through historical data
- Only enable auto-trading after passing rigorous backtests
- Default mode is ALERTS_ONLY for safety

⚠️ **Anti-Overfitting Measures**
- Use round numbers for parameters (EMA 20/50/200)
- Train/validation split: 2020-2023 train, 2024 validate
- Minimum 150 trades required for statistical significance
- Strategy must be stable across all years

⚠️ **Capital Plan**
- Demo: $10,000 (Exness demo account)
- Live pilot: $100 (execution smoke test only)
- Live micro: $500-1K (minimum viable for proper lot sizing)
- Scale gradually: $1K → $2K → $5K → $10K based on performance

## Contact & Support

For questions or issues, refer to the detailed documentation in the `docs/` folder.

---

**Built with:** MetaTrader 5 MQL5  
**Last Updated:** 2026-05-12
