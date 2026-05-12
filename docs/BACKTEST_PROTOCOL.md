# BACKTEST PROTOCOL - Anti-Overfitting Methodology

## Table of Contents
1. [Overview](#overview)
2. [Data Requirements](#data-requirements)
3. [Walk-Forward Analysis](#walk-forward-analysis)
4. [Backtest Execution Steps](#backtest-execution-steps)
5. [Metrics to Export](#metrics-to-export)
6. [Pass/Fail Criteria](#passfail-criteria)
7. [Red Flags](#red-flags)
8. [Comparison Matrix](#comparison-matrix)

---

## Overview

### Purpose
This backtest protocol prevents overfitting by establishing rigorous data split, parameter discipline, and pass/fail criteria **before** running backtests.

### Philosophy
**"Backtest to discover edge, not to create illusions"**

### The Overfitting Trap
❌ **Bad Practice:**
- Run 1000 parameter combinations
- Pick the best backtest result
- Deploy live → Loses money

✅ **Good Practice:**
- Define 4 sensible variants upfront
- Use round-number parameters
- Train/validate split
- Accept that some variants will fail

---

## Data Requirements

### Symbol & Timeframes
```
Symbol: XAUUSD (Gold spot CFD)
Entry Timeframe: M15
Trend Timeframe: H1
Minimum Data: H1 bars from 2020-01-01 to 2024-12-31 (4 years)
```

### Data Quality Checklist
- [ ] No gaps longer than 1 day (weekends OK)
- [ ] Spread data available (realistic, not 0)
- [ ] No obvious errors (e.g., price = 0.01)
- [ ] Covers multiple market regimes:
  - [ ] 2020: COVID crash + recovery
  - [ ] 2021: Inflation fears
  - [ ] 2022: Fed rate hikes, recession fears
  - [ ] 2023: Banking crisis, soft landing
  - [ ] 2024: Election year volatility

### Broker-Specific Settings
```
Spread: Fixed 20 pips (realistic Exness average)
Commission: 0 (Exness XAUUSD typically no commission on standard accounts)
Swap: Enable (use broker's real swap rates)
Starting capital: $10,000 USD
Leverage: 1:500 (typical retail)
```

---

## Walk-Forward Analysis

### Data Split Strategy

```
┌─────────────────────────────────────────────────────────┐
│                     Total Dataset                       │
│              2020-01-01 to 2024-12-31                  │
└─────────────────────────────────────────────────────────┘
           │                                 │
           ▼                                 ▼
  ┌────────────────────┐         ┌─────────────────┐
  │   TRAIN PERIOD     │         │  VALIDATION     │
  │   2020 - 2023      │         │     2024        │
  │   (3.5 years)      │         │   (1 year)      │
  └────────────────────┘         └─────────────────┘
           │                                 │
           ▼                                 ▼
   Parameters tuned here          Test unseen data
   Variants developed              Must perform here
```

### Rules
1. **All parameter decisions based on 2020-2023 data ONLY**
2. **2024 is "unseen future" - never look at it during development**
3. **Out-of-sample: 2025-current (if available)**

### Why This Works
- Prevents "peeking" at validation data
- Simulates real-world: can't know future
- If strategy fails on 2024 → Overfit to 2020-2023 noise

---

## Backtest Execution Steps

### Phase 1: Setup (Day 1)

#### Step 1: Install MT5 & Download Data
```
1. Open MetaTrader 5
2. Navigate to: Tools → History Center
3. Select: XAUUSD, H1
4. Download: 2020-01-01 to 2024-12-31
5. Verify: No gaps, ~35,000 H1 bars
```

#### Step 2: Compile EA
```
1. Open MetaEditor (F4 in MT5)
2. File → Open: TrendPullbackEA_v1.mq5
3. Compile (F7)
4. Verify: 0 errors, 0 warnings
```

### Phase 2: Run Backtests (Day 2)

#### Variant A Backtest
```
1. Open Strategy Tester (Ctrl+R)
2. Settings:
   - Expert: TrendPullbackEA_v1.ex5
   - Symbol: XAUUSD
   - Period: M15
   - Date: 2020.01.01 - 2024.12.31
   - Modeling: Every tick (most accurate)
   - Optimization: Disabled
   - Forward: Disabled (we do manual walk-forward)
3. Parameters:
   - InpStrategyVariant = VARIANT_A_PURE_EMA
   - InpTradingMode = MODE_AUTO_TRADE
   - All other params = defaults (see PARAMETER_REFERENCE.md)
4. Start → Wait for completion (~10-30 min depending on CPU)
```

#### Repeat for Variants B, C, D
- Only change: `InpStrategyVariant` parameter
- Keep all other params identical

### Phase 3: Export Results (Day 3)

#### For Each Variant:
```
1. Right-click on backtest result
2. Save Report → HTML
3. Save as: Variant_A_2020_2024.html
4. Open report, extract:
   - Total net profit
   - Profit factor
   - Total trades
   - Win rate (%)
   - Max drawdown ($, %)
   - Sharpe ratio
5. Export trade list:
   - Right-click → Export to CSV
   - Save as: Variant_A_trades.csv
```

---

## Metrics to Export

### Primary Metrics (Pass/Fail Decision)

| Metric | Symbol | Formula | Pass Threshold |
|--------|--------|---------|---------------|
| Win Rate | WR | Winning trades / Total trades × 100% | >45% |
| Profit Factor | PF | Gross profit / Gross loss | >1.3 |
| Max Drawdown | DD | (Peak - Trough) / Peak × 100% | <25% |
| Sharpe Ratio | SR | (Avg return - Risk-free rate) / Std dev | >0.5 |
| Total Trades | N | Count of closed trades | >150 |

### Secondary Metrics (Quality Indicators)

| Metric | Purpose | Good Value |
|--------|---------|-----------|
| Average R-multiple | Risk-adjusted return per trade | >0.3 |
| Max consecutive losses | Psychological stress test | <8 |
| Average trade duration | Confirm swing strategy | 4-12 hours |
| Monthly return std dev | Consistency check | <10% |
| Recovery factor | DD / Net profit | >2.0 |

### Monthly Breakdown
Export monthly returns to check:
- [ ] No single month dominates (e.g., +80% in one month, -5% others)
- [ ] Most months positive or near 0
- [ ] No wild swings (±50% in a month)

---

## Pass/Fail Criteria

### Phase 1: Backtest Pass (Any 1 Variant)

**At least 1 of 4 variants must achieve ALL:**

✅ **Minimum Requirements:**
```
Win Rate (WR)           ≥ 45%
Profit Factor (PF)      ≥ 1.3
Max Drawdown (DD)       ≤ 25%
Sharpe Ratio (SR)       ≥ 0.5
Total Trades (N)        ≥ 150
```

✅ **Stability Check:**
```
Strategy must be profitable (or near breakeven) in at least 3 out of 4 years
Example PASS:
  2020: +12%
  2021: +8%
  2022: -2%  ← acceptable
  2023: +15%
  2024: +10%

Example FAIL (single-year wonder):
  2020: -5%
  2021: +2%
  2022: +85%  ← suspicious outlier
  2023: -3%
  2024: +1%
```

### Phase 1: Backtest Fail (ALL Variants Fail)

❌ **STOP PROJECT if:**
- All 4 variants fail minimum requirements
- OR: All variants profitable but driven by 1-2 outlier months
- OR: All variants show extreme curve-fit symptoms (see Red Flags below)

**Action:** Do NOT proceed to demo/live. Strategy has no edge on XAUUSD.

### Phase 2: Validation Pass (2024 Unseen Data)

**Top variant from 2020-2023 must match performance on 2024:**

✅ **Acceptable Degradation:**
```
Win Rate: ±15% absolute
  Example: 2020-2023 WR = 50% → 2024 WR must be 35-65%

Profit Factor: ±30% relative
  Example: 2020-2023 PF = 1.5 → 2024 PF must be 1.05-1.95

Max DD: ±10% absolute
  Example: 2020-2023 DD = 18% → 2024 DD must be <28%
```

❌ **Fail if:**
- 2024 WR < 35% (even if 2020-2023 was 60%)
- 2024 PF < 1.0 (negative expectancy)
- 2024 DD > 35%

**Action:** If fail → Strategy overfit to 2020-2023. Do NOT deploy live.

### Phase 3: Demo Forward Pass (1 Month Real-Time)

**Best variant on demo $10K must:**

✅ **Match Backtest:**
```
Win Rate: within ±15% of backtest
Max DD: within ±10% of backtest
Trade frequency: within ±30% of backtest
No technical issues: reconnections, order rejections, spread rejections must be <5% of attempts
```

❌ **Fail if:**
- Win rate deviates >20% from backtest
- DD >30%
- More than 10% of orders rejected/failed

**Action:** If fail → Backtest not representative of live conditions. Investigate or abandon.

---

## Red Flags (Curve-Fit Symptoms)

### 🚩 Flag 1: Too Perfect
```
Backtest shows:
- Win rate >80%
- Profit factor >4.0
- Max DD <5%
- Sharpe ratio >3.0

Reality: This is statistically improbable for trend-following strategy
Conclusion: Likely bug in code or extreme overfitting
```

### 🚩 Flag 2: Single-Period Dominance
```
Yearly returns:
2020: +2%
2021: -3%
2022: +187%  ← 90%+ of total profit from one year
2023: +5%
2024: -1%

Conclusion: Strategy exploited one unique market condition, won't repeat
```

### 🚩 Flag 3: Hyper-Optimized Parameters
```
EMA periods: 23, 49, 197
RSI threshold: 34.7
ADX min: 19.3
ATR SL: 1.87x

Conclusion: These decimals = fitted to noise. Use round numbers (20, 50, 200, 35, 20, 2.0)
```

### 🚩 Flag 4: Low Trade Count
```
Total trades over 4 years: 37

Conclusion: Insufficient data for statistical significance (need 150+ trades)
Risk: Random luck, not edge
```

### 🚩 Flag 5: Inconsistent Behavior
```
2020-2023 backtest: Avg trade duration = 6 hours
2024 validation: Avg trade duration = 45 minutes

Conclusion: Strategy behaving differently, not robust
```

---

## Comparison Matrix

### Template for 4 Variants

| Metric | Variant A | Variant B | Variant C | Variant D | Pass Threshold |
|--------|-----------|-----------|-----------|-----------|---------------|
| **Win Rate** | 48.2% | 52.1% | 44.8% | 58.7% | >45% ✅ |
| **Profit Factor** | 1.42 | 1.63 | 1.28 | 1.91 | >1.3 ✅ |
| **Max DD** | 18.5% | 15.2% | 22.7% | 11.8% | <25% ✅ |
| **Sharpe Ratio** | 0.68 | 0.85 | 0.52 | 1.12 | >0.5 ✅ |
| **Total Trades** | 287 | 143 | 201 | 67 | >150 ✅ |
| **Avg R-multiple** | 0.42 | 0.68 | 0.31 | 0.95 | - |
| **Net Profit** | $4,230 | $6,150 | $2,890 | $7,820 | - |
| **Max Consec Losses** | 7 | 5 | 9 | 4 | - |
| **2020 Return** | +12.3% | +15.8% | +8.2% | +18.7% | - |
| **2021 Return** | +8.1% | +12.3% | +5.9% | +21.3% | - |
| **2022 Return** | -2.3% | +3.5% | -5.1% | -0.8% | - |
| **2023 Return** | +14.8% | +18.2% | +11.2% | +25.1% | - |
| **2024 Return** | +10.5% | +13.8% | +7.1% | +14.2% | - |
| **PASS/FAIL** | ✅ PASS | ✅ PASS | ✅ PASS | ⚠️ Low N | - |

### Decision Matrix

```
Variant A: PASS (solid baseline, good trade count)
Variant B: PASS (best balance: high PF, low DD, decent trade count)
Variant C: PASS (marginal Sharpe, but acceptable)
Variant D: BORDERLINE (excellent metrics but only 67 trades - statistical significance questionable)

Recommendation:
  1st choice: Variant B (best metrics + sufficient trades)
  2nd choice: Variant A (baseline, robust)
  
Deploy Variant B on demo forward test.
If B fails, try A.
Monitor D separately if interested in ultra-high-quality setups.
```

---

## Workflow Summary

```
┌─────────────────────┐
│  Day 1: Setup       │
│  - Install MT5      │
│  - Download data    │
│  - Compile EA       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Day 2-3: Backtest  │
│  - Run 4 variants   │
│  - Export reports   │
│  - Fill matrix      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Day 4: Analysis    │
│  - Check pass/fail  │
│  - Check red flags  │
│  - Pick top variant │
└──────────┬──────────┘
           │
           ▼
     ┌────┴────┐
     │         │
     ▼         ▼
  ✅ PASS   ❌ FAIL
     │         │
     │         └──→ STOP PROJECT
     │              (no edge found)
     │
     ▼
┌─────────────────────┐
│ Week 2-5: Demo      │
│ - Forward test 1mo  │
│ - Compare metrics   │
└──────────┬──────────┘
           │
           ▼
     ┌────┴────┐
     │         │
     ▼         ▼
  ✅ PASS   ❌ FAIL
     │         │
     │         └──→ Revisit params
     │              or abandon
     ▼
┌─────────────────────┐
│ Week 6+: Live Micro │
│ - Deploy $500-1K    │
│ - Monitor 3 months  │
└─────────────────────┘
```

---

## Final Checklist

**Before Running Backtests:**
- [ ] Data downloaded (2020-2024, no gaps)
- [ ] Spread set to 20 pips (realistic)
- [ ] Starting capital $10,000
- [ ] EA compiled with 0 errors
- [ ] All 4 variants defined

**After Running Backtests:**
- [ ] All 4 reports saved (HTML + CSV)
- [ ] Comparison matrix filled
- [ ] Pass/fail decision made (at least 1 variant pass?)
- [ ] Red flags checked (no curve-fit symptoms)
- [ ] Top 1-2 variants selected for forward test

**If ALL Variants Fail:**
- [ ] Accept: Strategy has no edge
- [ ] Do NOT tweak parameters to "make it work"
- [ ] Do NOT deploy demo/live
- [ ] Document lessons learned

---

**Document Version:** 1.0  
**Last Updated:** 2026-05-12  
**Purpose:** Prevent overfitting, ensure rigorous validation before live deployment
