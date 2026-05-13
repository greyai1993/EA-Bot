//+------------------------------------------------------------------+
//|                                     StrategyVariants.mqh        |
//|                                  Grey / Violet AI               |
//+------------------------------------------------------------------+
#property copyright "Grey / Violet AI"
#property link      "https://github.com/greyai1993/EA-Bot"
#property strict

enum ENUM_STRATEGY_VARIANT
{
   VARIANT_A,    // Pure EMA Pullback
   VARIANT_B,    // EMA + Supply/Demand
   VARIANT_C,    // EMA + Trendline
   VARIANT_D     // Full Hybrid
};

enum ENUM_SIGNAL
{
   SIGNAL_NONE,
   SIGNAL_LONG,
   SIGNAL_SHORT
};

class StrategyVariants
{
private:
   int m_ema_trend_period;
   int m_ema_fast_period;
   int m_ema_entry_period;
   int m_rsi_period;
   double m_rsi_oversold;
   double m_rsi_overbought;
   double m_adx_min;

   string m_last_signal_reason;

   // Variant A helpers
   bool IsUptrend_H1();
   bool IsDowntrend_H1();
   bool IsPullbackLong_M15();
   bool IsPullbackShort_M15();
   bool RSI_CrossUp();
   bool RSI_CrossDown();
   bool IsTrending();

   // Variant B helpers
   void FindDemandZones(double &zones[], int max_zones);
   void FindSupplyZones(double &zones[], int max_zones);
   int CountRejections(double price_level, int lookback_bars);
   bool IsNearDemandZone();
   bool IsNearSupplyZone();

   // Variant C helpers
   void FindSwingLows(double &swing_lows[], int max_swings);
   void FindSwingHighs(double &swing_highs[], int max_swings);
   bool IsAscendingSwingLows();
   bool IsDescendingSwingHighs();
   bool HasRecentTrendlineRetest();

   // Main signal functions
   ENUM_SIGNAL VariantA_Signal();
   ENUM_SIGNAL VariantB_Signal();
   ENUM_SIGNAL VariantC_Signal();
   ENUM_SIGNAL VariantD_Signal();

public:
   StrategyVariants();
   ~StrategyVariants();

   bool Initialize(int ema_trend, int ema_fast, int ema_entry,
                   int rsi_period, double rsi_oversold, double rsi_overbought,
                   double adx_min);

   ENUM_SIGNAL GetSignal(ENUM_STRATEGY_VARIANT variant);
   string GetSignalReason() { return m_last_signal_reason; }
};

//+------------------------------------------------------------------+
StrategyVariants::StrategyVariants()
{
   m_ema_trend_period = 200;
   m_ema_fast_period = 50;
   m_ema_entry_period = 20;
   m_rsi_period = 14;
   m_rsi_oversold = 30.0;
   m_rsi_overbought = 70.0;
   m_adx_min = 20.0;

   m_last_signal_reason = "";
}

//+------------------------------------------------------------------+
StrategyVariants::~StrategyVariants()
{
}

//+------------------------------------------------------------------+
bool StrategyVariants::Initialize(int ema_trend, int ema_fast, int ema_entry,
                                   int rsi_period, double rsi_oversold, double rsi_overbought,
                                   double adx_min)
{
   m_ema_trend_period = ema_trend;
   m_ema_fast_period = ema_fast;
   m_ema_entry_period = ema_entry;
   m_rsi_period = rsi_period;
   m_rsi_oversold = rsi_oversold;
   m_rsi_overbought = rsi_overbought;
   m_adx_min = adx_min;

   Print("StrategyVariants initialized - EMA Trend: ", m_ema_trend_period,
         ", EMA Fast: ", m_ema_fast_period, ", EMA Entry: ", m_ema_entry_period);

   return true;
}

//+------------------------------------------------------------------+
ENUM_SIGNAL StrategyVariants::GetSignal(ENUM_STRATEGY_VARIANT variant)
{
   m_last_signal_reason = "";

   switch(variant)
   {
      case VARIANT_A:
         return VariantA_Signal();

      case VARIANT_B:
         return VariantB_Signal();

      case VARIANT_C:
         return VariantC_Signal();

      case VARIANT_D:
         return VariantD_Signal();

      default:
         return SIGNAL_NONE;
   }
}

//+------------------------------------------------------------------+
// VARIANT A: Pure EMA Pullback
//+------------------------------------------------------------------+
ENUM_SIGNAL StrategyVariants::VariantA_Signal()
{
   if(!IsTrending())
      return SIGNAL_NONE;

   if(IsUptrend_H1() && IsPullbackLong_M15() && RSI_CrossUp())
   {
      m_last_signal_reason = "Variant_A: H1 uptrend + M15 pullback + RSI crossup";
      return SIGNAL_LONG;
   }

   if(IsDowntrend_H1() && IsPullbackShort_M15() && RSI_CrossDown())
   {
      m_last_signal_reason = "Variant_A: H1 downtrend + M15 pullback + RSI crossdown";
      return SIGNAL_SHORT;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsUptrend_H1()
{
   double ema200 = iMA(_Symbol, PERIOD_H1, m_ema_trend_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double close = iClose(_Symbol, PERIOD_H1, 0);

   return close > ema200;
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsDowntrend_H1()
{
   double ema200 = iMA(_Symbol, PERIOD_H1, m_ema_trend_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double close = iClose(_Symbol, PERIOD_H1, 0);

   return close < ema200;
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsPullbackLong_M15()
{
   double ema20 = iMA(_Symbol, PERIOD_M15, m_ema_entry_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema50 = iMA(_Symbol, PERIOD_M15, m_ema_fast_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double close = iClose(_Symbol, PERIOD_M15, 0);

   return (close < ema20 && ema20 > ema50);
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsPullbackShort_M15()
{
   double ema20 = iMA(_Symbol, PERIOD_M15, m_ema_entry_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema50 = iMA(_Symbol, PERIOD_M15, m_ema_fast_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double close = iClose(_Symbol, PERIOD_M15, 0);

   return (close > ema20 && ema20 < ema50);
}

//+------------------------------------------------------------------+
bool StrategyVariants::RSI_CrossUp()
{
   double rsi_current = iRSI(_Symbol, PERIOD_M15, m_rsi_period, PRICE_CLOSE, 0);
   double rsi_prev = iRSI(_Symbol, PERIOD_M15, m_rsi_period, PRICE_CLOSE, 1);

   return (rsi_prev < m_rsi_oversold && rsi_current > m_rsi_oversold);
}

//+------------------------------------------------------------------+
bool StrategyVariants::RSI_CrossDown()
{
   double rsi_current = iRSI(_Symbol, PERIOD_M15, m_rsi_period, PRICE_CLOSE, 0);
   double rsi_prev = iRSI(_Symbol, PERIOD_M15, m_rsi_period, PRICE_CLOSE, 1);

   return (rsi_prev > m_rsi_overbought && rsi_current < m_rsi_overbought);
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsTrending()
{
   double adx = iADX(_Symbol, PERIOD_H1, 14, PRICE_CLOSE, MODE_MAIN, 0);

   return (adx >= m_adx_min);
}

//+------------------------------------------------------------------+
// VARIANT B: EMA + Supply/Demand Proxy
//+------------------------------------------------------------------+
ENUM_SIGNAL StrategyVariants::VariantB_Signal()
{
   if(!IsTrending())
      return SIGNAL_NONE;

   if(IsUptrend_H1() && IsNearDemandZone() && IsPullbackLong_M15())
   {
      m_last_signal_reason = "Variant_B: Uptrend + Near demand zone + Pullback";
      return SIGNAL_LONG;
   }

   if(IsDowntrend_H1() && IsNearSupplyZone() && IsPullbackShort_M15())
   {
      m_last_signal_reason = "Variant_B: Downtrend + Near supply zone + Pullback";
      return SIGNAL_SHORT;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
void StrategyVariants::FindDemandZones(double &zones[], int max_zones)
{
   ArrayResize(zones, 0);

   int lookback = 100;
   int zone_count = 0;

   for(int i = 2; i < lookback && zone_count < max_zones; i++)
   {
      double low_current = iLow(_Symbol, PERIOD_H1, i);
      double low_prev = iLow(_Symbol, PERIOD_H1, i + 1);
      double low_next = iLow(_Symbol, PERIOD_H1, i - 1);

      if(low_current < low_prev && low_current < low_next)
      {
         int rejections = CountRejections(low_current, 50);
         if(rejections >= 2)
         {
            ArrayResize(zones, zone_count + 1);
            zones[zone_count] = low_current;
            zone_count++;
         }
      }
   }
}

//+------------------------------------------------------------------+
void StrategyVariants::FindSupplyZones(double &zones[], int max_zones)
{
   ArrayResize(zones, 0);

   int lookback = 100;
   int zone_count = 0;

   for(int i = 2; i < lookback && zone_count < max_zones; i++)
   {
      double high_current = iHigh(_Symbol, PERIOD_H1, i);
      double high_prev = iHigh(_Symbol, PERIOD_H1, i + 1);
      double high_next = iHigh(_Symbol, PERIOD_H1, i - 1);

      if(high_current > high_prev && high_current > high_next)
      {
         int rejections = CountRejections(high_current, 50);
         if(rejections >= 2)
         {
            ArrayResize(zones, zone_count + 1);
            zones[zone_count] = high_current;
            zone_count++;
         }
      }
   }
}

//+------------------------------------------------------------------+
int StrategyVariants::CountRejections(double price_level, int lookback_bars)
{
   int rejections = 0;
   double tolerance = price_level * 0.002;

   for(int i = 0; i < lookback_bars; i++)
   {
      double high = iHigh(_Symbol, PERIOD_H1, i);
      double low = iLow(_Symbol, PERIOD_H1, i);

      if(MathAbs(low - price_level) <= tolerance || MathAbs(high - price_level) <= tolerance)
      {
         rejections++;
      }
   }

   return rejections;
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsNearDemandZone()
{
   double zones[];
   FindDemandZones(zones, 5);

   if(ArraySize(zones) == 0)
      return false;

   double current_price = iClose(_Symbol, PERIOD_M15, 0);

   for(int i = 0; i < ArraySize(zones); i++)
   {
      double distance = MathAbs(current_price - zones[i]);
      double tolerance = current_price * 0.003;

      if(distance <= tolerance)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsNearSupplyZone()
{
   double zones[];
   FindSupplyZones(zones, 5);

   if(ArraySize(zones) == 0)
      return false;

   double current_price = iClose(_Symbol, PERIOD_M15, 0);

   for(int i = 0; i < ArraySize(zones); i++)
   {
      double distance = MathAbs(current_price - zones[i]);
      double tolerance = current_price * 0.003;

      if(distance <= tolerance)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
// VARIANT C: EMA + Trendline Proxy
//+------------------------------------------------------------------+
ENUM_SIGNAL StrategyVariants::VariantC_Signal()
{
   if(!IsTrending())
      return SIGNAL_NONE;

   if(IsUptrend_H1() && IsAscendingSwingLows() && HasRecentTrendlineRetest() && IsPullbackLong_M15())
   {
      m_last_signal_reason = "Variant_C: Uptrend + Ascending swings + Trendline retest";
      return SIGNAL_LONG;
   }

   if(IsDowntrend_H1() && IsDescendingSwingHighs() && HasRecentTrendlineRetest() && IsPullbackShort_M15())
   {
      m_last_signal_reason = "Variant_C: Downtrend + Descending swings + Trendline retest";
      return SIGNAL_SHORT;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
void StrategyVariants::FindSwingLows(double &swing_lows[], int max_swings)
{
   ArrayResize(swing_lows, 0);

   int lookback = 50;
   int swing_count = 0;

   for(int i = 2; i < lookback && swing_count < max_swings; i++)
   {
      double low_current = iLow(_Symbol, PERIOD_H1, i);
      double low_prev = iLow(_Symbol, PERIOD_H1, i + 1);
      double low_next = iLow(_Symbol, PERIOD_H1, i - 1);

      if(low_current < low_prev && low_current < low_next)
      {
         ArrayResize(swing_lows, swing_count + 1);
         swing_lows[swing_count] = low_current;
         swing_count++;
      }
   }
}

//+------------------------------------------------------------------+
void StrategyVariants::FindSwingHighs(double &swing_highs[], int max_swings)
{
   ArrayResize(swing_highs, 0);

   int lookback = 50;
   int swing_count = 0;

   for(int i = 2; i < lookback && swing_count < max_swings; i++)
   {
      double high_current = iHigh(_Symbol, PERIOD_H1, i);
      double high_prev = iHigh(_Symbol, PERIOD_H1, i + 1);
      double high_next = iHigh(_Symbol, PERIOD_H1, i - 1);

      if(high_current > high_prev && high_current > high_next)
      {
         ArrayResize(swing_highs, swing_count + 1);
         swing_highs[swing_count] = high_current;
         swing_count++;
      }
   }
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsAscendingSwingLows()
{
   double swings[];
   FindSwingLows(swings, 3);

   if(ArraySize(swings) < 3)
      return false;

   return (swings[0] > swings[1] && swings[1] > swings[2]);
}

//+------------------------------------------------------------------+
bool StrategyVariants::IsDescendingSwingHighs()
{
   double swings[];
   FindSwingHighs(swings, 3);

   if(ArraySize(swings) < 3)
      return false;

   return (swings[0] < swings[1] && swings[1] < swings[2]);
}

//+------------------------------------------------------------------+
bool StrategyVariants::HasRecentTrendlineRetest()
{
   double swings[];
   FindSwingLows(swings, 2);

   if(ArraySize(swings) < 2)
      return false;

   double current_low = iLow(_Symbol, PERIOD_M15, 0);
   double projected_trendline = swings[0];
   double tolerance = projected_trendline * 0.003;

   return (MathAbs(current_low - projected_trendline) <= tolerance);
}

//+------------------------------------------------------------------+
// VARIANT D: Full Hybrid (All Filters Combined)
//+------------------------------------------------------------------+
ENUM_SIGNAL StrategyVariants::VariantD_Signal()
{
   if(!IsTrending())
      return SIGNAL_NONE;

   if(IsUptrend_H1() &&
      IsPullbackLong_M15() &&
      RSI_CrossUp() &&
      IsNearDemandZone() &&
      IsAscendingSwingLows())
   {
      m_last_signal_reason = "Variant_D: All long filters passed";
      return SIGNAL_LONG;
   }

   if(IsDowntrend_H1() &&
      IsPullbackShort_M15() &&
      RSI_CrossDown() &&
      IsNearSupplyZone() &&
      IsDescendingSwingHighs())
   {
      m_last_signal_reason = "Variant_D: All short filters passed";
      return SIGNAL_SHORT;
   }

   return SIGNAL_NONE;
}
