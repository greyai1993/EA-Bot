//+------------------------------------------------------------------+
//|                                          RiskManager.mqh        |
//|                                  Grey / Violet AI               |
//+------------------------------------------------------------------+
#property copyright "Grey / Violet AI"
#property link      "https://github.com/greyai1993/EA-Bot"
#property strict

class RiskManager
{
private:
   double m_risk_percent;
   double m_daily_loss_cap;
   double m_weekly_loss_cap;
   double m_max_drawdown_percent;
   int    m_max_consecutive_losses;
   int    m_max_trades_per_day;

   double m_equity_peak;
   double m_daily_profit;
   double m_weekly_profit;
   int    m_daily_trade_count;
   int    m_consecutive_losses;

   datetime m_last_reset_day;
   datetime m_last_reset_week;

   bool LoadEquityPeak();
   bool SaveEquityPeak();

public:
   RiskManager();
   ~RiskManager();

   bool Initialize(double risk_pct, double daily_cap, double weekly_cap,
                   double max_dd, int max_consec_losses, int max_trades_day);

   double CalculateLotSize(double sl_pips);
   bool CanTrade(string &reason);
   double CalculateEquityDD();
   void OnTradeResult(double profit, bool is_win);
   void CheckAndResetCounters();

   double GetEquityPeak() { return m_equity_peak; }
   double GetDailyProfit() { return m_daily_profit; }
   double GetWeeklyProfit() { return m_weekly_profit; }
   int GetDailyTradeCount() { return m_daily_trade_count; }
   int GetConsecutiveLosses() { return m_consecutive_losses; }
};

//+------------------------------------------------------------------+
RiskManager::RiskManager()
{
   m_risk_percent = 0.25;
   m_daily_loss_cap = 1.5;
   m_weekly_loss_cap = 4.0;
   m_max_drawdown_percent = 12.0;
   m_max_consecutive_losses = 5;
   m_max_trades_per_day = 6;

   m_equity_peak = 0.0;
   m_daily_profit = 0.0;
   m_weekly_profit = 0.0;
   m_daily_trade_count = 0;
   m_consecutive_losses = 0;

   m_last_reset_day = 0;
   m_last_reset_week = 0;
}

//+------------------------------------------------------------------+
RiskManager::~RiskManager()
{
   SaveEquityPeak();
}

//+------------------------------------------------------------------+
bool RiskManager::Initialize(double risk_pct, double daily_cap, double weekly_cap,
                              double max_dd, int max_consec_losses, int max_trades_day)
{
   m_risk_percent = risk_pct;
   m_daily_loss_cap = daily_cap;
   m_weekly_loss_cap = weekly_cap;
   m_max_drawdown_percent = max_dd;
   m_max_consecutive_losses = max_consec_losses;
   m_max_trades_per_day = max_trades_day;

   if(!LoadEquityPeak())
   {
      m_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
      SaveEquityPeak();
   }

   m_last_reset_day = TimeCurrent();
   m_last_reset_week = TimeCurrent();

   Print("RiskManager initialized - Risk: ", m_risk_percent, "%, Daily Cap: ",
         m_daily_loss_cap, "%, Weekly Cap: ", m_weekly_loss_cap, "%");

   return true;
}

//+------------------------------------------------------------------+
double RiskManager::CalculateLotSize(double sl_pips)
{
   if(sl_pips <= 0)
   {
      Print("ERROR: Invalid SL pips = ", sl_pips);
      return 0.0;
   }

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = equity * (m_risk_percent / 100.0);

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double sl_distance = sl_pips * point;
   double risk_per_lot = (sl_distance / tick_size) * tick_value;

   double lot_size = risk_amount / risk_per_lot;

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot_size = MathFloor(lot_size / lot_step) * lot_step;
   lot_size = MathMax(lot_size, min_lot);
   lot_size = MathMin(lot_size, max_lot);

   return lot_size;
}

//+------------------------------------------------------------------+
bool RiskManager::CanTrade(string &reason)
{
   CheckAndResetCounters();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   if(m_equity_peak > 0)
   {
      if(equity > m_equity_peak)
      {
         m_equity_peak = equity;
         SaveEquityPeak();
      }
   }
   else
   {
      m_equity_peak = equity;
      SaveEquityPeak();
   }

   double dd_percent = CalculateEquityDD();
   if(dd_percent >= m_max_drawdown_percent)
   {
      reason = StringFormat("Max DD reached: %.2f%% >= %.2f%%", dd_percent, m_max_drawdown_percent);
      return false;
   }

   double daily_loss_pct = (m_daily_profit / m_equity_peak) * 100.0;
   if(daily_loss_pct <= -m_daily_loss_cap)
   {
      reason = StringFormat("Daily loss cap hit: %.2f%% <= -%.2f%%", daily_loss_pct, m_daily_loss_cap);
      return false;
   }

   double weekly_loss_pct = (m_weekly_profit / m_equity_peak) * 100.0;
   if(weekly_loss_pct <= -m_weekly_loss_cap)
   {
      reason = StringFormat("Weekly loss cap hit: %.2f%% <= -%.2f%%", weekly_loss_pct, m_weekly_loss_cap);
      return false;
   }

   if(m_consecutive_losses >= m_max_consecutive_losses)
   {
      reason = StringFormat("Max consecutive losses: %d >= %d", m_consecutive_losses, m_max_consecutive_losses);
      return false;
   }

   if(m_daily_trade_count >= m_max_trades_per_day)
   {
      reason = StringFormat("Max trades/day reached: %d >= %d", m_daily_trade_count, m_max_trades_per_day);
      return false;
   }

   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

   if(margin_level > 0 && margin_level < 200.0)
   {
      reason = StringFormat("Low margin level: %.2f%% < 200%%", margin_level);
      return false;
   }

   reason = "OK";
   return true;
}

//+------------------------------------------------------------------+
double RiskManager::CalculateEquityDD()
{
   if(m_equity_peak <= 0)
      return 0.0;

   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd_percent = ((m_equity_peak - current_equity) / m_equity_peak) * 100.0;

   return MathMax(dd_percent, 0.0);
}

//+------------------------------------------------------------------+
void RiskManager::OnTradeResult(double profit, bool is_win)
{
   m_daily_profit += profit;
   m_weekly_profit += profit;
   m_daily_trade_count++;

   if(is_win)
   {
      m_consecutive_losses = 0;
   }
   else
   {
      m_consecutive_losses++;
   }

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > m_equity_peak)
   {
      m_equity_peak = equity;
      SaveEquityPeak();
   }
}

//+------------------------------------------------------------------+
void RiskManager::CheckAndResetCounters()
{
   datetime now = TimeCurrent();
   MqlDateTime dt_now, dt_last_day;

   TimeToStruct(now, dt_now);
   TimeToStruct(m_last_reset_day, dt_last_day);

   if(dt_now.day != dt_last_day.day || dt_now.mon != dt_last_day.mon || dt_now.year != dt_last_day.year)
   {
      m_daily_profit = 0.0;
      m_daily_trade_count = 0;
      m_last_reset_day = now;
      Print("Daily counters reset");
   }

   MqlDateTime dt_last_week;
   TimeToStruct(m_last_reset_week, dt_last_week);

   if(dt_now.day_of_week == 1 && dt_last_week.day_of_week != 1)
   {
      m_weekly_profit = 0.0;
      m_last_reset_week = now;
      Print("Weekly counters reset");
   }
}

//+------------------------------------------------------------------+
bool RiskManager::LoadEquityPeak()
{
   int file_handle = FileOpen("EA_EquityPeak.dat", FILE_READ|FILE_BIN);
   if(file_handle == INVALID_HANDLE)
      return false;

   m_equity_peak = FileReadDouble(file_handle);
   FileClose(file_handle);

   Print("Equity peak loaded: ", m_equity_peak);
   return true;
}

//+------------------------------------------------------------------+
bool RiskManager::SaveEquityPeak()
{
   int file_handle = FileOpen("EA_EquityPeak.dat", FILE_WRITE|FILE_BIN);
   if(file_handle == INVALID_HANDLE)
      return false;

   FileWriteDouble(file_handle, m_equity_peak);
   FileClose(file_handle);

   return true;
}
