//+------------------------------------------------------------------+
//|                                    IndicatorHelpers.mqh          |
//|                                  Grey / Violet AI                |
//|  MT5 wrappers: emulate MT4-style indicator calls via cached      |
//|  handles + CopyBuffer. Returns a value at the requested shift.   |
//+------------------------------------------------------------------+
#ifndef __INDICATOR_HELPERS_MQH__
#define __INDICATOR_HELPERS_MQH__

#define IND_CACHE_MAX 32

struct IndHandle
{
   string key;
   int    handle;
};

IndHandle g_ind_cache[IND_CACHE_MAX];
int       g_ind_cache_n = 0;

int IndLookup(string key)
{
   for(int i = 0; i < g_ind_cache_n; i++)
      if(g_ind_cache[i].key == key)
         return g_ind_cache[i].handle;
   return INVALID_HANDLE;
}

int IndStore(string key, int h)
{
   if(g_ind_cache_n < IND_CACHE_MAX)
   {
      g_ind_cache[g_ind_cache_n].key    = key;
      g_ind_cache[g_ind_cache_n].handle = h;
      g_ind_cache_n++;
   }
   return h;
}

double IndRead(int h, int buffer, int shift)
{
   if(h == INVALID_HANDLE) return 0.0;
   double buf[];
   if(CopyBuffer(h, buffer, shift, 1, buf) <= 0) return 0.0;
   return buf[0];
}

//+------------------------------------------------------------------+
//| iATR_v(symbol, tf, period, shift)                                |
//+------------------------------------------------------------------+
double iATR_v(string symbol, ENUM_TIMEFRAMES tf, int period, int shift)
{
   string key = "ATR|" + symbol + "|" + IntegerToString((int)tf) + "|" + IntegerToString(period);
   int h = IndLookup(key);
   if(h == INVALID_HANDLE) h = IndStore(key, iATR(symbol, tf, period));
   return IndRead(h, 0, shift);
}

//+------------------------------------------------------------------+
//| iMA_v(symbol, tf, period, ma_shift, method, price, shift)        |
//+------------------------------------------------------------------+
double iMA_v(string symbol, ENUM_TIMEFRAMES tf, int period, int ma_shift,
             ENUM_MA_METHOD method, ENUM_APPLIED_PRICE price, int shift)
{
   string key = "MA|" + symbol + "|" + IntegerToString((int)tf) + "|"
              + IntegerToString(period) + "|" + IntegerToString(ma_shift) + "|"
              + IntegerToString((int)method) + "|" + IntegerToString((int)price);
   int h = IndLookup(key);
   if(h == INVALID_HANDLE) h = IndStore(key, iMA(symbol, tf, period, ma_shift, method, price));
   return IndRead(h, 0, shift);
}

//+------------------------------------------------------------------+
//| iRSI_v(symbol, tf, period, price, shift)                         |
//+------------------------------------------------------------------+
double iRSI_v(string symbol, ENUM_TIMEFRAMES tf, int period, ENUM_APPLIED_PRICE price, int shift)
{
   string key = "RSI|" + symbol + "|" + IntegerToString((int)tf) + "|"
              + IntegerToString(period) + "|" + IntegerToString((int)price);
   int h = IndLookup(key);
   if(h == INVALID_HANDLE) h = IndStore(key, iRSI(symbol, tf, period, price));
   return IndRead(h, 0, shift);
}

//+------------------------------------------------------------------+
//| iADX_v(symbol, tf, period, buffer, shift)                        |
//| buffer: 0=MAIN (ADX), 1=PLUSDI, 2=MINUSDI                        |
//+------------------------------------------------------------------+
double iADX_v(string symbol, ENUM_TIMEFRAMES tf, int period, int buffer, int shift)
{
   string key = "ADX|" + symbol + "|" + IntegerToString((int)tf) + "|" + IntegerToString(period);
   int h = IndLookup(key);
   if(h == INVALID_HANDLE) h = IndStore(key, iADX(symbol, tf, period));
   return IndRead(h, buffer, shift);
}

#endif // __INDICATOR_HELPERS_MQH__
