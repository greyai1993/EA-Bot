//+------------------------------------------------------------------+
//|                                             Logger.mqh          |
//|                                  Grey / Violet AI               |
//+------------------------------------------------------------------+
#property copyright "Grey / Violet AI"
#property link      "https://github.com/greyai1993/EA-Bot"
#property strict

class Logger
{
private:
   int m_file_handle;
   string m_csv_filename;
   bool m_is_initialized;

   string GetTimestamp();

public:
   Logger();
   ~Logger();

   bool Initialize(string variant_name);
   void Close();

   void LogTrade(string variant, string signal_reason, string direction,
                 datetime entry_time, double entry_price, double sl, double tp, double lot_size,
                 datetime exit_time, double exit_price, string exit_reason,
                 double profit, double r_multiple, double balance, double dd_percent);

   void LogSignal(string variant, string direction, string reason, double price);
   void LogRiskBlock(string reason);
   void LogCircuitBreaker(string event, string details);
};

//+------------------------------------------------------------------+
Logger::Logger()
{
   m_file_handle = INVALID_HANDLE;
   m_csv_filename = "";
   m_is_initialized = false;
}

//+------------------------------------------------------------------+
Logger::~Logger()
{
   Close();
}

//+------------------------------------------------------------------+
bool Logger::Initialize(string variant_name)
{
   if(m_is_initialized)
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   m_csv_filename = StringFormat("EA_Trades_%s_%04d%02d%02d.csv",
                                  variant_name,
                                  dt.year, dt.mon, dt.day);

   m_file_handle = FileOpen(m_csv_filename, FILE_WRITE|FILE_READ|FILE_CSV|FILE_ANSI, ',');

   if(m_file_handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create CSV file: ", m_csv_filename);
      return false;
   }

   if(FileSize(m_file_handle) == 0)
   {
      FileWrite(m_file_handle,
                "Timestamp",
                "Variant",
                "Signal_Reason",
                "Direction",
                "Entry_Time",
                "Entry_Price",
                "SL",
                "TP",
                "Lot_Size",
                "Exit_Time",
                "Exit_Price",
                "Exit_Reason",
                "Profit",
                "R_Multiple",
                "Balance",
                "DD_Percent");
   }

   m_is_initialized = true;
   Print("Logger initialized - CSV: ", m_csv_filename);

   return true;
}

//+------------------------------------------------------------------+
void Logger::Close()
{
   if(m_file_handle != INVALID_HANDLE)
   {
      FileClose(m_file_handle);
      m_file_handle = INVALID_HANDLE;
      m_is_initialized = false;
   }
}

//+------------------------------------------------------------------+
void Logger::LogTrade(string variant, string signal_reason, string direction,
                      datetime entry_time, double entry_price, double sl, double tp, double lot_size,
                      datetime exit_time, double exit_price, string exit_reason,
                      double profit, double r_multiple, double balance, double dd_percent)
{
   if(!m_is_initialized || m_file_handle == INVALID_HANDLE)
      return;

   FileSeek(m_file_handle, 0, SEEK_END);

   FileWrite(m_file_handle,
             GetTimestamp(),
             variant,
             signal_reason,
             direction,
             TimeToString(entry_time, TIME_DATE|TIME_SECONDS),
             DoubleToString(entry_price, _Digits),
             DoubleToString(sl, _Digits),
             DoubleToString(tp, _Digits),
             DoubleToString(lot_size, 2),
             TimeToString(exit_time, TIME_DATE|TIME_SECONDS),
             DoubleToString(exit_price, _Digits),
             exit_reason,
             DoubleToString(profit, 2),
             DoubleToString(r_multiple, 2),
             DoubleToString(balance, 2),
             DoubleToString(dd_percent, 2));

   FileFlush(m_file_handle);
}

//+------------------------------------------------------------------+
void Logger::LogSignal(string variant, string direction, string reason, double price)
{
   string log_msg = StringFormat("[SIGNAL] %s %s @ %.2f - %s",
                                  variant, direction, price, reason);

   Print(log_msg);

   int signal_file = FileOpen("EA_Signals.log", FILE_WRITE|FILE_READ|FILE_ANSI|FILE_TXT);
   if(signal_file != INVALID_HANDLE)
   {
      FileSeek(signal_file, 0, SEEK_END);
      FileWriteString(signal_file, GetTimestamp() + " " + log_msg + "\n");
      FileClose(signal_file);
   }
}

//+------------------------------------------------------------------+
void Logger::LogRiskBlock(string reason)
{
   string log_msg = StringFormat("[RISK_BLOCK] %s", reason);

   Print(log_msg);

   int risk_file = FileOpen("EA_RiskBlocks.log", FILE_WRITE|FILE_READ|FILE_ANSI|FILE_TXT);
   if(risk_file != INVALID_HANDLE)
   {
      FileSeek(risk_file, 0, SEEK_END);
      FileWriteString(risk_file, GetTimestamp() + " " + log_msg + "\n");
      FileClose(risk_file);
   }
}

//+------------------------------------------------------------------+
void Logger::LogCircuitBreaker(string event, string details)
{
   string log_msg = StringFormat("[CIRCUIT_BREAKER] %s - %s", event, details);

   Print(log_msg);

   int cb_file = FileOpen("EA_CircuitBreaker.log", FILE_WRITE|FILE_READ|FILE_ANSI|FILE_TXT);
   if(cb_file != INVALID_HANDLE)
   {
      FileSeek(cb_file, 0, SEEK_END);
      FileWriteString(cb_file, GetTimestamp() + " " + log_msg + "\n");
      FileClose(cb_file);
   }
}

//+------------------------------------------------------------------+
string Logger::GetTimestamp()
{
   return TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
}
