# PARAMETER REFERENCE - Complete Input Variable Guide

## Table of Contents
1. [Strategy Selection](#strategy-selection)
2. [Timeframes](#timeframes)
3. [Technical Indicators](#technical-indicators)
4. [Risk Management](#risk-management)
5. [Execution Guards](#execution-guards)
6. [Circuit Breaker](#circuit-breaker)
7. [Session Filter](#session-filter)
8. [Trading Mode](#trading-mode)
9. [Telegram Alerts](#telegram-alerts)
10. [Logging](#logging)
11. [Recommended Presets](#recommended-presets)

---

## Strategy Selection

### InpStrategyVariant
**Type:** `ENUM_STRATEGY_VARIANT`  
**Default:** `VARIANT_A_PURE_EMA`  
**Options:**
- `VARIANT_A_PURE_EMA` - Pure EMA pullback (baseline)
- `VARIANT_B_SD` - EMA + Supply/Demand zones
- `VARIANT_C_TRENDLINE` - EMA + Trendline proxy
- `VARIANT_D_HYBRID` - All filters combined

**Description:** Selects which of the 4 strategy variants to run. Each variant has different entry filters:
- **A:** Simple and robust, good for baseline testing
- **B:** Adds S&D zone filter, may reduce false signals
- **C:** Adds trendline break/retest, good for momentum plays
- **D:** Ultra-selective, highest quality but fewer trades

**Recommendation:** Start with A for initial backtest, then compare all 4.

---

## Timeframes

### InpEntryTF
**Type:** `ENUM_TIMEFRAMES`  
**Default:** `PERIOD_M15`  
**Options:** Any MT5 timeframe (M1, M5, M15, M30, H1, H4, D1)

**Description:** Timeframe for entry signal detection (pullback, RSI, ADX).

**Recommendation:** Keep at M15. Lower timeframes (M5) = more noise. Higher (H1) = fewer trades.

---

### InpTrendTF
**Type:** `ENUM_TIMEFRAMES`  
**Default:** `PERIOD_H1`  
**Options:** Any MT5 timeframe (M15, M30, H1, H4, D1)

**Description:** Timeframe for trend identification (EMA200, EMA50).

**Recommendation:** Keep at H1. This is higher timeframe trend bias.

**Important:** InpTrendTF must be >= InpEntryTF (e.g., H1 >= M15).

---

## Technical Indicators

### EMA Settings

#### InpEMA_Trend
**Type:** `int`  
**Default:** `200`  
**Range:** 50-300

**Description:** Primary trend EMA on higher timeframe (H1). Classic 200 EMA for long-term trend.

**Usage:**
- Price > EMA200 = Uptrend
- Price < EMA200 = Downtrend

**Recommendation:** Keep at 200 (industry standard). Do NOT optimize to 197 or 203.

---

#### InpEMA_Fast
**Type:** `int`  
**Default:** `50`  
**Range:** 20-100

**Description:** Secondary trend EMA on higher timeframe (H1). Used as additional trend filter.

**Usage:**
- Uptrend: EMA50 > EMA200
- Downtrend: EMA50 < EMA200

**Recommendation:** Keep at 50. Common values: 50, 55, or 20.

---

#### InpEMA_Entry
**Type:** `int`  
**Default:** `20`  
**Range:** 10-50

**Description:** Entry EMA on lower timeframe (M15). Pullback entry level.

**Usage:** Wait for price to touch EMA20 or EMA50, then enter when closes back through EMA20.

**Recommendation:** Keep at 20. Common alternatives: 21 (Fibonacci).

---

### RSI Settings

#### InpRSI_Period
**Type:** `int`  
**Default:** `14`  
**Range:** 7-21

**Description:** RSI calculation period.

**Recommendation:** Keep at 14 (Welles Wilder standard).

---

#### InpRSI_Oversold
**Type:** `double`  
**Default:** `35.0`  
**Range:** 20.0-40.0

**Description:** RSI level to confirm long entry (cross up through this level).

**Usage:** Wait for RSI to cross UP through 35 from below (indicates bullish momentum resuming).

**Recommendation:** 
- Conservative: 30 (classic oversold)
- Moderate: 35 (default, earlier entry)
- Aggressive: 40 (early entry, more signals)

---

#### InpRSI_Overbought
**Type:** `double`  
**Default:** `65.0`  
**Range:** 60.0-80.0

**Description:** RSI level to confirm short entry (cross down through this level).

**Usage:** Wait for RSI to cross DOWN through 65 from above (indicates bearish momentum resuming).

**Recommendation:**
- Aggressive: 60
- Moderate: 65 (default)
- Conservative: 70 (classic overbought)

---

### ADX Settings

#### InpADX_Period
**Type:** `int`  
**Default:** `14`  
**Range:** 7-21

**Description:** ADX calculation period.

**Recommendation:** Keep at 14 (Welles Wilder standard).

---

#### InpADX_Min
**Type:** `double`  
**Default:** `20.0`  
**Range:** 15.0-30.0

**Description:** Minimum ADX value to confirm trending market (not ranging).

**Usage:** Only take trades when ADX > 20 (indicates trend strength).

**Recommendation:**
- Loose: 15-18 (more signals, may include ranges)
- Moderate: 20-22 (default)
- Strict: 25-30 (very strong trends only, fewer signals)

---

### ATR Settings (for SL/TP/Trailing)

#### InpATR_Period
**Type:** `int`  
**Default:** `14`  
**Range:** 7-21

**Description:** ATR calculation period for volatility measurement.

**Recommendation:** Keep at 14 (standard).

---

#### InpATR_TF
**Type:** `ENUM_TIMEFRAMES`  
**Default:** `PERIOD_H1`  
**Options:** M15, M30, H1, H4

**Description:** Timeframe for ATR calculation. Using higher TF (H1) provides more stable SL/TP levels.

**Recommendation:** Keep at H1. M15 ATR may be too reactive.

---

#### InpATR_SL_Multiplier
**Type:** `double`  
**Default:** `2.0`  
**Range:** 1.5-3.0

**Description:** Stop Loss distance = ATR × this multiplier.

**Example:** If H1 ATR = 15 pips, SL = 15 × 2.0 = 30 pips from entry.

**Recommendation:**
- Tight: 1.5-1.8 (more stop-outs, but smaller loss per trade)
- Moderate: 2.0 (default)
- Wide: 2.5-3.0 (fewer stop-outs, but larger loss per trade)

---

#### InpATR_TP_Multiplier
**Type:** `double`  
**Default:** `3.0`  
**Range:** 2.0-5.0

**Description:** Take Profit distance = ATR × this multiplier.

**Risk:Reward Ratio:** TP_Multiplier / SL_Multiplier
- Default: 3.0 / 2.0 = 1.5 R:R

**Recommendation:**
- Conservative: 2.0 (1:1 R:R, easier to hit TP)
- Moderate: 3.0 (1.5:1 R:R, default)
- Aggressive: 4.0-5.0 (2:1 to 2.5:1 R:R, harder to hit)

---

#### InpATR_Trail_Multiplier
**Type:** `double`  
**Default:** `1.0`  
**Range:** 0.5-2.0

**Description:** Trailing stop distance = ATR × this multiplier.

**Usage:** After breakeven is reached, trail SL by this distance as price moves favorably.

**Recommendation:**
- Tight trail: 0.5-0.8 (lock profits quickly, may exit early)
- Moderate: 1.0 (default)
- Wide trail: 1.5-2.0 (let winners run, but risk giving back profit)

---

#### InpATR_Breakeven_Multiplier
**Type:** `double`  
**Default:** `1.5`  
**Range:** 1.0-2.0

**Description:** Move SL to breakeven when profit reaches ATR × this multiplier.

**Example:** If ATR = 15 pips, move SL to entry when profit = 15 × 1.5 = 22.5 pips.

**Recommendation:**
- Quick breakeven: 1.0 (protect capital fast, but may exit on normal retracement)
- Moderate: 1.5 (default)
- Patient: 2.0 (wait for more confirmation)

---

## Supply & Demand Proxy (Variant B/D)

### InpSD_LookbackBars
**Type:** `int`  
**Default:** `30`  
**Range:** 20-50

**Description:** How many bars back to search for swing highs/lows to form S&D zones.

**Recommendation:** 30 is moderate. Increase to 50 for longer-term zones.

---

### InpSD_MinRejections
**Type:** `int`  
**Default:** `2`  
**Range:** 2-4

**Description:** Minimum number of times price must touch and reject from a level to qualify as S&D zone.

**Recommendation:** Keep at 2 (balance between quality and quantity).

---

### InpSD_BufferPips
**Type:** `int`  
**Default:** `10`  
**Range:** 5-20

**Description:** Tolerance around swing level to count as "touched" (in pips).

**Example:** Swing low at 1950.00, buffer = 10 → Zone is 1949.90 to 1950.10.

**Recommendation:** For XAUUSD, 10 pips is reasonable. Increase for higher volatility pairs.

---

### InpSD_EntryTolerancePips
**Type:** `int`  
**Default:** `15`  
**Range:** 10-30

**Description:** How close current price must be to S&D zone to qualify for entry (in pips).

**Recommendation:** 15 pips for XAUUSD. Tighter = fewer signals, wider = more signals.

---

## Trendline Proxy (Variant C/D)

### InpTL_SwingLookback
**Type:** `int`  
**Default:** `7`  
**Range:** 5-15

**Description:** How many bars on each side to identify swing high/low.

**Example:** 7 = A bar is swing low if lower than 7 bars before AND 7 bars after it.

**Recommendation:** 
- Sensitive (more swings): 5
- Moderate: 7 (default)
- Conservative (major swings only): 10-15

---

### InpTL_MinSwings
**Type:** `int`  
**Default:** `3`  
**Range:** 2-5

**Description:** Minimum number of ascending/descending swings to confirm trendline.

**Recommendation:** Keep at 3 (good balance).

---

### InpTL_RetestTolerancePips
**Type:** `int`  
**Default:** `15`  
**Range:** 10-30

**Description:** How close price must get to trendline to count as "retest" (in pips).

**Recommendation:** 15 pips for XAUUSD.

---

### InpTL_RetestMaxBarsAgo
**Type:** `int`  
**Default:** `10`  
**Range:** 5-20

**Description:** How recently the trendline retest must have occurred (bars ago).

**Recommendation:** 10 bars (on M15 = ~2.5 hours ago max).

---

## Risk Management

### InpRiskPerTrade
**Type:** `double`  
**Default:** `0.25`  
**Range:** 0.1-2.0  
**Unit:** % of equity

**Description:** Risk amount per trade as percentage of account equity.

**Example:** $10,000 account, 0.25% risk = $25 risk per trade.

**Recommendation:**
- Ultra-conservative: 0.1-0.2% (slow growth)
- Conservative: 0.25-0.5% (default, recommended for v1)
- Moderate: 0.5-1.0%
- Aggressive: 1.0-2.0% (high risk, faster DD accumulation)

**Warning:** >2% per trade is gambler territory, not recommended.

---

### InpDailyLossCap
**Type:** `double`  
**Default:** `1.5`  
**Range:** 1.0-5.0  
**Unit:** % of equity

**Description:** Max loss allowed in one day. If hit, EA stops trading until next day.

**Example:** $10,000 account, 1.5% cap = Stop if lose $150 in one day.

**Recommendation:**
- Strict: 1.0-1.5% (default)
- Moderate: 2.0-3.0%
- Loose: 4.0-5.0%

**Formula:** Should be ~3-6× InpRiskPerTrade (i.e., allow 3-6 losing trades per day max).

---

### InpWeeklyLossCap
**Type:** `double`  
**Default:** `4.0`  
**Range:** 3.0-10.0  
**Unit:** % of equity

**Description:** Max loss allowed in one week. If hit, EA stops trading until next week.

**Recommendation:**
- Strict: 3.0-4.0% (default)
- Moderate: 5.0-7.0%
- Loose: 8.0-10.0%

**Formula:** Should be ~2-3× InpDailyLossCap.

---

### InpMaxEquityDD
**Type:** `double`  
**Default:** `12.0`  
**Range:** 10.0-25.0  
**Unit:** % of peak equity

**Description:** Maximum equity drawdown allowed. If hit, EA closes all positions and pauses.

**Example:** Peak equity was $11,000, current equity $9,680 → DD = 12% → Trigger.

**Recommendation:**
- Conservative: 10-12% (default)
- Moderate: 15-18%
- Aggressive: 20-25%

**Warning:** This is a "kill switch" - once hit, requires manual review before resuming.

---

### InpMaxConsecutiveLosses
**Type:** `int`  
**Default:** `3`  
**Range:** 2-8

**Description:** Max number of losing trades in a row before EA pauses and requires manual review.

**Recommendation:**
- Sensitive: 2-3 (default, catch bad streaks early)
- Moderate: 4-5
- Patient: 6-8

**Psychology:** Even with 50% WR, 3 losses in a row happens ~12.5% of time (normal). 8 losses = 0.4% (very rare, indicates problem).

---

### InpMaxTradesPerDay
**Type:** `int`  
**Default:** `3`  
**Range:** 1-10

**Description:** Maximum number of trades allowed in one day.

**Purpose:** Prevents over-trading, spam trading, or EA malfunction.

**Recommendation:**
- Conservative: 2-3 (default, swing strategy)
- Moderate: 4-5
- Scalper: 10+ (not applicable to this EA)

---

### InpMaxOpenPositions
**Type:** `int`  
**Default:** `1`  
**Range:** 1-5

**Description:** Maximum number of positions open simultaneously.

**Recommendation:** **Keep at 1** for this strategy (no grid, no martingale, no hedging).

---

## Execution Guards

### InpMaxSpreadPips
**Type:** `int`  
**Default:** `30`  
**Range:** 20-50  
**Unit:** Pips

**Description:** Skip entry if current spread exceeds this value.

**XAUUSD Context:**
- Normal Exness spread: 15-25 pips
- News spike: 40-80 pips
- Weekend gap: 50-150 pips

**Recommendation:** 30 pips (catches abnormal spreads).

---

### InpMaxSlippagePips
**Type:** `int`  
**Default:** `10`  
**Range:** 5-20  
**Unit:** Pips

**Description:** Maximum allowed slippage on order execution. Order rejected if exceeds.

**Recommendation:**
- Strict: 5-10 pips (default)
- Moderate: 10-15 pips
- Loose: 15-20 pips

---

### InpMinFreeMarginPercent
**Type:** `double`  
**Default:** `200.0`  
**Range:** 100.0-500.0  
**Unit:** %

**Description:** Minimum free margin as % of used margin required to open new position.

**Formula:** (Free Margin / Used Margin) × 100 ≥ This value

**Example:** Used margin = $100, require 200% → Need $200 free margin.

**Recommendation:**
- Conservative: 300-500% (very safe)
- Moderate: 200% (default)
- Aggressive: 100-150% (minimum safety)

---

### InpFridayAutoClose
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Automatically close all positions on Friday before weekend to avoid gap risk.

**Recommendation:** **Enable (true)** unless you enjoy weekend gap surprises.

---

### InpFridayCloseTime
**Type:** `string`  
**Default:** `"22:00"`  
**Format:** "HH:MM" (24-hour, GMT)

**Description:** What time on Friday to close all positions.

**Recommendation:**
- Conservative: "20:00" GMT (close early)
- Moderate: "22:00" GMT (default)
- Aggressive: "23:30" GMT (trade until last minute)

**XAUUSD Note:** Gold market closes Friday 22:00 GMT, so 22:00 is reasonable.

---

## Circuit Breaker (Volatility Pause)

### InpEnableVolatilityBreaker
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Enable auto-pause during volatility spikes (news, flash crashes).

**Recommendation:** **Enable (true)** for safety.

---

### InpATR_VolatilityMultiplier
**Type:** `double`  
**Default:** `3.0`  
**Range:** 2.0-5.0

**Description:** Trigger pause if current ATR > median ATR × this multiplier.

**Example:** Median ATR = 10 pips, current ATR = 35 pips → 35/10 = 3.5× → Trigger.

**Recommendation:**
- Sensitive: 2.0-2.5 (pause often, very safe)
- Moderate: 3.0 (default)
- Loose: 4.0-5.0 (only extreme events)

---

### InpATR_VolatilityLookback
**Type:** `int`  
**Default:** `50`  
**Range:** 20-100

**Description:** How many bars to calculate median ATR for comparison.

**Recommendation:** 50 bars is good balance (on M15 = ~12.5 hours).

---

### InpSpreadSpikeThreshold
**Type:** `int`  
**Default:** `50`  
**Range:** 30-100  
**Unit:** Pips

**Description:** Trigger pause if spread exceeds this value (extreme event).

**XAUUSD Context:**
- Normal: 15-25 pips
- Spike threshold: 50 pips = 2-3× normal

**Recommendation:** 50 pips (catches major disruptions).

---

### InpVolatilityPauseMinutes
**Type:** `int`  
**Default:** `30`  
**Range:** 10-120  
**Unit:** Minutes

**Description:** How long to pause trading after volatility trigger.

**Recommendation:**
- Short: 10-20 min (quick resume)
- Moderate: 30 min (default)
- Long: 60-120 min (wait for full calm)

---

## Session Filter (Phase 2 Feature)

### InpTradeAsian
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Allow trading during Asian session (00:00-08:00 GMT+7).

**Recommendation:** Phase 1 = `true` (collect data). Phase 2 = Adjust based on backtest.

---

### InpTradeLondon
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Allow trading during London session (14:00-23:00 GMT+7).

**Recommendation:** Keep `true` (London = high liquidity for XAUUSD).

---

### InpTradeNY
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Allow trading during NY session (19:00-04:00 GMT+7).

**Recommendation:** Keep `true` (NY = peak volume for XAUUSD).

---

## Trading Mode

### InpTradingMode
**Type:** `ENUM_TRADING_MODE`  
**Default:** `MODE_ALERTS_ONLY`  
**Options:**
- `MODE_ALERTS_ONLY` - Detect signals, log only, NO real trades
- `MODE_AUTO_TRADE` - Auto-execute trades
- `MODE_PAUSED` - Stop all activity

**Description:** Controls EA behavior.

**Recommendation by Phase:**
- Phase 1 (Backtest): `AUTO_TRADE` (in Strategy Tester)
- Phase 2 (Demo Forward): `AUTO_TRADE`
- Phase 3 (Live Pilot): `AUTO_TRADE` (but test with `ALERTS_ONLY` first)
- Production: `AUTO_TRADE`

**Safety:** Default is `ALERTS_ONLY` to prevent accidental live trading.

---

## Telegram Alerts

### InpTelegramEnabled
**Type:** `bool`  
**Default:** `false`  
**Options:** `true` / `false`

**Description:** Enable Telegram push notifications.

**Recommendation:** Optional. Useful for monitoring, but not required.

---

### InpTelegramBotToken
**Type:** `string`  
**Default:** `""`

**Description:** Telegram bot API token (get from @BotFather).

**Format:** `"1234567890:ABCdefGHIjklMNOpqrsTUVwxyz"`

---

### InpTelegramChatID
**Type:** `string`  
**Default:** `""`

**Description:** Your Telegram chat ID (get from @userinfobot).

**Format:** `"123456789"`

---

### InpTelegramMinAlertLevel
**Type:** `int`  
**Default:** `1`  
**Range:** 1-3

**Description:** Minimum alert level to send:
- `1` = Info (all signals, entries, exits)
- `2` = Warning (risk events, circuit breaker)
- `3` = Error (only critical failures)

**Recommendation:** `1` for full monitoring, `2` to reduce spam.

---

## Logging

### InpEnableCSVLog
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Enable CSV trade log export.

**Recommendation:** **Keep enabled (true)** - Required for backtest analysis.

---

### InpCSVLogPath
**Type:** `string`  
**Default:** `"EA_Logs\\XAUUSD_MultiStrategy_"`

**Description:** Path prefix for CSV log files.

**Output:** Files created like: `EA_Logs\XAUUSD_MultiStrategy_2024_05_12.csv`

---

### InpVerboseLog
**Type:** `bool`  
**Default:** `true`  
**Options:** `true` / `false`

**Description:** Enable detailed journal logs (every decision logged).

**Recommendation:**
- Development/Debug: `true`
- Production: `false` (reduce log spam)

---

## Magic Number

### InpMagicNumber
**Type:** `int`  
**Default:** `230512`  
**Range:** Any integer

**Description:** Unique identifier for this EA's trades (allows running multiple EAs on same account).

**Recommendation:** Use date-based (YYMMDD format) or any unique number.

---

## Recommended Presets

### Preset 1: Conservative (Default)
```
InpRiskPerTrade = 0.25
InpDailyLossCap = 1.5
InpWeeklyLossCap = 4.0
InpMaxEquityDD = 12.0
InpMaxConsecutiveLosses = 3
InpATR_SL_Multiplier = 2.0
InpATR_TP_Multiplier = 3.0
```
**Profile:** Safety-first, slow growth, good for live micro.

---

### Preset 2: Moderate
```
InpRiskPerTrade = 0.5
InpDailyLossCap = 2.5
InpWeeklyLossCap = 6.0
InpMaxEquityDD = 18.0
InpMaxConsecutiveLosses = 4
InpATR_SL_Multiplier = 2.0
InpATR_TP_Multiplier = 4.0
```
**Profile:** Balanced risk/reward, suitable after proving edge in conservative mode.

---

### Preset 3: Aggressive (NOT Recommended for v1)
```
InpRiskPerTrade = 1.0
InpDailyLossCap = 4.0
InpWeeklyLossCap = 10.0
InpMaxEquityDD = 25.0
InpMaxConsecutiveLosses = 5
InpATR_SL_Multiplier = 1.5
InpATR_TP_Multiplier = 5.0
```
**Profile:** High risk, high reward, only after 6+ months proven track record.

---

## Parameter Tuning Guidelines

### ✅ Safe to Tune (Minimal Overfitting Risk)
- ATR multipliers (SL, TP, Trail, Breakeven)
- Risk % per trade
- Daily/weekly loss caps
- Trading mode (Alerts vs Auto)

### ⚠️ Tune Carefully (Moderate Overfitting Risk)
- EMA periods (stick to common values: 20, 50, 200)
- RSI thresholds (stay within 30-40 / 60-70 range)
- ADX minimum (15-25 range)
- S&D lookback / rejection count

### ❌ Do NOT Tune (High Overfitting Risk)
- Technical indicator periods to decimals (e.g., EMA 197.3)
- Hyper-optimize RSI to 34.7
- Session times to exact minute
- Any parameter based on single backtest year

---

## Quick Reference Card

| Parameter | Default | Range | Purpose |
|-----------|---------|-------|---------|
| **Strategy** | A | A/B/C/D | Select variant |
| **Risk/Trade** | 0.25% | 0.1-2% | Position size |
| **Daily Cap** | 1.5% | 1-5% | Stop if hit |
| **Weekly Cap** | 4% | 3-10% | Stop if hit |
| **Max DD** | 12% | 10-25% | Kill switch |
| **Max Losses** | 3 | 2-8 | Consecutive stop |
| **SL Mult** | 2.0 | 1.5-3 | ATR × this |
| **TP Mult** | 3.0 | 2-5 | ATR × this |
| **Max Spread** | 30 | 20-50 | Skip if over |
| **Mode** | Alerts | 3 modes | Safety default |

---

**Document Version:** 1.0  
**Last Updated:** 2026-05-12  
**Total Parameters:** 50+  
**Purpose:** Complete reference for all EA input variables
