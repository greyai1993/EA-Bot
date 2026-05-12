# MT5 EXPERT ADVISOR - PROJECT BRIEF

## Executive Summary

**Project Name:** XAUUSD Multi-Strategy EA v1  
**Project Type:** Research/Backtest Framework  
**Primary Goal:** Validate trading strategy edge through rigorous data analysis before live deployment  
**Timeline:** 6-8 weeks  
**Target Performance:** 5-10% monthly return (after validation)  

---

## 1. MINDSET RESET (CRITICAL)

### ❌ What This Project is NOT:
- NOT a "get rich quick" money-making bot
- NOT a production-ready system on day 1
- NOT promising 1-5% daily returns
- NOT trading with real money until fully validated

### ✅ What This Project IS:
- A **research framework** to find and validate trading edge
- A **systematic approach** to test multiple strategy variants
- A **data-driven process** with clear pass/fail criteria
- A **foundation** for future live trading (only if validation succeeds)

### Philosophy:
**"Prove the edge first, trade second"**

No manual trading history → No world-class trader data → Must create evidence through:
- Historical backtesting (2020-2024)
- Walk-forward analysis
- Out-of-sample testing
- Demo forward testing (1 month minimum)

Only after passing ALL validation phases do we consider live micro deployment.

---

## 2. BUSINESS CONTEXT

### Capital Plan

| Phase | Account Type | Capital | Purpose |
|-------|-------------|---------|---------|
| Phase 1 | Demo | $10,000 | Backtest validation |
| Phase 2 | Demo | $10,000 | Forward test (1 month) |
| Phase 3 | Live Pilot | $100 | Execution smoke test only |
| Phase 4 | Live Micro | $500-1K | Performance validation |
| Phase 5+ | Live Scale | $2K→$5K→$10K | Gradual scaling based on results |

**Important Notes:**
- $100 live account is NOT for performance validation (lot sizing limitations)
- $100 only tests: Can bot place orders? Are logs correct? Do guards work?
- Minimum $500-1K required for proper risk management with XAUUSD lot sizes

### Success Criteria by Phase

#### Phase 1: Backtest (Week 1-3)
**Pass Criteria:**
- ✅ At least 1 of 4 variants achieves:
  - Win Rate >45%
  - Profit Factor >1.3
  - Max Drawdown <25%
  - Sharpe Ratio >0.5
  - Minimum 150 trades (statistical significance)
  - Stable performance across 2020-2024 (no single-year outlier)

**Fail Criteria:**
- ❌ If ALL 4 variants fail → **STOP PROJECT** (strategy has no edge)

#### Phase 2: Demo Forward (Week 4-7)
**Pass Criteria:**
- ✅ Top variant from backtest matches metrics ±15% in demo
- ✅ Max DD <20%
- ✅ No technical failures (reconnections, order rejections)
- ✅ Stable monthly returns (no wild spikes)

**Fail Criteria:**
- ❌ Large deviation from backtest → Strategy overfit or market regime changed

#### Phase 3: Live Micro (Week 8+)
**Pass Criteria:**
- ✅ +3-8% monthly return sustained for 3 months
- ✅ Max DD <15%
- ✅ Slippage/spread within tolerance
- ✅ No blow-up events

**Scale Trigger:**
- After 3 consecutive profitable months → Scale to $2K
- After 6 months stability → Scale to $5K
- After 12 months → Scale to $10K+

### Broker & Setup

- **Broker:** Exness Vietnam
- **Symbol:** XAUUSD (Gold spot CFD)
- **Typical Spread:** 15-25 pips
- **Leverage:** 1:500 (typical retail)
- **Session Preference:** London + NY (highest liquidity, to be validated in backtest)
- **VPS:** TBD (low latency Singapore/HK preferred)

### Target Performance (Realistic)

| Metric | Conservative | Aggressive | Unrealistic |
|--------|--------------|-----------|-------------|
| Monthly Return | 3-5% | 8-12% | 20%+ (1%/day) |
| Win Rate | 40-50% | 50-60% | 70%+ |
| Profit Factor | 1.2-1.5 | 1.5-2.0 | 3.0+ |
| Max DD | 15-20% | 10-15% | <5% |

**Note:** This is a trend pullback strategy on M15/H1, NOT scalping.
- Expected trade frequency: 1-3 trades/day
- Expected avg hold time: 4-12 hours
- Cannot support 1-5%/day targets (that requires high-frequency scalping)

---

## 3. STRATEGY ARCHITECTURE

### Core Approach: Multi-Variant Testing

**Philosophy:** Instead of betting on one configuration, test 4 variants simultaneously to increase probability of finding edge.

### The 4 Strategy Variants

#### Variant A: Pure EMA Pullback (Baseline)
**Concept:** Classic trend-following with pullback entry

**Logic:**
```
TREND IDENTIFICATION (H1):
- Uptrend: Price > EMA200 AND EMA50 > EMA200
- Downtrend: Price < EMA200 AND EMA50 < EMA200

ENTRY SIGNAL (M15):
- Wait for pullback to EMA20 or EMA50
- Candle confirmation: close back above EMA20 (long) / below EMA20 (short)
- RSI confirmation: RSI crosses up through 35 (long) / down through 65 (short)
- ADX filter: ADX > 20 (ensure trending, not ranging)

EXIT:
- SL: 2× ATR(14, H1)
- TP: 3× ATR(14, H1) → Risk:Reward = 1:1.5
- Trailing: Breakeven at +1.5 ATR profit, then trail by 1× ATR
```

**Pros:** Simple, established methodology  
**Cons:** May have many false signals in choppy markets

---

#### Variant B: EMA + Supply/Demand Proxy
**Concept:** Add institutional S&D zone filter to reduce false entries

**S&D Zone Detection (Automated Proxy):**
```
DEMAND ZONE:
- Swing low from last 30 bars
- Price rejected (touched & reversed up) 2+ times
- Buffer: ±10 pips tolerance

SUPPLY ZONE:
- Swing high from last 30 bars
- Price rejected (touched & reversed down) 2+ times
- Buffer: ±10 pips tolerance

ENTRY RULE:
- Take Variant A signal ONLY IF:
  - Long: Price within ±15 pips of demand zone
  - Short: Price within ±15 pips of supply zone
```

**Pros:** Filters out entries not near key levels  
**Cons:** May reduce trade frequency significantly

---

#### Variant C: EMA + Trendline Proxy
**Concept:** Add trendline break & retest confirmation

**Trendline Detection (Automated Proxy):**
```
UPTREND LINE:
- Last 3 swing lows ascending (each > previous)
- Swing lookback: 7 bars

DOWNTREND LINE:
- Last 3 swing highs descending (each < previous)

ENTRY RULE:
- Take Variant A signal ONLY IF:
  - Price broke & retested trendline within last 10 bars
  - Retest tolerance: ±15 pips from trendline
```

**Pros:** Catches momentum shift plays  
**Cons:** Trendline proxy may not match human-drawn lines

---

#### Variant D: Full Hybrid
**Concept:** Combine ALL filters (EMA + S&D + Trendline + RSI + ADX)

**Entry Requirement:**
```
ALL of the following must be true:
- Variant A base signal (EMA pullback + RSI + ADX)
- Price near S&D zone (Variant B filter)
- Recent trendline break/retest (Variant C filter)
```

**Pros:** Ultra-high-quality setups only  
**Cons:** May have too few trades (over-filtered) → insufficient data

**Expected Outcome:** Variant D will either:
- Pass with very high win rate (60%+) and PF (1.8+) BUT low trade count
- OR fail due to insufficient trades for statistical significance

---

## 4. RISK MANAGEMENT (Universal Across All Variants)

### Position Sizing
```
Risk per trade: 0.25% equity (conservative for v1)
Formula: LotSize = (Equity × 0.0025) / (SL_pips × PipValue)

Max open positions: 1 (no grid, no martingale, no hedging)
Max trades per day: 3
```

### Daily/Weekly Caps
```
Daily loss cap: -1.5% equity → Stop trading today, resume tomorrow
Weekly loss cap: -4% equity → Stop trading this week
Max consecutive losses: 3 → Pause EA, require manual review
```

### Equity Drawdown Protection
```
Max equity DD: 12%
Action: If floating + closed DD hits 12% → Close all positions, pause EA, Telegram alert
```

### No Martingale / No Grid
**Strictly prohibited:**
- Averaging down
- Doubling lot size after loss
- Grid trading
- Hedging
- Revenge trading (re-entry immediately after loss)

---

## 5. EXECUTION GUARDS & CIRCUIT BREAKER

### Spread Filter
```
Max spread: 30 pips (XAUUSD Exness typical: 15-25 pips)
Action: Skip entry if spread > 30 pips
```

### Slippage Control
```
Max slippage: 10 pips
Action: Reject order if slippage exceeds limit
```

### Margin Guard
```
Min free margin: 200% of used margin
Formula: (FreeMargin / UsedMargin × 100) ≥ 200%
Action: Skip entry if insufficient margin buffer
```

### Friday Auto-Close
```
Logic: Close all positions Friday 22:00 GMT
Reason: Avoid weekend gap risk
Config: Optional ON/OFF parameter
```

### Volatility Circuit Breaker (Risk Control)
**Purpose:** Auto-pause during market shocks (news events, flash crashes)

**Trigger Conditions:**
```
1. ATR Spike: Current ATR(14, M15) > 3× median ATR(50 bars)
   OR
2. Spread Spike: Spread > 50 pips
   OR
3. Gap Detection: Price gap > 2× ATR (post-weekend/news)
```

**Actions:**
```
- Pause new entries for 30 minutes
- Keep existing positions running with trailing stop
- Telegram alert: "⚠️ VOLATILITY PAUSE: ATR spike detected"
- Log: timestamp, ATR value, reason
```

**Why Not News Filter?**
- News calendar APIs are complex and unreliable
- Volatility spike detection is real-time and catches ALL abnormal events
- Can be backtested (ATR data available historically)

---

## 6. TRADING MODES (CRITICAL SAFETY FEATURE)

### Three Modes:

```mql5
input ENUM_TRADING_MODE InpTradingMode = MODE_ALERTS_ONLY;

Options:
- MODE_ALERTS_ONLY (DEFAULT): Signal detection + logging only, NO real trades
- MODE_AUTO_TRADE: Auto-execute trades (enable only after validation)
- MODE_PAUSED: Stop all activity
```

### Mode Usage by Phase:

| Phase | Mode | Purpose |
|-------|------|---------|
| Phase 1 (Backtest) | ALERTS_ONLY | Verify signal logic, log analysis |
| Phase 2 (Demo Forward) | AUTO_TRADE | Test execution on demo |
| Phase 3 (Live Pilot $100) | AUTO_TRADE | Execution smoke test |
| Phase 4 (Live Micro) | AUTO_TRADE | Performance validation |

**Safety Rule:** Default is ALWAYS `MODE_ALERTS_ONLY` to prevent accidental live trading.

---

## 7. SESSION FILTER STRATEGY

### Phase 1 Approach: Trade ALL Sessions
**Reason:** Gather baseline data to identify which sessions are profitable

### Phase 2 Optimization:
Analyze backtest results by session:
```
Sessions (GMT+7 timezone):
- Asian: 00:00-08:00
- London: 14:00-23:00
- NY: 19:00-04:00
- Overlap (London+NY): 19:00-23:00 (peak liquidity)
```

**Decision Logic:**
- If Asian session has negative expectancy → Disable in Phase 2
- If Overlap has best metrics → Focus only on Overlap hours

**Exness Vietnam Context:**
- Most retail XAUUSD traders focus on London + NY sessions
- EA should have option to filter by session, but test ALL first

---

## 8. ANTI-OVERFITTING PROTOCOL

### The Overfitting Problem:
**Scenario:** Backtest shows 70% WR, 2.5 PF → Demo shows 35% WR, 0.8 PF  
**Cause:** Parameters optimized to fit historical data perfectly, but no predictive power

### Our Anti-Overfitting Measures:

#### 1. Data Split (Walk-Forward)
```
Train/Research: 2020-2023 (3.5 years)
Validation: 2024 (1 year - unseen data)
Out-of-Sample: 2025-current (if available)
```

**Rule:** Parameters tuned on 2020-2023 ONLY. If fails on 2024 → Overfit.

#### 2. Use Round Numbers
```
✅ Good: EMA(20, 50, 200), RSI(14), ADX(20), ATR(14)
❌ Bad: EMA(23, 49, 197), RSI(13.5), ADX(21.7)

Reason: Hyper-optimized decimals = curve-fit to noise
```

#### 3. Minimum Trade Count
```
Minimum 150 trades required for statistical significance
If variant produces <150 trades in 4 years → Not testable
```

#### 4. Stability Across Years
```
Backtest must show positive expectancy in MOST years

Example Good:
2020: +15%
2021: +8%
2022: -3%
2023: +12%
2024: +10%
→ One bad year acceptable

Example Bad (Overfit):
2020: -5%
2021: +2%
2022: +80% ← Suspect
2023: -8%
2024: +1%
→ Single-year outlier = likely curve-fit
```

#### 5. Don't Over-Optimize
```
❌ Don't test 1000 parameter combinations
✅ Test 4 pre-defined variants with sensible defaults
```

#### 6. Reject Perfect Results
```
If backtest shows:
- 100% win rate
- 0% drawdown
- Profit factor > 5

→ Likely bug or extreme curve-fit, NOT real edge
```

---

## 9. DELIVERABLES

### Phase 1: Code + Documentation

**Code Artifacts:**
1. `src/TrendPullbackEA_v1.mq5` - Main EA (~2000-3000 lines)
2. `src/include/RiskManager.mqh` - Position sizing & DD tracking
3. `src/include/StrategyVariants.mqh` - 4 variant logic modules
4. `src/include/CircuitBreaker.mqh` - Volatility pause system
5. `src/include/Logger.mqh` - CSV + journal logging

**Documentation:**
1. `docs/TECHNICAL_SPEC.md` - Full code specifications
2. `docs/BACKTEST_PROTOCOL.md` - Testing methodology
3. `docs/PARAMETER_REFERENCE.md` - All 100+ input parameters explained
4. `README.md` - Quick start guide

### Phase 2: Backtest Results

**Research Package:**
1. **Trade Log CSV** (per variant):
   ```csv
   timestamp,variant,signal_reason,entry,SL,TP,R_multiple,exit_reason,profit,balance
   2020-01-05 10:30,A,EMA_PULLBACK_RSI_ADX,1950.50,1945.00,1958.50,1.5,TP_HIT,+75.00,10075.00
   ```

2. **Metrics Comparison Table:**
   | Variant | WR | PF | Max DD | Sharpe | Trades | Avg R |
   |---------|----|----|--------|--------|--------|-------|
   | A | 48% | 1.4 | 18% | 0.65 | 287 | 0.42 |
   | B | 52% | 1.6 | 15% | 0.82 | 143 | 0.68 |
   | C | 45% | 1.3 | 22% | 0.51 | 201 | 0.35 |
   | D | 58% | 1.9 | 12% | 1.05 | 67 | 0.95 |

3. **Equity Curves** (4 charts comparing variants)

4. **Monthly Return Heatmap** (2020-2024)

5. **Parameter Sheet** (exact config tested for each variant)

---

## 10. KNOWN RISKS & MITIGATIONS

### Risk 1: Backtest Overfitting
**Symptom:** Backtest pass, demo/live fail  
**Mitigation:**
- Long backtest period (4 years)
- Round number parameters
- Walk-forward validation (2024 unseen)
- 1 month demo minimum

### Risk 2: Execution Costs Worse Than Expected
**Symptom:** Live results worse due to spread/slippage  
**Mitigation:**
- Use realistic 20-pip spread in backtest
- Monitor actual costs in demo
- Spread/slippage guards in code

### Risk 3: Low Trade Frequency (Variant D)
**Symptom:** Over-filtered, no trades for weeks  
**Mitigation:**
- Test 4 variants, accept Variant D may fail
- Focus on A/B/C if D too slow

### Risk 4: News Shock / Flash Crash
**Symptom:** Slippage spike, spread widening, blow account  
**Mitigation:**
- Volatility circuit breaker (ATR 3× median)
- Max DD 12% hard stop
- Friday auto-close

### Risk 5: No Edge Found
**Symptom:** All 4 variants fail backtest  
**Action:** **STOP PROJECT** - Don't force it, accept strategy has no edge on XAUUSD

---

## 11. TIMELINE & WORKFLOW

```
Week 1-2: Build EA Framework
- Code 4 strategy variants
- Implement risk management
- Build circuit breaker
- CSV logging system

Week 3: Backtest All Variants
- Run 2020-2024 backtests (4 runs)
- Export trade logs
- Compare metrics
- Pick top 1-2 variants

Week 4-7: Forward Test Demo ($10K)
- Deploy best variant(s) on demo
- Monitor daily: trades, DD, alerts
- Compare to backtest metrics

Week 8: Live Pilot ($100)
- Execution smoke test only
- Verify: orders placed correctly, logs work, guards trigger

Week 9+: Live Micro ($500-1K)
- Deploy if demo passed
- Monitor 3 months minimum
- Scale gradually if sustained performance

Month 4-6: Scale Capital
- $2K → $5K → $10K based on results
```

---

## 12. FINAL CHECKLIST BEFORE BUILD

- [x] Mindset reset: This is research, not money bot
- [x] 4 strategy variants defined with explicit rules
- [x] Risk management: 0.25%/trade, 1.5% daily cap, 4% weekly cap
- [x] Execution guards: spread, slippage, margin, Friday close
- [x] Circuit breaker: ATR spike + spread spike + gap detection
- [x] Trading modes: ALERTS_ONLY (default) / AUTO_TRADE / PAUSED
- [x] Anti-overfitting: 2020-2023 train, 2024 validate, round numbers
- [x] Pass criteria: WR >45%, PF >1.3, DD <25%, Sharpe >0.5, min 150 trades
- [x] Fail criteria: All 4 variants fail → STOP project
- [x] Capital plan: Demo $10K → Live pilot $100 → Live micro $500-1K → Scale
- [x] CSV logging with reason codes mandatory
- [x] Backtest protocol documented
- [x] All 100+ input parameters defined

---

## READY TO BUILD

This brief provides complete context for EA development. Next step: Refer to `TECHNICAL_SPEC.md` for detailed code specifications.

---

**Document Version:** 1.0  
**Last Updated:** 2026-05-12  
**Author:** Violet AI (based on Grey, Tinh Tu, Ray requirements)
