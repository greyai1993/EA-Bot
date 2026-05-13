//+------------------------------------------------------------------+
//|                                       CircuitBreaker.mqh        |
//|                                  Grey / Violet AI               |
//+------------------------------------------------------------------+
#property copyright "Grey / Violet AI"
#property link      "https://github.com/greyai1993/EA-Bot"
#property strict

#include "IndicatorHelpers.mqh"

class CircuitBreaker
{
private:
   int m_atr_period;
   int m_atr_lookback;
   double m_atr_spike_multiplier;
   double m_spread_threshold_pips;
   int m_pause_duration_minutes;

   datetime m_pause_until;
   string m_last_pause_reason;

   double CalculateMedianATR(int lookback, ENUM_TIMEFRAMES tf);
   double GetCurrentSpreadPips();
   bool DetectGap(double atr_value);

public:
   CircuitBreaker();
   ~CircuitBreaker();

   bool Initialize(int atr_period, int atr_lookback, double atr_multiplier,
                   double spread_threshold, int pause_duration);

   bool IsVolatilityHigh(string &reason);
   void TriggerPause(string reason);
   bool IsPaused();

   datetime GetPauseUntil() { return m_pause_until; }
   string GetLastPauseReason() { return m_last_pause_reason; }
};

//+------------------------------------------------------------------+
CircuitBreaker::CircuitBreaker()
{
   m_atr_period = 14;
   m_atr_lookback = 20;
   m_atr_spike_multiplier = 2.0;
   m_spread_threshold_pips = 5.0;
   m_pause_duration_minutes = 15;

   m_pause_until = 0;
   m_last_pause_reason = "";
}

//+------------------------------------------------------------------+
CircuitBreaker::~CircuitBreaker()
{
}

//+------------------------------------------------------------------+
bool CircuitBreaker::Initialize(int atr_period, int atr_lookback, double atr_multiplier,
                                 double spread_threshold, int pause_duration)
{
   m_atr_period = atr_period;
   m_atr_lookback = atr_lookback;
   m_atr_spike_multiplier = atr_multiplier;
   m_spread_threshold_pips = spread_threshold;
   m_pause_duration_minutes = pause_duration;

   Print("CircuitBreaker initialized - ATR Period: ", m_atr_period,
         ", Spike Multiplier: ", m_atr_spike_multiplier,
         ", Spread Threshold: ", m_spread_threshold_pips, " pips");

   return true;
}

//+------------------------------------------------------------------+
bool CircuitBreaker::IsVolatilityHigh(string &reason)
{
   if(IsPaused())
   {
      int minutes_left = (int)((m_pause_until - TimeCurrent()) / 60);
      reason = StringFormat("Paused for %d more minutes - %s", minutes_left, m_last_pause_reason);
      return true;
   }

   double current_atr = iATR_v(_Symbol, PERIOD_H1, m_atr_period, 0);
   if(current_atr == 0)
   {
      Print("WARNING: ATR value is 0");
      return false;
   }

   double median_atr = CalculateMedianATR(m_atr_lookback, PERIOD_H1);
   if(median_atr == 0)
   {
      Print("WARNING: Median ATR is 0");
      return false;
   }

   if(current_atr > median_atr * m_atr_spike_multiplier)
   {
      reason = StringFormat("ATR spike: %.2f > %.2f (%.1fx median)",
                            current_atr, median_atr * m_atr_spike_multiplier, m_atr_spike_multiplier);
      return true;
   }

   double spread_pips = GetCurrentSpreadPips();
   if(spread_pips > m_spread_threshold_pips)
   {
      reason = StringFormat("Spread spike: %.1f pips > %.1f pips threshold",
                            spread_pips, m_spread_threshold_pips);
      return true;
   }

   if(DetectGap(current_atr))
   {
      reason = "Price gap detected > 2x ATR";
      return true;
   }

   reason = "OK";
   return false;
}

//+------------------------------------------------------------------+
void CircuitBreaker::TriggerPause(string reason)
{
   m_pause_until = TimeCurrent() + (m_pause_duration_minutes * 60);
   m_last_pause_reason = reason;

   Print("CIRCUIT BREAKER TRIGGERED: ", reason);
   Print("Trading paused until: ", TimeToString(m_pause_until, TIME_DATE|TIME_SECONDS));
}

//+------------------------------------------------------------------+
bool CircuitBreaker::IsPaused()
{
   if(m_pause_until == 0)
      return false;

   if(TimeCurrent() >= m_pause_until)
   {
      Print("Circuit breaker pause expired - Resuming");
      m_pause_until = 0;
      m_last_pause_reason = "";
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
double CircuitBreaker::CalculateMedianATR(int lookback, ENUM_TIMEFRAMES tf)
{
   if(lookback <= 0)
      return 0.0;

   double atr_values[];
   ArrayResize(atr_values, lookback);

   for(int i = 0; i < lookback; i++)
   {
      double atr = iATR_v(_Symbol, tf, m_atr_period, i + 1);
      if(atr == 0)
      {
         Print("WARNING: ATR at bar ", i + 1, " is 0");
         return 0.0;
      }
      atr_values[i] = atr;
   }

   ArraySort(atr_values);

   int mid = lookback / 2;
   if(lookback % 2 == 0)
   {
      return (atr_values[mid - 1] + atr_values[mid]) / 2.0;
   }
   else
   {
      return atr_values[mid];
   }
}

//+------------------------------------------------------------------+
double CircuitBreaker::GetCurrentSpreadPips()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double spread_points = (ask - bid) / point;

   return spread_points / 10.0;
}

//+------------------------------------------------------------------+
bool CircuitBreaker::DetectGap(double atr_value)
{
   if(Bars(_Symbol, PERIOD_M15) < 2)
      return false;

   double close_prev = iClose(_Symbol, PERIOD_M15, 1);
   double open_current = iOpen(_Symbol, PERIOD_M15, 0);

   double gap = MathAbs(open_current - close_prev);

   double gap_threshold = atr_value * 2.0;

   if(gap > gap_threshold)
   {
      Print("Gap detected: ", gap, " > ", gap_threshold, " (2x ATR)");
      return true;
   }

   return false;
}
