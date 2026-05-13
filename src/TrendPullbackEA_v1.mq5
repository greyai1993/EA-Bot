//+------------------------------------------------------------------+
//|                                      TrendPullbackEA_v1.mq5     |
//|                                  Grey / Violet AI               |
//|                                  https://github.com/greyai1993  |
//+------------------------------------------------------------------+
#property copyright "Grey / Violet AI"
#property link      "https://github.com/greyai1993/EA-Bot"
#property version   "1.00"
#property description "XAUUSD Multi-Strategy Expert Advisor - Research Framework"
#property strict

#include "include/IndicatorHelpers.mqh"
#include "include/RiskManager.mqh"
#include "include/Logger.mqh"
#include "include/CircuitBreaker.mqh"
#include "include/StrategyVariants.mqh"

//+------------------------------------------------------------------+
//| Input Parameters - Strategy Selection                            |
//+------------------------------------------------------------------+
input ENUM_STRATEGY_VARIANT InpStrategyVariant = VARIANT_A;  // Strategy Variant (A/B/C/D)

//+------------------------------------------------------------------+
//| Input Parameters - Trading Mode                                  |
//+------------------------------------------------------------------+
enum ENUM_TRADING_MODE
{
   MODE_ALERTS_ONLY,    // Alerts Only (no actual trades)
   MODE_AUTO_TRADE,     // Auto Trading
   MODE_PAUSED          // Paused
};

input ENUM_TRADING_MODE InpTradingMode = MODE_ALERTS_ONLY;  // Trading Mode

//+------------------------------------------------------------------+
//| Input Parameters - EMA Settings                                  |
//+------------------------------------------------------------------+
input int InpEMA_Trend = 200;        // EMA Trend Period (H1)
input int InpEMA_Fast = 50;          // EMA Fast Period (M15)
input int InpEMA_Entry = 20;         // EMA Entry Period (M15)

//+------------------------------------------------------------------+
//| Input Parameters - RSI Settings                                  |
//+------------------------------------------------------------------+
input int InpRSI_Period = 14;        // RSI Period
input double InpRSI_Oversold = 30.0; // RSI Oversold Level
input double InpRSI_Overbought = 70.0; // RSI Overbought Level

//+------------------------------------------------------------------+
//| Input Parameters - ADX Settings                                  |
//+------------------------------------------------------------------+
input double InpADX_Min = 20.0;      // ADX Minimum for Trend

//+------------------------------------------------------------------+
//| Input Parameters - ATR Settings                                  |
//+------------------------------------------------------------------+
input int InpATR_Period = 14;        // ATR Period
input double InpSL_ATR_Multiplier = 1.5;    // SL ATR Multiplier
input double InpTP_ATR_Multiplier = 2.0;    // TP ATR Multiplier
input double InpTrailing_ATR_Multiplier = 1.0; // Trailing Stop ATR Multiplier

//+------------------------------------------------------------------+
//| Input Parameters - Risk Management                               |
//+------------------------------------------------------------------+
input double InpRiskPercent = 0.25;           // Risk Per Trade (%)
input double InpDailyLossCap = 1.5;           // Daily Loss Cap (%)
input double InpWeeklyLossCap = 4.0;          // Weekly Loss Cap (%)
input double InpMaxDrawdown = 12.0;           // Max Drawdown (%)
input int InpMaxConsecutiveLosses = 5;        // Max Consecutive Losses
input int InpMaxTradesPerDay = 6;             // Max Trades Per Day

//+------------------------------------------------------------------+
//| Input Parameters - Circuit Breaker                               |
//+------------------------------------------------------------------+
input int InpCB_ATR_Lookback = 20;            // Circuit Breaker ATR Lookback
input double InpCB_ATR_Multiplier = 2.0;      // Circuit Breaker ATR Spike Multiplier
input double InpCB_SpreadThreshold = 5.0;     // Circuit Breaker Spread Threshold (pips)
input int InpCB_PauseDuration = 15;           // Circuit Breaker Pause Duration (minutes)

//+------------------------------------------------------------------+
//| Input Parameters - Execution Guards                              |
//+------------------------------------------------------------------+
input double InpMaxSpreadPips = 3.0;          // Max Spread (pips)
input int InpMaxSlippagePips = 5;             // Max Slippage (pips)
input double InpMinMarginLevel = 200.0;       // Min Margin Level (%)
input bool InpFridayAutoClose = true;         // Friday Auto Close
input int InpFridayCloseHour = 21;            // Friday Close Hour (server time)

//+------------------------------------------------------------------+
//| Input Parameters - Position Management                           |
//+------------------------------------------------------------------+
input bool InpUseBreakeven = true;            // Use Breakeven
input double InpBreakevenTriggerR = 1.0;      // Breakeven Trigger (R multiple)
input double InpBreakevenOffset = 0.5;        // Breakeven Offset (R multiple)
input bool InpUseTrailingStop = true;         // Use Trailing Stop
input double InpTrailingTriggerR = 1.5;       // Trailing Stop Trigger (R multiple)

//+------------------------------------------------------------------+
//| Input Parameters - Logging                                       |
//+------------------------------------------------------------------+
input bool InpEnableLogging = true;           // Enable CSV Logging

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
RiskManager *g_risk;
Logger *g_logger;
CircuitBreaker *g_circuit;
StrategyVariants *g_strategy;

int g_magic_number = 20240513;
bool g_initialized = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TrendPullbackEA v1.0 Initializing ===");

   g_risk = new RiskManager();
   g_logger = new Logger();
   g_circuit = new CircuitBreaker();
   g_strategy = new StrategyVariants();

   if(!g_risk.Initialize(InpRiskPercent, InpDailyLossCap, InpWeeklyLossCap,
                          InpMaxDrawdown, InpMaxConsecutiveLosses, InpMaxTradesPerDay))
   {
      Print("ERROR: Failed to initialize RiskManager");
      return INIT_FAILED;
   }

   if(InpEnableLogging)
   {
      string variant_name = "";
      switch(InpStrategyVariant)
      {
         case VARIANT_A: variant_name = "VariantA"; break;
         case VARIANT_B: variant_name = "VariantB"; break;
         case VARIANT_C: variant_name = "VariantC"; break;
         case VARIANT_D: variant_name = "VariantD"; break;
      }

      if(!g_logger.Initialize(variant_name))
      {
         Print("WARNING: Failed to initialize Logger");
      }
   }

   if(!g_circuit.Initialize(InpATR_Period, InpCB_ATR_Lookback, InpCB_ATR_Multiplier,
                             InpCB_SpreadThreshold, InpCB_PauseDuration))
   {
      Print("ERROR: Failed to initialize CircuitBreaker");
      return INIT_FAILED;
   }

   if(!g_strategy.Initialize(InpEMA_Trend, InpEMA_Fast, InpEMA_Entry,
                              InpRSI_Period, InpRSI_Oversold, InpRSI_Overbought,
                              InpADX_Min))
   {
      Print("ERROR: Failed to initialize StrategyVariants");
      return INIT_FAILED;
   }

   g_initialized = true;

   string mode_str = "";
   switch(InpTradingMode)
   {
      case MODE_ALERTS_ONLY: mode_str = "ALERTS_ONLY"; break;
      case MODE_AUTO_TRADE: mode_str = "AUTO_TRADE"; break;
      case MODE_PAUSED: mode_str = "PAUSED"; break;
   }

   Print("=== Initialization Complete ===");
   Print("Mode: ", mode_str);
   Print("Variant: ", InpStrategyVariant);
   Print("Risk: ", InpRiskPercent, "%");
   Print("Symbol: ", _Symbol);
   Print("=============================");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== TrendPullbackEA v1.0 Deinitializing ===");

   if(g_logger != NULL)
   {
      g_logger.Close();
      delete g_logger;
   }

   if(g_risk != NULL)
      delete g_risk;

   if(g_circuit != NULL)
      delete g_circuit;

   if(g_strategy != NULL)
      delete g_strategy;

   Print("=== Deinitialization Complete ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized)
      return;

   if(InpTradingMode == MODE_PAUSED)
      return;

   ManagePositions();

   if(HasOpenPosition())
      return;

   string cb_reason;
   if(g_circuit.IsVolatilityHigh(cb_reason))
   {
      if(!g_circuit.IsPaused())
      {
         g_circuit.TriggerPause(cb_reason);
         g_logger.LogCircuitBreaker("PAUSE_TRIGGERED", cb_reason);
      }
      return;
   }

   string risk_reason;
   if(!g_risk.CanTrade(risk_reason))
   {
      g_logger.LogRiskBlock(risk_reason);
      return;
   }

   if(!CheckExecutionGuards())
      return;

   CheckEntrySignals();
}

//+------------------------------------------------------------------+
//| Check Entry Signals                                               |
//+------------------------------------------------------------------+
void CheckEntrySignals()
{
   ENUM_SIGNAL signal = g_strategy.GetSignal(InpStrategyVariant);

   if(signal == SIGNAL_NONE)
      return;

   string signal_reason = g_strategy.GetSignalReason();
   double current_price = (signal == SIGNAL_LONG) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(InpTradingMode == MODE_ALERTS_ONLY)
   {
      string direction = (signal == SIGNAL_LONG) ? "LONG" : "SHORT";
      g_logger.LogSignal(GetVariantName(), direction, signal_reason, current_price);
      return;
   }

   if(InpTradingMode == MODE_AUTO_TRADE)
   {
      if(signal == SIGNAL_LONG)
         OpenLongPosition(signal_reason);
      else if(signal == SIGNAL_SHORT)
         OpenShortPosition(signal_reason);
   }
}

//+------------------------------------------------------------------+
//| Open Long Position                                                |
//+------------------------------------------------------------------+
void OpenLongPosition(string signal_reason)
{
   double atr = iATR_v(_Symbol, PERIOD_H1, InpATR_Period, 0);
   double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = entry - (atr * InpSL_ATR_Multiplier);
   double tp = entry + (atr * InpTP_ATR_Multiplier);

   double sl_pips = (entry - sl) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10.0;
   double lot_size = g_risk.CalculateLotSize(sl_pips);

   if(lot_size <= 0)
   {
      Print("ERROR: Invalid lot size calculated");
      return;
   }

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot_size;
   request.type = ORDER_TYPE_BUY;
   request.price = entry;
   request.sl = sl;
   request.tp = tp;
   request.deviation = InpMaxSlippagePips;
   request.magic = g_magic_number;
   request.comment = signal_reason;

   if(!OrderSend(request, result))
   {
      Print("ERROR: OrderSend failed - ", result.retcode);
      return;
   }

   Print("LONG position opened - Ticket: ", result.order, " @ ", entry);
}

//+------------------------------------------------------------------+
//| Open Short Position                                               |
//+------------------------------------------------------------------+
void OpenShortPosition(string signal_reason)
{
   double atr = iATR_v(_Symbol, PERIOD_H1, InpATR_Period, 0);
   double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = entry + (atr * InpSL_ATR_Multiplier);
   double tp = entry - (atr * InpTP_ATR_Multiplier);

   double sl_pips = (sl - entry) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10.0;
   double lot_size = g_risk.CalculateLotSize(sl_pips);

   if(lot_size <= 0)
   {
      Print("ERROR: Invalid lot size calculated");
      return;
   }

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot_size;
   request.type = ORDER_TYPE_SELL;
   request.price = entry;
   request.sl = sl;
   request.tp = tp;
   request.deviation = InpMaxSlippagePips;
   request.magic = g_magic_number;
   request.comment = signal_reason;

   if(!OrderSend(request, result))
   {
      Print("ERROR: OrderSend failed - ", result.retcode);
      return;
   }

   Print("SHORT position opened - Ticket: ", result.order, " @ ", entry);
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                             |
//+------------------------------------------------------------------+
void ManagePositions()
{
   if(InpFridayAutoClose)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);

      if(dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour)
      {
         CloseAllPositions("Friday auto-close");
         return;
      }
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != g_magic_number)
         continue;

      double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      double initial_risk = MathAbs(entry_price - sl);
      double current_profit_r = 0;

      if(pos_type == POSITION_TYPE_BUY)
         current_profit_r = (current_price - entry_price) / initial_risk;
      else
         current_profit_r = (entry_price - current_price) / initial_risk;

      if(InpUseBreakeven && current_profit_r >= InpBreakevenTriggerR)
      {
         double new_sl = entry_price + (initial_risk * InpBreakevenOffset);
         if(pos_type == POSITION_TYPE_BUY && new_sl > sl)
            ModifySL(ticket, new_sl);
         else if(pos_type == POSITION_TYPE_SELL && new_sl < sl)
            ModifySL(ticket, new_sl);
      }

      if(InpUseTrailingStop && current_profit_r >= InpTrailingTriggerR)
      {
         double atr = iATR_v(_Symbol, PERIOD_H1, InpATR_Period, 0);
         double trailing_distance = atr * InpTrailing_ATR_Multiplier;

         double new_sl;
         if(pos_type == POSITION_TYPE_BUY)
         {
            new_sl = current_price - trailing_distance;
            if(new_sl > sl)
               ModifySL(ticket, new_sl);
         }
         else
         {
            new_sl = current_price + trailing_distance;
            if(new_sl < sl)
               ModifySL(ticket, new_sl);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Modify Stop Loss                                                  |
//+------------------------------------------------------------------+
void ModifySL(ulong ticket, double new_sl)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.sl = new_sl;
   request.tp = PositionGetDouble(POSITION_TP);

   if(!OrderSend(request, result))
   {
      Print("ERROR: Failed to modify SL - ", result.retcode);
   }
}

//+------------------------------------------------------------------+
//| Close All Positions                                               |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != g_magic_number)
         continue;

      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_DEAL;
      request.position = ticket;
      request.symbol = _Symbol;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price = (request.type == ORDER_TYPE_SELL) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      request.deviation = InpMaxSlippagePips;
      request.magic = g_magic_number;

      if(!OrderSend(request, result))
      {
         Print("ERROR: Failed to close position - ", result.retcode);
      }
      else
      {
         Print("Position closed - ", reason);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if Has Open Position                                        |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i) <= 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == g_magic_number)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check Execution Guards                                            |
//+------------------------------------------------------------------+
bool CheckExecutionGuards()
{
   double spread_pips = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10.0;

   if(spread_pips > InpMaxSpreadPips)
   {
      return false;
   }

   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(margin_level > 0 && margin_level < InpMinMarginLevel)
   {
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Get Variant Name                                                  |
//+------------------------------------------------------------------+
string GetVariantName()
{
   switch(InpStrategyVariant)
   {
      case VARIANT_A: return "Variant_A";
      case VARIANT_B: return "Variant_B";
      case VARIANT_C: return "Variant_C";
      case VARIANT_D: return "Variant_D";
      default: return "Unknown";
   }
}
