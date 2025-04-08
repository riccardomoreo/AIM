//+------------------------------------------------------------------+
//|  FTMO Assistant                                                  |
//+------------------------------------------------------------------+

#property copyright "Riccardo Moreo"
#property strict
#property icon   "AIM.ico"
#property version   "2.50"

#include<Trade/Trade.mqh>
CTrade trade;
CPositionInfo position;
CObject object;
CHistoryOrderInfo info;
CDealInfo dealinfo;

//+------------------------------------------------------------------+
//|  News Class                                                      |
//+------------------------------------------------------------------+

enum Importanza
  {
   Bassa = 0,// Low
   Media = 1,// Medium
   Alta = 2,// High
  };

enum Valute
  {
   USD = 0,
   EUR = 1,
   GBP = 2,
   AUD = 3,
   CYN = 4,
   CHF = 5,
   NZD = 6,
   BRL = 7,
   KRW = 8,
  };
  
//News Class//

class CNews
  {
private:
   struct EventStruct
     {
      ulong          value_id;
      ulong          event_id;
      datetime       time;
      datetime       period;
      int            revision;
      long           actual_value;
      long           prev_value;
      long           revised_prev_value;
      long           forecast_value;
      ENUM_CALENDAR_EVENT_IMPACT impact_type;
      ENUM_CALENDAR_EVENT_TYPE event_type;
      ENUM_CALENDAR_EVENT_SECTOR sector;
      ENUM_CALENDAR_EVENT_FREQUENCY frequency;
      ENUM_CALENDAR_EVENT_TIMEMODE timemode;
      ENUM_CALENDAR_EVENT_IMPORTANCE importance;
      ENUM_CALENDAR_EVENT_MULTIPLIER multiplier;
      ENUM_CALENDAR_EVENT_UNIT unit;
      uint           digits;
      ulong          country_id;
     };
   string            future_eventname[];
   MqlDateTime       tm;
   datetime          servertime;

public:
   datetime          GMT(ushort server_offset_winter,ushort server_offset_summer);
   EventStruct       event[];
   string            eventname[];
   int               SaveHistory(bool printlog_info=false);
   int               LoadHistory(bool printlog_info=false);
   int               update(int interval_seconds,bool printlog_info=false);
   int               next(int pointer_start,string currency,bool show_on_chart,long chart_id);
   int               GetNextNewsEvent(int pointer_start, string currency, Importanza importance);
   int               CurrencyToCountryId(string currency);   
   datetime          last_update;
   ushort            GMT_offset_winter;
   ushort            GMT_offset_summer;

                     CNews(void)
     {
      ArrayResize(event,100000,0);
      ZeroMemory(event);
      ArrayResize(eventname,100000,0);
      ZeroMemory(eventname);
      ArrayResize(future_eventname,100000,0);
      ZeroMemory(future_eventname);
      last_update=0;
      SaveHistory(true);
      LoadHistory(true);
     }
                    ~CNews(void) {};
  };

//Dichiarazione Struct//

CNews news;

//Update News Events//

int CNews::update(int interval_seconds=60,bool printlog_info=false)
  {
   static datetime last_time=0;
   static int total_events=0;
   if(TimeCurrent()<last_time+interval_seconds)
     {
      return total_events;
     }
   SaveHistory(printlog_info);
   total_events=LoadHistory(printlog_info);
   last_time=TimeCurrent();
   return total_events;
  }
//Currency to Country id//

int CNews::CurrencyToCountryId(string currency)
  {
   if (currency=="EUR"){return 999;}
   if (currency=="USD"){return 840;}
   if (currency=="AUD"){return 36;}
   if (currency=="NZD"){return 554;}
   if (currency=="CYN"){return 156;}
   if (currency=="GBP"){return 826;}
   if (currency=="CHF"){return 756;}
   if (currency=="BRL"){return 76;}
   if (currency=="KRW"){return 410;}
   return 0;
  }

//Grab News History & Save It//

int CNews::SaveHistory(bool printlog_info=false)
  {
   datetime tm_gmt=GMT(GMT_offset_winter,GMT_offset_summer);
   int filehandle;

   if(!FileIsExist("news\\newshistory.bin",FILE_COMMON))
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      if(filehandle!=INVALID_HANDLE)
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": creating new file common/files/news/newshistory.bin");
           }
        }
      else
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,"invalid filehandle, can't create news history file");
           }
         return 0;
        }
      FileSeek(filehandle,0,SEEK_SET);
      FileWriteLong(filehandle,(long)last_update);
     }
   else
     {
      filehandle=FileOpen("news\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      FileSeek(filehandle,0,SEEK_SET);
      last_update=(datetime)FileReadLong(filehandle);
      if(filehandle!=INVALID_HANDLE)
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": previous newshistory file found in common/files; history update starts from ",last_update," GMT");
           }
        }
      else
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": invalid filehandle; can't open previous news history file");
           };
         return 0;
        }
      bool from_beginning=FileSeek(filehandle,0,SEEK_END);
      if(!from_beginning)
        {
         Print(__FUNCTION__": unable to go to the file's beginning");
        }
     }
   if(last_update>tm_gmt)
     {
      if(printlog_info)
        {
         Print(__FUNCTION__,": time of last news update is in the future relative to timestamp of request; the existing data won't be overwritten/replaced,",
               "\nexecution of function therefore prohibited; only future events relative to this timestamp will be loaded");
        }
      return 0;
     }

   MqlCalendarValue eventvaluebuffer[];
   ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;
   ZeroMemory(eventbuffer);
   CalendarValueHistory(eventvaluebuffer,last_update,tm_gmt);

   int number_of_events=ArraySize(eventvaluebuffer);
   int saved_elements=0;
   if(number_of_events>=ArraySize(event))
     {
      ArrayResize(event,number_of_events,0);
     }
   for(int i=0;i<number_of_events;i++)
     {
      event[i].value_id          =  eventvaluebuffer[i].id;
      event[i].event_id          =  eventvaluebuffer[i].event_id;
      event[i].time              =  eventvaluebuffer[i].time;
      event[i].period            =  eventvaluebuffer[i].period;
      event[i].revision          =  eventvaluebuffer[i].revision;
      event[i].actual_value      =  eventvaluebuffer[i].actual_value;
      event[i].prev_value        =  eventvaluebuffer[i].prev_value;
      event[i].revised_prev_value=  eventvaluebuffer[i].revised_prev_value;
      event[i].forecast_value    =  eventvaluebuffer[i].forecast_value;
      event[i].impact_type       =  eventvaluebuffer[i].impact_type;

      CalendarEventById(eventvaluebuffer[i].event_id,eventbuffer);

      event[i].event_type        =  eventbuffer.type;
      event[i].sector            =  eventbuffer.sector;
      event[i].frequency         =  eventbuffer.frequency;
      event[i].timemode          =  eventbuffer.time_mode;
      event[i].multiplier        =  eventbuffer.multiplier;
      event[i].unit              =  eventbuffer.unit;
      event[i].digits            =  eventbuffer.digits;
      event[i].country_id        =  eventbuffer.country_id;

      if(event[i].event_type!=CALENDAR_TYPE_HOLIDAY &&
         event[i].timemode==CALENDAR_TIMEMODE_DATETIME)
        {
         FileWriteStruct(filehandle,event[i]);
         int length=StringLen(eventbuffer.name);
         FileWriteInteger(filehandle,length,INT_VALUE);
         FileWriteString(filehandle,eventbuffer.name,length);
         saved_elements++;
        }
     }
   FileSeek(filehandle,0,SEEK_SET);
   FileWriteLong(filehandle,(long)tm_gmt);
   FileClose(filehandle);
   if(printlog_info)
     {
      Print(__FUNCTION__,": ",number_of_events," total events found, ",saved_elements,
            " events saved (holiday events and events without exact published time are ignored)");
     }
   return saved_elements;
  }

//Load History//

int CNews::LoadHistory(bool printlog_info=false)
  {
   datetime dt_gmt = GMT(GMT_offset_winter, GMT_offset_summer);
   int filehandle;
   int number_of_events = 0;

   if(FileIsExist("news\\newshistory.bin", FILE_COMMON))
     {
      filehandle = FileOpen("news\\newshistory.bin", FILE_READ | FILE_WRITE | FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_COMMON | FILE_BIN);

      if(filehandle != INVALID_HANDLE)
        {
         FileSeek(filehandle, 0, SEEK_SET);
         last_update = (datetime)FileReadLong(filehandle);
         if(printlog_info)
            Print(__FUNCTION__, ": previous news history file found; last update was on ", last_update, " (GMT)");
        }
      else
        {
         if(printlog_info)
            Print(__FUNCTION__, ": can't open previous news history file; invalid file handle");
         return 0;
        }

      ZeroMemory(event);

      int i = 0;
      while(!FileIsEnding(filehandle) && !IsStopped())
        {
         if(ArraySize(event) <= i)
            ArrayResize(event, i + 1000);

         FileReadStruct(filehandle, event[i]);

         int length = FileReadInteger(filehandle, INT_VALUE);
         if(ArraySize(eventname) <= i)
            ArrayResize(eventname, i + 1000);

         eventname[i] = FileReadString(filehandle, length);
         i++;
        }

      number_of_events = i;
      FileClose(filehandle);

      if(printlog_info)
         Print(__FUNCTION__, ": loading of event history completed (", number_of_events, " events), continuing with events after ", last_update, " (GMT) ...");
     }
   else
     {
      if(printlog_info)
         Print(__FUNCTION__, ": no newshistory file found, only upcoming events will be loaded");
      last_update = dt_gmt;
     }

   MqlCalendarValue eventvaluebuffer[];
   ZeroMemory(eventvaluebuffer);
   MqlCalendarEvent eventbuffer;
   ZeroMemory(eventbuffer);

   CalendarValueHistory(eventvaluebuffer, last_update, 0);
   int future_events = ArraySize(eventvaluebuffer);

   if(printlog_info)
      Print(__FUNCTION__, ": ", future_events, " new events found (holiday events and events without published exact time will be ignored)");

   ArrayResize(event, number_of_events + future_events);
   ArrayResize(eventname, number_of_events + future_events);

   for(int i = 0; i < future_events; i++)
     {
      event[number_of_events].value_id          = eventvaluebuffer[i].id;
      event[number_of_events].event_id          = eventvaluebuffer[i].event_id;
      event[number_of_events].time              = eventvaluebuffer[i].time;
      event[number_of_events].period            = eventvaluebuffer[i].period;
      event[number_of_events].revision          = eventvaluebuffer[i].revision;
      event[number_of_events].actual_value      = eventvaluebuffer[i].actual_value;
      event[number_of_events].prev_value        = eventvaluebuffer[i].prev_value;
      event[number_of_events].revised_prev_value= eventvaluebuffer[i].revised_prev_value;
      event[number_of_events].forecast_value    = eventvaluebuffer[i].forecast_value;
      event[number_of_events].impact_type       = eventvaluebuffer[i].impact_type;

      CalendarEventById(eventvaluebuffer[i].event_id, eventbuffer);

      event[number_of_events].event_type        = eventbuffer.type;
      event[number_of_events].sector            = eventbuffer.sector;
      event[number_of_events].frequency         = eventbuffer.frequency;
      event[number_of_events].timemode          = eventbuffer.time_mode;
      event[number_of_events].importance        = eventbuffer.importance;
      event[number_of_events].multiplier        = eventbuffer.multiplier;
      event[number_of_events].unit              = eventbuffer.unit;
      event[number_of_events].digits            = eventbuffer.digits;
      event[number_of_events].country_id        = eventbuffer.country_id;

      eventname[number_of_events] = eventbuffer.name;

      if(event[number_of_events].event_type != CALENDAR_TYPE_HOLIDAY &&
         event[number_of_events].timemode == CALENDAR_TIMEMODE_DATETIME)
        {
         number_of_events++;
        }
     }

   if(printlog_info)
      Print(__FUNCTION__, ": loading of news history completed, ", number_of_events, " events in memory");

   last_update = dt_gmt;
   return number_of_events;
  }

//Pointer Next Event//

int timezone_off = 180*PeriodSeconds(PERIOD_M1);

int CNews::next(int pointer_start,string currency,bool show_on_chart=true,long chart_id=0)
  {
   int country = CurrencyToCountryId(currency); 
   datetime dt_gmt=GMT(GMT_offset_winter,GMT_offset_summer);
   for(int p=pointer_start;p<ArraySize(event);p++)
     {
      if(event[p].country_id==country && event[p].time>=dt_gmt)
        {
         if(pointer_start!=p && show_on_chart && MQLInfoInteger(MQL_VISUAL_MODE))
           {
            ObjectCreate(chart_id,"event "+IntegerToString(p),OBJ_VLINE,0,event[p].time+TimeTradeServer()-dt_gmt-timezone_off,0);
            ObjectSetInteger(chart_id,"event "+IntegerToString(p),OBJPROP_WIDTH,3);
            ObjectCreate(chart_id,"label "+IntegerToString(p),OBJ_TEXT,0,event[p].time+TimeTradeServer()-dt_gmt-timezone_off,SymbolInfoDouble(Symbol(),SYMBOL_BID));
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_YOFFSET,800);
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_BACK,true);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_FONT,"Arial");
            ObjectSetInteger(chart_id,"label "+IntegerToString(p),OBJPROP_FONTSIZE,10);
            ObjectSetDouble(chart_id,"label "+IntegerToString(p),OBJPROP_ANGLE,-90);
            ObjectSetString(chart_id,"label "+IntegerToString(p),OBJPROP_TEXT,eventname[p]);
           }
         return p;
        }
     }
   return pointer_start;
  }

//Server Time To GMT//

datetime CNews::GMT(ushort server_offset_winter,ushort server_offset_summer)
  {
   if(!MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_TESTER))
     {
      return TimeGMT();
     }

   servertime=TimeCurrent();
   TimeToStruct(servertime,tm);
   static bool initialized=false;
   static bool summertime=true;

   if(!initialized)
     {
      if(tm.mon<=2 || (tm.mon==3 && tm.day<=7))
        {
         summertime=false;
        }
      if((tm.mon==11 && tm.day>=8) || tm.mon==12)
        {
         summertime=false;
        }
      initialized=true;
     }

   if(tm.mon==3 && tm.day>7 && tm.day_of_week==0 && tm.hour==7+server_offset_winter)
     {
      summertime=true;
     }

   if(tm.mon==11 && tm.day<=7 && tm.day_of_week==0 && tm.hour==7+server_offset_summer)
     {
      summertime=false;
     }
   if(summertime)
     {
      return servertime-server_offset_summer*3600;
     }
   else
     {
      return servertime-server_offset_winter*3600;
     }
  }

//Get Next News Panel//

int CNews::GetNextNewsEvent(int pointer_start, string currency, Importanza importance)
  {
   for(int p = pointer_start; p < ArraySize(event); p++)
     {
      bool ImportanceFilter = (importance == Bassa) ? event[p].importance == CALENDAR_IMPORTANCE_LOW ||
                              event[p].importance == CALENDAR_IMPORTANCE_MODERATE ||
                              event[p].importance == CALENDAR_IMPORTANCE_HIGH :
                              (importance == Media) ? event[p].importance == CALENDAR_IMPORTANCE_MODERATE ||
                              event[p].importance == CALENDAR_IMPORTANCE_HIGH :
                              (importance == Alta)  ? event[p].importance == CALENDAR_IMPORTANCE_HIGH : false;

      if(ImportanceFilter && news.event[p].country_id == CurrencyToCountryId(currency) && news.event[p].sector != CALENDAR_SECTOR_BUSINESS)
        {
         return p;
        }
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|  Functions                                                       |
//+------------------------------------------------------------------+

//Errori//

string ErrorDescription(int error_code)
  {
   switch(error_code)
     {
      case 0:
         return "No error";
      case 1:
         return "Unknown Function";
      case 2:
         return "Invalid Parameter";
      case 3:
         return "Invalid Market Condition";
      case 4:
         return "Invalid Operation";
      case 5:
         return "Request Timeout";
      case 10004:
         return "Unable to connect to Trading Server";
      case 10006:
         return "Trading Request has been Discarded";
      case 10007:
         return "Trading Server is Occupied";
      case 10008:
         return "Trading Request Timeout";
      case 10009:
         return "Order Rejectes";
      case 10010:
         return "No Open Orders";
      case 10011:
         return "Invalid Operation for the Current Account";
      case 10012:
         return "Invalid Volume";
      case 10013:
         return "Invalid Price";
      case 10014:
         return "Invalid Stop loss or Take profit";
      case 10015:
         return "Market Price Unavaible";
      case 10016:
         return "Insufficient Margin";
      case 10017:
         return "Max Orders Limit has been reached";
      case 10018:
         return "Trading Request has been Cancelled";
      case 10019:
         return "No Chronostory Avaible";
      default:
         return "Unknown Error. Error Code: " + IntegerToString(error_code);
     }
  }

//Punti//

double point(string Simbolo)
  {
   return SymbolInfoDouble(Simbolo, SYMBOL_POINT);
  }
  
//Prezzo//

double Bid(string Simbolo)
  {
   return NormalizeDouble(SymbolInfoDouble(Simbolo, SYMBOL_BID), Digit(Simbolo));
  }

double Ask(string Simbolo)
  {
   return NormalizeDouble(SymbolInfoDouble(Simbolo, SYMBOL_ASK), Digit(Simbolo));
  }
  
double Prezzo(string Simbolo)
   {
    return NormalizeDouble((Ask(Simbolo) - Bid(Simbolo))/2 + Bid(Simbolo), Digit(Simbolo));
   }
   
double Open(string Simbolo, ENUM_TIMEFRAMES TimeFrame, int Shift)
  {
   return NormalizeDouble(iOpen(Simbolo,TimeFrame,Shift), Digit(Simbolo));
  }

double Close(string Simbolo, ENUM_TIMEFRAMES TimeFrame, int Shift)
  {
   return NormalizeDouble(iClose(Simbolo,TimeFrame,Shift), Digit(Simbolo));
  }

double High(string Simbolo, ENUM_TIMEFRAMES TimeFrame, int Shift)
  {
   return NormalizeDouble(iHigh(Simbolo,TimeFrame,Shift), Digit(Simbolo));
  }

double Low(string Simbolo, ENUM_TIMEFRAMES TimeFrame, int Shift)
  {
   return NormalizeDouble(iLow(Simbolo,TimeFrame,Shift), Digit(Simbolo));
  }

double LowestLow(string symbol, ENUM_TIMEFRAMES TimeFrame, int count)
  {
   return iLow(symbol,TimeFrame,iLowest(symbol,TimeFrame,MODE_LOW,count,0));
  }

double HighestHigh(string symbol, ENUM_TIMEFRAMES TimeFrame, int count)
  {
   return iHigh(symbol,TimeFrame,iHighest(symbol,TimeFrame,MODE_HIGH,count,0));
  }

//Ordini a Mercato//

void SendBuy(double Lotti, string Simbolo, string Commento, int MagicNumber)
  {
   trade.SetExpertMagicNumber(MagicNumber);

   if(!trade.Buy(Lotti, Simbolo, SymbolInfoDouble(Simbolo, SYMBOL_BID), 0.0, 0.0, Commento))
     {
      int error_code = GetLastError();
      Print("Error opening BUY order for ", Simbolo, ". Error Code : ", error_code, " - Description: ", ErrorDescription(error_code));
      ResetLastError();
     }
   else
     {
      Print("Order BUY opened correctly for ", Simbolo, ". Lot Size : ", Lotti);
     }
  }

void SendSell(double Lotti, string Simbolo, string Commento, int MagicNumber)
  {
   trade.SetExpertMagicNumber(MagicNumber);

   if(!trade.Sell(Lotti, Simbolo, SymbolInfoDouble(Simbolo, SYMBOL_ASK), 0.0, 0.0, Commento))
     {
      int error_code = GetLastError();
      Print("Error opening SELL order for ", Simbolo, ". Error Code : ", error_code, " - Description: ", ErrorDescription(error_code));
      ResetLastError();
     }
   else
     {
      Print("Order SELL opened correctly for ", Simbolo, ". Lot Size : ", Lotti);
     }
  }

//Ordini Limite//

void SendBuyLimit(double Prezzo, double Lotti, string Simbolo, string Commento, int MagicNumber)
  {
   trade.SetExpertMagicNumber(MagicNumber);

   if(!trade.BuyLimit(Lotti, Prezzo, Simbolo, 0.0, 0.0, 0, 0, Commento))
     {
      int error_code = GetLastError();
      Print("Error opening BUY order for ", Simbolo, ". Error Code : ", error_code, " - Description: ", ErrorDescription(error_code));
      ResetLastError();
     }
   else
     {
      Print("Order BUY opened correctly for ", Simbolo, ". Lot Size : ", Lotti);
     }
  }

void SendSellLimit(double Prezzo, double Lotti, string Simbolo, string Commento, int MagicNumber)
  {
   trade.SetExpertMagicNumber(MagicNumber);

   if(!trade.SellLimit(Lotti, Prezzo, Simbolo, 0.0, 0.0, 0, 0, Commento))
     {
      int error_code = GetLastError();
      Print("Error opening SELL order for ", Simbolo, ". Error Code: ", error_code, " - Description: ", ErrorDescription(error_code));
      ResetLastError();
     }
   else
     {
      Print("Order SELL Opened correctly for ", Simbolo, ". Lot Size : ", Lotti);
     }
  }

//Digits//

int Digit(string Simbolo)
  {
   int i = 0;

   i = (int)SymbolInfoInteger(Simbolo,SYMBOL_DIGITS);

   return(i);
  }

//Chiudi tutti i Buy//

void CloseAllBuy(string Simbolo, int MagicNumber)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);

      if(PositionDirection == POSITION_TYPE_BUY && PositionMagicNumber == MagicNumber && PositionSymbol == Simbolo)
        {
         trade.PositionClose(ticket);
        }
     }
  }

//Chiudi tutti i Sell//

void CloseAllSell(string Simbolo, int MagicNumber)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);

      if(PositionDirection == POSITION_TYPE_SELL && PositionMagicNumber == MagicNumber && PositionSymbol == Simbolo)
        {
         trade.PositionClose(ticket);
        }
     }
  }

//Counter Ordini//

double CountOrders(string Simbolo, int MagicNumber, int positionType)
  {
   int OpenOrders = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetSymbol(i) == Simbolo &&
         PositionGetInteger(POSITION_TYPE) == positionType &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         OpenOrders++;
        }
     }

   return OpenOrders;
  }

double CounterBuy(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, POSITION_TYPE_BUY);
  }

double CounterSell(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, POSITION_TYPE_SELL);
  }

//Counter Ordini Limite//

double CountOrdersLimit(string Simbolo, int MagicNumber, int OrderType)
  {
   int OpenOrders = 0;

   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderGetString(ORDER_SYMBOL) == Simbolo &&
         OrderGetInteger(ORDER_TYPE) == OrderType &&
         OrderGetInteger(ORDER_MAGIC) == MagicNumber)
        {
         OpenOrders++;
        }
     }

   return OpenOrders;
  }

double CounterBuyLimit(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, ORDER_TYPE_BUY_LIMIT);
  }

double CounterSellLimit(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, ORDER_TYPE_SELL_LIMIT);
  }

// Rendimento //

double RendimentoGiornaliero(string Simbolo)
   {
    double inizio = Open(Simbolo,PERIOD_D1,0);
    double adesso = Prezzo(Simbolo);
    
    if(inizio <= 0.0) return 0.0;
    
    return ((adesso - inizio) / inizio) * 100; 
   }

double RendimentoSettimanale(string Simbolo)
   {
    double inizio = Open(Simbolo,PERIOD_W1,0);
    double adesso = Prezzo(Simbolo);
    
    if(inizio <= 0.0) return 0.0;
    
    return ((adesso - inizio) / inizio) * 100; 
   }
   
double RendimentoMensile(string Simbolo)
   {
    double inizio = Open(Simbolo,PERIOD_MN1,0);
    double adesso = Prezzo(Simbolo);
    
    if(inizio <= 0.0) return 0.0;
    
    return ((adesso - inizio) / inizio) * 100; 
   }
   
double RendimentoQuartile(string Simbolo)
   {
   datetime inizio, fine;
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int start_month = ((dt.mon - 1) / 3) * 3 + 1;
   dt.mon = start_month;
   dt.day = 0;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   inizio = StructToTime(dt);
   fine = now;

   double open[], close[];
   datetime time[];

   if(CopyTime(Simbolo, PERIOD_D1, inizio, fine, time) < 2)
     {
      Print("Error: Not Enough Data");
      return 0;
     }

   if(CopyOpen(Simbolo, PERIOD_D1, inizio, fine, open) < 1 ||
      CopyClose(Simbolo, PERIOD_D1, inizio, fine, close) < 1)
     {
      Print("Error on retrieving OHLC Data");
      return 0;
     }

   double rendimento = ((close[ArraySize(close) - 1] - open[0]) / open[0]) * 100.0;
   return rendimento;
   }   
   
string GetCurrentQuarter()
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int month = dt.mon;
   string quarter;

   if(month >= 1 && month <= 3)
      quarter = "Q1";
   else if(month >= 4 && month <= 6)
      quarter = "Q2";
   else if(month >= 7 && month <= 9)
      quarter = "Q3";
   else if(month >= 10 && month <= 12)
      quarter = "Q4";
   else
      quarter = "Error : Invalid Month";

   return quarter;
  }
   
   
//LotSize Per SL//

double CalculateLotSize(string Simbolo, double SL, double Risk_Per_Trade)
  {
   double StopLoss = NormalizeDouble(SL,Digit(Simbolo));
   double tickValue = SymbolInfoDouble(Simbolo, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(Simbolo, SYMBOL_POINT);
   double volumeStep = SymbolInfoDouble(Simbolo, SYMBOL_VOLUME_STEP);
   double volumeMin = SymbolInfoDouble(Simbolo, SYMBOL_VOLUME_MIN);
   double volumeMax = SymbolInfoDouble(Simbolo, SYMBOL_VOLUME_MAX);
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double accountRisk = accountBalance * (Risk_Per_Trade / 100.0);
   double pipValue = tickValue / point;
   double lotSize = accountRisk / (pipValue * StopLoss);

   lotSize = MathFloor(lotSize / volumeStep) * volumeStep;

   if(lotSize < volumeMin)
      lotSize = volumeMin;
   if(lotSize > volumeMax)
      lotSize = volumeMax;
   if(lotSize < volumeMin || lotSize > volumeMax)
     {
      Print("Calculated lot size is invalid: ", lotSize);
      return 0;
     }
   return lotSize;
  }

//Calcolo Rischio Variabile//

double CalculateDynamicRisk(int Attivo,double Maxrisk)
   {
    double Profit = AccountInfoDouble(ACCOUNT_BALANCE) - Saldo;
    double Monetary_Risk = (Risk / 100) * AccountInfoDouble(ACCOUNT_BALANCE);
    double Monetary_Risk_Final;
    double Risk_Final;
    bool alert1 = false, alert2 = false;
   
    if(Profit >= Saldo * 0.005)
      {
       Monetary_Risk_Final = Monetary_Risk + (Profit * (Risk/2));  
       
       if(Monetary_Risk_Final >= Profit)
         {
          Monetary_Risk_Final = Profit-5;   
         }
         
       Risk_Final = NormalizeDouble((Monetary_Risk_Final / AccountInfoDouble(ACCOUNT_BALANCE)) * 100,2);  
      }
     else
      {
       Monetary_Risk_Final = Monetary_Risk;
       Risk_Final = Risk;
      }
     
     if(Monetary_Risk_Final >= (AccountInfoDouble(ACCOUNT_BALANCE) * (Maxrisk/100)) && alert1 == false)
       {
        Risk_Final = 2;
        Monetary_Risk_Final = Saldo * (Maxrisk/100);
        Alert("Risk too high, your risking more than "+DoubleToString(Maxrisk/100,2)+"% so it will be set at "+DoubleToString(Maxrisk/100,2)+"%");
        alert1 = true;
       }
     
     if(Monetary_Risk_Final >= (AccountInfoDouble(ACCOUNT_BALANCE) * (Perdita_Massima_Giornaliera/100)) && alert2 == false)
       { 
        Risk_Final = Risk;
        Monetary_Risk_Final = Monetary_Risk;
        Alert("Your risking more than the max daily loss, Risk will be normalized without DVR");
        alert2 = true;
       }
     
     if(Attivo == 0)
      {
       Risk_Final = Risk;
       Monetary_Risk_Final = Monetary_Risk;
      }
       
     if(Monetary_Risk_Final >= Profit)
       {
        GlobalRiskColor = Red;
       }  
     else
       {
        GlobalRiskColor = DodgerBlue;
       } 
       
    return Risk_Final;
   }

//Creazione Label//

void Label(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, string Text, color Color, string Font, double Size)
  {
   ObjectCreate(0, Name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
   ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
   ObjectSetString(0, Name, OBJPROP_TEXT, Text);
   ObjectSetString(0, Name, OBJPROP_FONT, Font);
   ObjectSetInteger(0, Name, OBJPROP_FONTSIZE, long(Size));
   ObjectSetInteger(0, Name, OBJPROP_COLOR, Color);
   ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,Name,OBJPROP_HIDDEN,true);
  }

//Creazione Edit//

void Edit(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, string Text, color Color, string Font, double Size)
  {
   ObjectCreate(0, Name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
   ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
   ObjectSetInteger(0, Name, OBJPROP_XSIZE, long(Size_X));
   ObjectSetInteger(0, Name, OBJPROP_YSIZE, long(Size_Y));
   ObjectSetString(0, Name, OBJPROP_TEXT, Text);
   ObjectSetString(0, Name, OBJPROP_FONT, Font);
   ObjectSetInteger(0, Name, OBJPROP_FONTSIZE, long(Size));
   ObjectSetInteger(0, Name, OBJPROP_COLOR, Color);
   ObjectSetInteger(0, Name, OBJPROP_READONLY, false);
   ObjectSetInteger(0,Name, OBJPROP_ZORDER, 0);
   ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,Name,OBJPROP_HIDDEN,true);
  }

//Creazione Button//

void Button(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, string Text, color Color, color BackGround_Color, string Font)
  {
   ObjectCreate(0, Name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
   ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
   ObjectSetInteger(0, Name, OBJPROP_XSIZE, long(Size_X));
   ObjectSetInteger(0, Name, OBJPROP_YSIZE, long(Size_Y));
   ObjectSetInteger(0, Name, OBJPROP_BGCOLOR, BackGround_Color);
   ObjectSetInteger(0, Name, OBJPROP_BORDER_COLOR, Color);
   ObjectSetInteger(0,Name, OBJPROP_ZORDER, 0);
   ObjectSetInteger(0, Name, OBJPROP_COLOR, Color);
   ObjectSetString(0, Name, OBJPROP_TEXT, Text);
   ObjectSetString(0, Name, OBJPROP_FONT, Font);
   ObjectSetInteger(0, Name,OBJPROP_STATE,false);
  }

//Creazione Label Rettangolare//

void RectangleLabel(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, color Border_Color, color BackGround_Color, ENUM_BORDER_TYPE Border_Type)
  {
   ObjectCreate(0, Name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
   ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
   ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
   ObjectSetInteger(0, Name, OBJPROP_XSIZE, long(Size_X));
   ObjectSetInteger(0, Name, OBJPROP_YSIZE, long(Size_Y));
   ObjectSetInteger(0, Name, OBJPROP_BGCOLOR, BackGround_Color);
   ObjectSetInteger(0, Name, OBJPROP_BORDER_COLOR, Border_Color);
   ObjectSetInteger(0, Name, OBJPROP_BORDER_TYPE, Border_Type);
   ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,Name,OBJPROP_HIDDEN,true);
  }

// Time Filter //

bool TimeFilter(string inizio, string fine)
  {
   datetime Start = StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " " + inizio);
   datetime End = StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " " + fine);
   
   if(!(iTime(Symbol(),Period(),0) >= Start && iTime(Symbol(),Period(),0) <= End))
     {
      return(false);
     }
   return(true);
  }

//Setta SL ad un prezzo Limite//

void SetStopLossPriceBuyLimit(string Simbolo, int MagicNumber, double StopLoss, string comment)
  {
   double SL = NormalizeDouble(StopLoss,Digit(Simbolo));

   for(int w = (OrdersTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = OrderGetTicket(w);
      long PositionMagicNumber = OrderGetInteger(ORDER_MAGIC);
      string PositionComment = OrderGetString(ORDER_COMMENT);
      string PositionSymbol = OrderGetString(ORDER_SYMBOL);
      long PositionDirection = OrderGetInteger(ORDER_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == ORDER_TYPE_BUY_LIMIT && PositionComment == comment)
        {
         double PositionStopLoss = OrderGetDouble(ORDER_SL);

         if(PositionStopLoss == 0.0)
           {
            int j = trade.OrderModify(Ticket, Price, SL, OrderGetDouble(ORDER_TP),ORDER_TIME_DAY,0,0);
           }
        }
     }
  }

void SetStopLossPriceSellLimit(string Simbolo, int MagicNumber, double StopLoss, string comment)
  {
   double SL = NormalizeDouble(StopLoss,Digit(Simbolo));

   for(int w = (OrdersTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = OrderGetTicket(w);
      long PositionMagicNumber = OrderGetInteger(ORDER_MAGIC);
      string PositionComment = OrderGetString(ORDER_COMMENT);
      string PositionSymbol = OrderGetString(ORDER_SYMBOL);
      long PositionDirection = OrderGetInteger(ORDER_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == ORDER_TYPE_SELL_LIMIT && PositionComment == comment)
        {
         double PositionStopLoss = OrderGetDouble(ORDER_SL);

         if(PositionStopLoss == 0.0)
           {
            int j = trade.OrderModify(Ticket, Price, SL, OrderGetDouble(ORDER_TP),ORDER_TIME_DAY,0,0);
           }
        }
     }
  }

//Setta TP ad un prezzo Limite//

void SetTakeProfitPriceBuyLimit(string Simbolo, int MagicNumber, double TakeProfit, string comment)
  {
   double TP = NormalizeDouble(TakeProfit,Digit(Simbolo));

   for(int w = (OrdersTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = OrderGetTicket(w);
      long PositionMagicNumber = OrderGetInteger(ORDER_MAGIC);
      string PositionComment = OrderGetString(ORDER_COMMENT);
      string PositionSymbol = OrderGetString(ORDER_SYMBOL);
      long PositionDirection = OrderGetInteger(ORDER_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == ORDER_TYPE_BUY_LIMIT && PositionComment == comment)
        {
         double PositionTP = OrderGetDouble(ORDER_TP);

         if(PositionTP == 0.0)
           {
            int j = trade.OrderModify(Ticket, Price, OrderGetDouble(ORDER_SL), TP,ORDER_TIME_DAY,0,0);
           }
        }
     }
  }

void SetTakeProfitPriceSellLimit(string Simbolo, int MagicNumber, double TakeProfit, string comment)
  {
   double TP = NormalizeDouble(TakeProfit,Digit(Simbolo));


   for(int w = (OrdersTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = OrderGetTicket(w);
      long PositionMagicNumber = OrderGetInteger(ORDER_MAGIC);
      string PositionComment = OrderGetString(ORDER_COMMENT);
      string PositionSymbol = OrderGetString(ORDER_SYMBOL);
      long PositionDirection = OrderGetInteger(ORDER_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == ORDER_TYPE_SELL_LIMIT && PositionComment == comment)
        {
         double PositionTP = OrderGetDouble(ORDER_TP);

         if(PositionTP == 0.0)
           {
            int j = trade.OrderModify(Ticket, Price, OrderGetDouble(ORDER_SL), TP,ORDER_TIME_DAY,0,0);
           }
        }
     }
  }

//Setta SL ad un prezzo//

void SetStopLossPriceBuy(string Simbolo, int MagicNumber, double StopLoss, string comment)
  {
   double SL = NormalizeDouble(StopLoss,Digit(Simbolo));

   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionComment = PositionGetString(POSITION_COMMENT);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == POSITION_TYPE_BUY && PositionComment == comment)
        {
         double PositionStopLoss = PositionGetDouble(POSITION_SL);

         if(PositionStopLoss == 0.0)
           {
            int j = trade.PositionModify(Ticket, SL, position.TakeProfit());
           }
        }
     }
  }

void SetStopLossPriceSell(string Simbolo, int MagicNumber, double StopLoss, string comment)
  {
   double SL = NormalizeDouble(StopLoss,Digit(Simbolo));

   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionComment = PositionGetString(POSITION_COMMENT);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == POSITION_TYPE_SELL && PositionComment == comment)
        {
         double PositionStopLoss = PositionGetDouble(POSITION_SL);

         if(PositionStopLoss == 0.0)
           {
            int j = trade.PositionModify(Ticket, SL, position.TakeProfit());
           }
        }
     }
  }

//Setta TP ad un prezzo//

void SetTakeProfitPriceBuy(string Simbolo, int MagicNumber, double TakeProfit, string comment)
  {
   double TP = NormalizeDouble(TakeProfit,Digit(Simbolo));

   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionComment = PositionGetString(POSITION_COMMENT);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == POSITION_TYPE_BUY && PositionComment == comment)
        {
         double PositionTP = PositionGetDouble(POSITION_TP);

         if(PositionTP == 0.0)
           {
            int j = trade.PositionModify(Ticket, position.StopLoss(), TP);
           }
        }
     }
  }

void SetTakeProfitPriceSell(string Simbolo, int MagicNumber, double TakeProfit, string comment)
  {
   double TP = NormalizeDouble(TakeProfit,Digit(Simbolo));

   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionComment = PositionGetString(POSITION_COMMENT);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionDirection == POSITION_TYPE_SELL && PositionComment == comment)
        {
         double PositionTP = PositionGetDouble(POSITION_TP);

         if(PositionTP == 0.0)
           {
            int j = trade.PositionModify(Ticket, position.StopLoss(), TP);
           }
        }
     }
  }

//Break Even//

void BreakEven(string Simbolo, int MagicNumber, string comment)
  {
   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionComment = PositionGetString(POSITION_COMMENT);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_BUY)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),Digit(Simbolo));

         if(PositionSL != PositionOpen)
           {
            if(Ask(Simbolo) > PositionOpen)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
              }
            else
               if(Ask(Simbolo) < PositionOpen)
                 {
                  Alert("Trade is in loss and cannot be moved to Break Even");
                 }
           }
        }
      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_SELL)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),Digit(Simbolo));

         if(PositionSL != PositionOpen)
           {
            if(Bid(Simbolo) < PositionOpen)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
              }
            else
               if(Bid(Simbolo) > PositionOpen)
                 {
                  Alert("Trade is in loss and cannot be moved to Break Even");
                 }
           }
        }
     }
  }

//Automatic Break Even//

void ABE(string Simbolo, int MagicNumber, string comment)
  {
   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionComment = PositionGetString(POSITION_COMMENT);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_BUY)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),Digit(Simbolo));
         double PositionTake = NormalizeDouble(PositionGetDouble(POSITION_TP),Digit(Simbolo));
         double DimTP = PositionTake - PositionOpen;
         
         if(PositionSL != PositionOpen)
           {
            if(Ask(Simbolo) >= PositionOpen + (DimTP/2))
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
              }
           }
        }
      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_SELL)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),Digit(Simbolo));
         double PositionTake = NormalizeDouble(PositionGetDouble(POSITION_TP),Digit(Simbolo));
         double DimTP = PositionOpen - PositionTake;

         if(PositionSL != PositionOpen)
           {
            if(Bid(Simbolo) <= PositionOpen - (DimTP/2))
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
              }
           }
        }
     }
  }

//Valute To String//

string ValuteToString(Valute valut)
  {
  string res = "";
  
  if(valut == 0)
    {
     res = "USD";
    }  
  if(valut == 1)
    {
     res = "EUR";
    }  
  if(valut == 2)
    {
     res = "GBP";
    }  
  if(valut == 3)
    {
     res = "AUD";
    }  
  if(valut == 4)
    {
     res = "CYN";
    }  
  if(valut == 5)
    {
     res = "CHF";
    }  
  if(valut == 6)
    {
     res = "NZD";
    }  
  if(valut == 7)
    {
     res = "BRL";
    }  
  if(valut == 8)
    {
     res = "KRW";
    }
    return res;
  }

//News//

void GetNextNews(string currency, int OffSet, bool reset_index)
  {
   int country = news.CurrencyToCountryId(currency);
   
   if(reset_index)
     {
      last_event_index = 0;
      GlobalIndex = 0;
     }

   int total_events = news.update();

   if(total_events > 0)
     {
      datetime current_time = TimeCurrent();
      datetime closest_event_time = 0;
      int closest_event_index = -1;
      int highest_importance = -1;

      for(int next_event_index = news.next(last_event_index, currency, false, 0); next_event_index < total_events; next_event_index++)
        {
         bool ImportanceFilter = (Imp == Bassa) ? news.event[next_event_index].importance != CALENDAR_IMPORTANCE_NONE :
                                 (Imp == Media) ? news.event[next_event_index].importance == CALENDAR_IMPORTANCE_MODERATE ||
                                 news.event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH :
                                 (Imp == Alta)  ? news.event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH : false;

         if(ImportanceFilter && news.event[next_event_index].country_id == country && news.event[next_event_index].sector != CALENDAR_SECTOR_BUSINESS)
           {
            if(news.event[next_event_index].time >= current_time - PeriodSeconds(PERIOD_M10))
              {
               if(closest_event_index == -1 || news.event[next_event_index].time < closest_event_time)
                 {
                  closest_event_time = news.event[next_event_index].time;
                  closest_event_index = next_event_index;
                  highest_importance = news.event[next_event_index].importance;
                 }
               else
                  if(news.event[next_event_index].time == closest_event_time)
                    {
                     if(news.event[next_event_index].importance > highest_importance)
                       {
                        closest_event_index = next_event_index;
                        highest_importance = news.event[next_event_index].importance;
                       }
                    }
              }
           }
        }

      if(closest_event_index != -1)
        {
         last_event_index = closest_event_index;
         GlobalIndex = last_event_index;

         GlobalEventName = news.eventname[closest_event_index];

         StringSetLength(GlobalEventName, 52);

         GlobalEventTime = news.event[closest_event_index].time + OffSet;
         GlobalEventActualTime = news.event[closest_event_index].time;

         if(news.event[closest_event_index].unit == CALENDAR_UNIT_CURRENCY)
           {
            GlobalUnit = " "+valuta;
           }
         else
            if(news.event[closest_event_index].unit == CALENDAR_UNIT_PERCENT)
              {
               GlobalUnit = " %";
              }
            else
              {
               GlobalUnit = "";
              }

         if(news.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_NONE)
           {
            GlobalMultiplier = "";
           }
         else
            if(news.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_THOUSANDS)
              {
               GlobalMultiplier = " K";
              }
            else
               if(news.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_MILLIONS)
                 {
                  GlobalMultiplier = " M";
                 }
               else
                  if(news.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_BILLIONS)
                    {
                     GlobalMultiplier = " B";
                    }
                  else
                     if(news.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_TRILLIONS)
                       {
                        GlobalMultiplier = " T";
                       }

         if(news.event[closest_event_index].event_type == CALENDAR_TYPE_INDICATOR)
           {
            GlobalEventType = 1;
           }
         else
           {
            GlobalEventType = 0;
           }

         if(news.event[closest_event_index].importance == CALENDAR_IMPORTANCE_HIGH)
           {
            GlobalColor = Red;
            GlobalImportance = "Alta";
            GlobalEnumImportance = CALENDAR_IMPORTANCE_HIGH;
           }
         else
            if(news.event[closest_event_index].importance == CALENDAR_IMPORTANCE_MODERATE)
              {
               GlobalColor = Orange;
               GlobalImportance = "Media";
               GlobalEnumImportance = CALENDAR_IMPORTANCE_MODERATE;
              }
            else
               if(news.event[closest_event_index].importance == CALENDAR_IMPORTANCE_LOW)
                 {
                  GlobalColor = DarkGray;
                  GlobalImportance = "Bassa";
                  GlobalEnumImportance = CALENDAR_IMPORTANCE_LOW;
                 }
        }
      else
        {
         Print("No Relevant Event Found for ", currency);
        }
     }
   else
     {
      Print("No Event Available for ", currency);
     }
  }

//Interfaccia//

void InterfacciaInit(string simbolo, double conto, Importanza importance, int offSet)
  {
//Variabili Dinamiche//
   long fontsize = 12;
   string font = "Impact";
//Creazione Tabelle//
   RectangleLabel("Bordo",CORNER_LEFT_UPPER,0,0,800,800,Black,DodgerBlue,BORDER_FLAT);
   RectangleLabel("Sfondo",CORNER_LEFT_UPPER,5,5,790,790,Black,White,BORDER_FLAT);
   RectangleLabel("TabellaMercato",CORNER_LEFT_UPPER,5,5,395,395,Black,White,BORDER_FLAT);
   RectangleLabel("TabellaOperativa",CORNER_LEFT_UPPER,5,400,395,395,Black,White,BORDER_FLAT);
   RectangleLabel("TabellaAccount",CORNER_LEFT_UPPER,400,5,395,395,Black,White,BORDER_FLAT);
   RectangleLabel("TabellaNews",CORNER_LEFT_UPPER,400,400,395,395,Black,White,BORDER_FLAT);
//Tabella Mercato//
   Label("Simbolo",CORNER_LEFT_UPPER,15,20,"Active Symbol : "+simbolo,Black,font,fontsize*1.5);
   Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask : ND",Blue,font,fontsize);
   Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread : ND",Black,font,fontsize);
   Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid : ND",FireBrick,font,fontsize);
   Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,15,110,"Daily Return : ND",G,font,fontsize);
   Label("AndamentoSettimanale",CORNER_LEFT_UPPER,15,160,"Weekly Return : ND",S,font,fontsize);
   Label("AndamentoMensile",CORNER_LEFT_UPPER,15,210,"Monthly Return : ND",M,font,fontsize);
   Label("AndamentoQuartile",CORNER_LEFT_UPPER,15,260,"Quarter Return : ND",Q,font,fontsize);
   Label("EscursioneGiornaliera",CORNER_LEFT_UPPER,15,310,"Daily Range in Points : ND",Black,font,fontsize);
   Label("Sessione",CORNER_LEFT_UPPER,15,360,"Actual Session : ND",Black,font,fontsize);
//Tabella Operativa//
   Label("Rischio",CORNER_LEFT_UPPER,130,415,"Risk per Trade : 0.00%",GlobalRiskColor,font,fontsize);
   Button("Conservative",CORNER_LEFT_UPPER,15,450,100,50,"Conservative",Black,LightSkyBlue,font);
   Button("Medium",CORNER_LEFT_UPPER,150,450,100,50,"Medium",Black,LightSkyBlue,font);
   Button("Aggressive",CORNER_LEFT_UPPER,290,450,100,50,"Aggressive",Black,LightSkyBlue,font);
   Button("Limite",CORNER_LEFT_UPPER,25,520,150,50,"Limit Order",Black,LightGreen,font);
   Button("Mercato",CORNER_LEFT_UPPER,225,520,150,50,"Market Order",Black,LightGreen,font);
   Label("SeLimite",CORNER_LEFT_UPPER,15,580,"Limit Order Price : ",Black,font,fontsize);
   Edit("PrezzoLimite",CORNER_LEFT_UPPER,175,580,100,22.5,"",White,font,fontsize);
   Label("Tipo",CORNER_LEFT_UPPER,290,580,"Order Type : ND",Black,font,fontsize);
   Label("SetSL",CORNER_LEFT_UPPER,15,620,"Stop Loss Price : ",Black,font,fontsize);
   Edit("SL",CORNER_LEFT_UPPER,175,620,100,22.5,"",White,font,fontsize);
   Label("SetTP",CORNER_LEFT_UPPER,15,660,"Take Profit Price : ",Black,font,fontsize);
   Edit("TP",CORNER_LEFT_UPPER,175,660,100,22.5,"",White,font,fontsize);
   Button("Compra",CORNER_LEFT_UPPER,15,690,90,50,"Buy",Black,LightGreen,font);
   Button("Chiudi Buy",CORNER_LEFT_UPPER,15,740,90,50,"Close Buy",Black,FireBrick,font);
   Button("Vendi",CORNER_LEFT_UPPER,300,690,90,50,"Sell",Black,LightGreen,font);
   Button("Chiudi Sell",CORNER_LEFT_UPPER,300,740,90,50,"Close Sell",Black,FireBrick,font);
   Button("BreakEven",CORNER_LEFT_UPPER,105,690,195,100,"Break Even",Black,LightSkyBlue,font);
//Tabella Account//
   Label("Account",CORNER_LEFT_UPPER,410,20,"Account Starting Balance : "+DoubleToString(Saldo,0)+" $",Black,font,fontsize*1.5);
   Label("PNL",CORNER_LEFT_UPPER,410,70,"P&L : ND",Black,font,fontsize);
   Label("PerditaGioraliera",CORNER_LEFT_UPPER,410,112.5,"Max Daily Loss : ND",Black,font,fontsize);
   Label("PerditaMassima",CORNER_LEFT_UPPER,410,155,"Max Total Loss : ND",Black,font,fontsize);
   Label("ABE",CORNER_LEFT_UPPER,410,197.5,"Automatic Break Even : ND",Black,font,fontsize);
   Button("AttivaABE",CORNER_LEFT_UPPER,410,235,180,50,"Activate ABE",Black,LightSkyBlue,font);
   Button("DisattivaABE",CORNER_LEFT_UPPER,600,235,180,50,"Disactivate ABE",Black,LightSkyBlue,font);
   Label("DVR",CORNER_LEFT_UPPER,410,295,"Dynamic Variable Risk : ND",Black,font,fontsize);
   Button("DVRAttiva",CORNER_LEFT_UPPER,410,330,180,50,"Activate DVR",Black,LightSkyBlue,font);
   Button("DVRDisattiva",CORNER_LEFT_UPPER,600,330,180,50,"Disactivate DVR",Black,LightSkyBlue,font);
//Tabella News//
   int Max_News = 12;
   string currency = ValuteToString(Valuta);
   int coun = news.CurrencyToCountryId(currency);
   int indexes = 0;
   int news_found = 0;
   int yOffset = 60;
   datetime event_time;
   double prev_value, forecast_value, actual_value;

   for(int index = news.GetNextNewsEvent(0, currency,importance); index >= 0; index = news.GetNextNewsEvent(index + 1, currency,importance))
     {
      if(news_found >= Max_News)
         break;

      indexes = index;
      event_time = news.event[index].time;

      if(event_time >= TimeCurrent() - PeriodSeconds(PERIOD_H12))
        {
         prev_value = (double)news.event[index].prev_value / 1000000;
         forecast_value = (double)news.event[index].forecast_value / 1000000;
         actual_value = (double)news.event[index].actual_value / 1000000;

         string event_name = news.eventname[indexes];
         string eventtime = TimeToString(event_time + offSet * PeriodSeconds(PERIOD_H1), TIME_DATE | TIME_MINUTES);
         string eventimportance = news.event[indexes].importance == CALENDAR_IMPORTANCE_LOW ? "Bassa" :
                                  news.event[indexes].importance == CALENDAR_IMPORTANCE_MODERATE ? "Media" :
                                  news.event[indexes].importance == CALENDAR_IMPORTANCE_HIGH ? "Alta" : "";
         string eventprevious = DoubleToString(prev_value, 1);
         string eventforecast = DoubleToString(forecast_value, 1);
         string eventactual = DoubleToString(actual_value, 1);
         string eventsector = EnumToString(news.event[indexes].sector);

         if(prev_value == (double)LONG_MIN / 1000000)
            eventprevious = "ND";
         if(forecast_value == (double)LONG_MIN / 1000000)
            eventforecast = "ND";
         if(actual_value == (double)LONG_MIN / 1000000)
            eventactual = "ND";

         string label_name = Prefix + "Name" + IntegerToString(indexes);
         string label_time = Prefix + "Time" + IntegerToString(indexes);

         StringSetLength(event_name, 40);

         color clr = Black;

         if(eventimportance == "Bassa")
            clr = DarkGray;
         if(eventimportance == "Media")
            clr = Orange;
         if(eventimportance == "Alta")
            clr = FireBrick;
            
         Label(Prefix + "Nomes",CORNER_LEFT_UPPER,410,415,"Upcoming News",DodgerBlue,font,fontsize);
         Label(Prefix + "Times",CORNER_LEFT_UPPER,675,415,"Date and Time",DodgerBlue,font,fontsize);
         Label(label_name, CORNER_LEFT_UPPER, 410, yOffset + 385, event_name, Black,font,fontsize*0.9);
         Label(label_time, CORNER_LEFT_UPPER, 675, yOffset + 385, eventtime, clr, font, fontsize*0.9);

         yOffset += 30;
         news_found++;
        }
     }
  }

void InterfacciaTick(string simbolo, double conto)
  {
//Variabili Dinamiche//
   long fontsize = 12;
   string font = "Impact";
//Tabella Mercato//
   Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask : "+DoubleToString(Ask(simbolo),Digit(simbolo)),Blue,font,fontsize);
   Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread : "+DoubleToString(Ask(simbolo)-Bid(simbolo),Digit(simbolo)),Black,font,fontsize);
   Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid : "+DoubleToString(Bid(simbolo),Digit(simbolo)),FireBrick,font,fontsize);
   Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,15,110,"Daily Return : "+DoubleToString(RendimentoGiornaliero(simbolo),2)+"%",G,font,fontsize);
   Label("AndamentoSettimanale",CORNER_LEFT_UPPER,15,160,"Weekly Return : "+DoubleToString(RendimentoSettimanale(simbolo),2)+"%",S,font,fontsize);
   Label("AndamentoMensile",CORNER_LEFT_UPPER,15,210,"Monthly Return : "+DoubleToString(RendimentoMensile(simbolo),2)+"%",M,font,fontsize);
   Label("AndamentoQuartile",CORNER_LEFT_UPPER,15,260,"Quarterly Return ("+GetCurrentQuarter()+") : "+DoubleToString(RendimentoQuartile(simbolo),2)+"%",Q,font,fontsize);
   Label("EscursioneGiornaliera",CORNER_LEFT_UPPER,15,310,"Daily Range in Points : "+DoubleToString(High(simbolo,PERIOD_D1,0)-Low(simbolo,PERIOD_D1,0),Digit(simbolo)),Black,font,fontsize);
   Label("Sessione",CORNER_LEFT_UPPER,15,360,"Actual Session : "+sessione,Black,font,fontsize);
//Tabella Account//
   Label("PNL",CORNER_LEFT_UPPER,410,70,"P&L : "+segno+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)-conto,2)+" $",Black,font,fontsize);
   Label("PerditaGioraliera",CORNER_LEFT_UPPER,410,112.5,"Max Daily Loss : "+DoubleToString(Perdita_Giornaliera,2)+" $",Black,font,fontsize);
   Label("PerditaMassima",CORNER_LEFT_UPPER,410,155,"Max Total Loss : "+DoubleToString(Perdita_Totale,2)+" $",Black,font,fontsize);
   Label("ABE",CORNER_LEFT_UPPER,410,197.5,"Automatic Break Even : "+state,Black,font,fontsize);
   Label("DVR",CORNER_LEFT_UPPER,410,295,"Dynamic Variable Risk : "+state_DVR,Black,font,fontsize);
//Tabella Operativa//
   Label("Rischio",CORNER_LEFT_UPPER,130,415,"Risk per Trade : "+DoubleToString(Final_Risk,2)+"%",GlobalRiskColor,font,fontsize);
   Label("Tipo",CORNER_LEFT_UPPER,290,580,"Order Type : "+tipo,Black,font,fontsize);
  }
  
//+------------------------------------------------------------------+
//| Inputs & Variables                                               |
//+------------------------------------------------------------------+

input double Saldo = 100000.00; // Account Starting Balance
input double Perdita_Massima_Giornaliera = 5;// Max Daily Loss in Percentage
input double Perdita_Massima_Totale = 10;// Max Total Loss in Percentage
input double MaxRisk = 2;// Max Risk Per Trade
input Valute Valuta = USD; // News Currency
input Importanza Imp = Media;// Minum Importance for the News
input int TimeOffSet = -1;// Offset in Hours from the Broker's Time

string commento = "AIM", GlobalEventName, GlobalImportance, GlobalUnit, GlobalMultiplier,Currency, valuta, Prefix = "N", tipo = "", segno = "",state = "", state_DVR = "", sessione = "ND";

color GlobalColor = Black, GlobalRiskColor = DodgerBlue, G = Black, S = Black, M = Black, Q = Black;

datetime GlobalEventTime, last_news_event_time = 0, news_dates[], GlobalEventActualTime;

int last_event_index = 0, magicNumber = 322974,timezone_offset = TimeOffSet * PeriodSeconds(PERIOD_H1), GlobalEventType = -1, GlobalIndex, MaxNews = 10;

static int Limitexist = 0, ABE = 0, DVR = 0;

double AvaragePrice, Lots, Take, Stop, Risk, Price, TodayPNL, Final_Risk, saldo_giornaliero = AccountInfoDouble(ACCOUNT_BALANCE), Perdita_Giornaliera = saldo_giornaliero * (Perdita_Massima_Giornaliera/100), Perdita_Totale;

ENUM_CALENDAR_EVENT_IMPORTANCE GlobalEnumImportance;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
// News //

   news.update();

   GetNextNews("USD",timezone_offset,true);

// Interfaccia //

   InterfacciaInit(Symbol(),Saldo,Imp,TimeOffSet);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| On Tick                                                          |
//+------------------------------------------------------------------+

void OnTick()
  {
// Segno //

   if(Saldo <= AccountInfoDouble(ACCOUNT_EQUITY))
     {
      segno = "+";
     }
   else
     {
      segno = "";
     }  

// Andamento Periodico //

   if(RendimentoGiornaliero(Symbol()) >= 0)
     {
      G = Green;
     }
   else
     {
      G = FireBrick;
     }  

   if(RendimentoSettimanale(Symbol()) >= 0)
     {
      S = Green;
     }
   else
     {
      S = FireBrick;
     }

   if(RendimentoMensile(Symbol()) >= 0)
     {
      M = Green;
     }
   else
     {
      M = FireBrick;
     }

   if(RendimentoQuartile(Symbol()) >= 0)
     {
      Q = Green;
     }
   else
     {
      Q = FireBrick;
     }               

// Tipo Ordine // 

   if(Limitexist == 0)
     {
      tipo = "M";
     }
   else
     {
      tipo = "L";
     }  
     
// PNL e Perdite //     
   
   if(TimeFilter("23:00","23:10") && (CountOrders(Symbol(),magicNumber,POSITION_TYPE_BUY) == 0 || CountOrders(Symbol(),magicNumber,POSITION_TYPE_SELL) == 0))
     {
      TodayPNL = 0;
      saldo_giornaliero = AccountInfoDouble(ACCOUNT_BALANCE);
     }
   else
     {
      TodayPNL = AccountInfoDouble(ACCOUNT_BALANCE)-AccountInfoDouble(ACCOUNT_EQUITY);
      
      if(TodayPNL > 0)
        {
         Perdita_Giornaliera = (saldo_giornaliero * (Perdita_Massima_Giornaliera/100)) - TodayPNL;
        }
     }
     
   Perdita_Totale = (AccountInfoDouble(ACCOUNT_BALANCE) - Saldo) + (Saldo * (Perdita_Massima_Totale/100));  

// Sessione Attuale // 
   
   if(TimeFilter(DoubleToString(22+TimeOffSet,0)+":00",DoubleToString(23+TimeOffSet,0)+":59") || TimeFilter(DoubleToString(00+TimeOffSet,0)+":00",DoubleToString(08+TimeOffSet,0)+":59"))
     {
      sessione = "Tokyo";
     }
   else 
      if(TimeFilter(DoubleToString(09+TimeOffSet,0)+":00",DoubleToString(15+TimeOffSet,0)+":29"))
        {
         sessione = "London";
        }
      else
         if(TimeFilter(DoubleToString(15+TimeOffSet,0)+":30",DoubleToString(21+TimeOffSet,0)+":59"))
           {
            sessione = "New York";
           }

// Stato //
   
   if(ABE == 1)
     {
      state = "Activated";
      ABE(Symbol(),magicNumber,commento);
     }  
   else
     {
      state = "Deactivated";
     }  

    if(DVR == 1)
     {
      state_DVR = "Activated";
     }  
   else
     {
      state_DVR = "Deactivated";
     }  
     
   Final_Risk = CalculateDynamicRisk(DVR,MaxRisk);

// Lotti //
    
   if(Limitexist == 0)
     {
      if(Stop != 0.0)
        {
         if(Stop > Bid(Symbol()))
           {
            Lots = CalculateLotSize(Symbol(), Stop - Bid(Symbol()), Final_Risk);     
           }
          else 
             if(Stop < Ask(Symbol()))
               {
                Lots = CalculateLotSize(Symbol(), Ask(Symbol()) - Stop, Final_Risk);          
               } 
        }
      else
        {
         Lots = 0.0;
        }
   }
   else
      if(Limitexist > 0)
        {
         if(Stop != 0.0)
           {
            if(Stop > Price)
              {
               Lots = CalculateLotSize(Symbol(), Stop - Price, Final_Risk);     
              }
             else 
                if(Stop < Price)
                  {
                   Lots = CalculateLotSize(Symbol(), Price - Stop, Final_Risk);          
                  } 
           }
         else
           {
            Lots = 0.0;
           }       
        }

// TP & SL per Ordini Limite //
   
   if(CounterBuyLimit(Symbol(), magicNumber) > 0)
     {
      for(int w = (OrdersTotal() - 1); w >= 0; w--)
         {
          ulong Ticket = OrderGetTicket(w);
          long OrderMagicNumber = OrderGetInteger(ORDER_MAGIC);
          string OrderComment = OrderGetString(ORDER_COMMENT);
          string OrderSymbol = OrderGetString(ORDER_SYMBOL);
          long OrderType = OrderGetInteger(ORDER_TYPE);       
          double OrderTP = OrderGetDouble(ORDER_TP);       
          double OrderSL = OrderGetDouble(ORDER_SL);       
         
          if(OrderSymbol == Symbol() && OrderMagicNumber == magicNumber && OrderType == ORDER_TYPE_BUY_LIMIT && OrderComment == commento)
            {             
             if(OrderSL == 0.0)
               {
                SetStopLossPriceBuyLimit(Symbol(), magicNumber, Stop, commento);        
               }
            
             if(OrderTP == 0.0)
               {
                SetTakeProfitPriceBuyLimit(Symbol(), magicNumber, Take, commento);
               } 
             break;                 
            }
        }          
     }
   
   if(CounterSellLimit(Symbol(), magicNumber) > 0)
     {
      for(int w = (OrdersTotal() - 1); w >= 0; w--)
         {
          ulong Ticket = OrderGetTicket(w);
          long OrderMagicNumber = OrderGetInteger(ORDER_MAGIC);
          string OrderComment = OrderGetString(ORDER_COMMENT);
          string OrderSymbol = OrderGetString(ORDER_SYMBOL);
          long OrderType = OrderGetInteger(ORDER_TYPE);       
          double OrderTP = OrderGetDouble(ORDER_TP);       
          double OrderSL = OrderGetDouble(ORDER_SL);       
         
          if(OrderSymbol == Symbol() && OrderMagicNumber == magicNumber && OrderType == ORDER_TYPE_SELL_LIMIT && OrderComment == commento)
            {
             if(OrderSL == 0.0)
               {
                SetStopLossPriceSellLimit(Symbol(), magicNumber, Stop, commento);   
               }
            
             if(OrderTP == 0.0)
               {
                SetTakeProfitPriceSellLimit(Symbol(), magicNumber, Take, commento);             
               }
             break;                 
            }
         }       
     }  
   
// TP & SL Ordini Mercato //
   
   if(CounterBuy(Symbol(),magicNumber) > 0)
     {
      for(int w = (PositionsTotal() - 1); w >= 0; w--)
         {
          ulong Ticket = PositionGetTicket(w);
          long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
          string PositionComment = PositionGetString(POSITION_COMMENT);
          string PositionSymbol = PositionGetString(POSITION_SYMBOL);
          long PositionDirection = PositionGetInteger(POSITION_TYPE);       
          double PositionTP = PositionGetDouble(POSITION_TP);       
          double PositionSL = PositionGetDouble(POSITION_SL);       
        
          if(PositionSymbol == Symbol() && PositionMagicNumber == magicNumber && PositionDirection == POSITION_TYPE_BUY && PositionComment == commento)     
            {             
             if(PositionSL == 0.0)
               {
                SetStopLossPriceBuy(Symbol(),magicNumber,Stop,commento);        
               }
             
             if(PositionTP == 0.0)
               {
                SetTakeProfitPriceBuy(Symbol(),magicNumber,Take,commento);
               }
             break;                 
            }
         }       
     }   
         
   if(CounterSell(Symbol(),magicNumber) > 0)
     {
      for(int w = (PositionsTotal() - 1); w >= 0; w--)
         {
          ulong Ticket = PositionGetTicket(w);
          long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
          string PositionComment = PositionGetString(POSITION_COMMENT);
          string PositionSymbol = PositionGetString(POSITION_SYMBOL);
          long PositionDirection = PositionGetInteger(POSITION_TYPE);       
          double PositionTP = PositionGetDouble(POSITION_TP);       
          double PositionSL = PositionGetDouble(POSITION_SL);       
        
          if(PositionSymbol == Symbol() && PositionMagicNumber == magicNumber && PositionDirection == POSITION_TYPE_SELL && PositionComment == commento)     
            {
             if(PositionSL == 0.0)
               {
                SetStopLossPriceSell(Symbol(),magicNumber,Stop,commento);   
               }
             
             if(PositionTP == 0.0)
               {
                SetTakeProfitPriceSell(Symbol(),magicNumber,Take,commento);             
               }
             break;                 
            }
         }       
     }
        
// Interfaccia //

   InterfacciaTick(Symbol(),Saldo);
  }

//+------------------------------------------------------------------+
//| On Chart                                                         |
//+------------------------------------------------------------------+

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam == "TP")
        {
         Take = NormalizeDouble(StringToDouble(ObjectGetString(0,"TP",OBJPROP_TEXT)),Digit(Symbol()));
         Print("The Take Profit Price is set to : "+DoubleToString(Take,Digit(Symbol())));
        }
      if(sparam == "SL")
        {
         Stop = NormalizeDouble(StringToDouble(ObjectGetString(0,"SL",OBJPROP_TEXT)),Digit(Symbol()));
         Print("The Stop Loss is set to : "+DoubleToString(Stop,Digit(Symbol())));
        }
      if(sparam == "PrezzoLimite")
        {
         Price = NormalizeDouble(StringToDouble(ObjectGetString(0,"PrezzoLimite",OBJPROP_TEXT)),Digit(Symbol()));
         Print("The Entry Price is set to : "+DoubleToString(Price,Digit(Symbol())));
        }        
     }   
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == "Conservative")
        {
         Risk = 0.25;
        }
      if(sparam == "Medium")
        {
         Risk = 0.50;
        }
      if(sparam == "Aggressive")
        {
         Risk = 0.75;
        }
      if(sparam == "Limite")
        {
         Limitexist = 1;
        }
      if(sparam == "Mercato")
        {
         Limitexist = 0;
        } 
      if(sparam == "AttivaABE") 
        {
         ABE = 1;
        }
      if(sparam == "DisattivaABE") 
        {
         ABE = 0;
        }
      if(sparam == "DVRAttiva") 
        {
         DVR = 1;
        }
      if(sparam == "DVRDisattiva") 
        {
         DVR = 0;
        }  
      if(sparam == "Compra" && Lots != 0.0 && Limitexist == 0)
        {
         if(Stop < Ask(Symbol()) && (Take == 0.0 || Take > Ask(Symbol())))
           {
            SendBuy(Lots,Symbol(),commento,magicNumber);
            SetTakeProfitPriceBuy(Symbol(),magicNumber,Take,commento);
            SetStopLossPriceBuy(Symbol(),magicNumber,Stop,commento);             
           }
         else
           {
            Alert("Incorrect parameters to Open a Buy Order");
           }              
        }
      if(sparam == "Vendi"  && Lots != 0.0 && Limitexist == 0)
        {
         if(Stop > Ask(Symbol()) && (Take == 0.0 || Take < Ask(Symbol())))
           {
            SendSell(Lots,Symbol(),commento,magicNumber);
            SetTakeProfitPriceSell(Symbol(),magicNumber,Take,commento);
            SetStopLossPriceSell(Symbol(),magicNumber,Stop,commento);  
           }
          else
           {
            Alert("Incorrect parameters to Open a Sell Order");
           }                
        }
      if(sparam == "Compra" && Lots != 0.0 && Limitexist > 0)
        {
         if(Stop < Price && (Take == 0.0 || Take > Price))
           {
            SendBuyLimit(Price,Lots,Symbol(),commento,magicNumber);
            SetTakeProfitPriceBuyLimit(Symbol(),magicNumber,Take,commento);
            SetStopLossPriceBuyLimit(Symbol(),magicNumber,Stop,commento);             
           }
         else
           {
            Alert("Incorrect parameters to Open a Buy Limit Order");
           }              
        }
      if(sparam == "Vendi"  && Lots != 0.0 && Limitexist > 0)
        {
         if(Stop > Price && (Take == 0.0 || Take < Price))
           {
            SendSellLimit(Price,Lots,Symbol(),commento,magicNumber);
            SetTakeProfitPriceSellLimit(Symbol(),magicNumber,Take,commento);
            SetStopLossPriceSellLimit(Symbol(),magicNumber,Stop,commento);  
           }
          else
           {
            Alert("Incorrect parameters to Open a Sell Limit Order");
           }                
        }
      if(sparam == "Chiudi Buy")
        {
         CloseAllBuy(Symbol(),magicNumber);
        }
      if(sparam == "Chiudi Sell")
        {
         CloseAllSell(Symbol(),magicNumber);
        }
      if(sparam == "BreakEven")
        {
         BreakEven(Symbol(),magicNumber,commento);
        }  
     }
  }
  
//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {
   if(reason != 3)
     {
      ObjectsDeleteAll(0,-1,-1);
     }
  }
  
//+------------------------------------------------------------------+
