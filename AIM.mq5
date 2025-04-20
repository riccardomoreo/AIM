//+------------------------------------------------------------------+
//| AIM                                                              |
//+------------------------------------------------------------------+

#property copyright "Riccardo Moreo"
#property strict
#property icon   "AIM.ico"
#property version   "5.3"

#include<Trade/Trade.mqh>
CTrade trade;
CPositionInfo position;
CObject object;
CHistoryOrderInfo info;
CDealInfo dealinfo;

//+------------------------------------------------------------------+
//| News Class                                                       |
//+------------------------------------------------------------------+

enum Importanza
  {
   Bassa = 0,// Low
   Media = 1,// Medium
   Alta = 2,// High
  };

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
   int               last_event_index;
   int               GlobalIndex;
   string            GlobalEventName;
   datetime          GlobalEventTime;
   datetime          GlobalEventActualTime;
   string            GlobalUnit;
   string            GlobalMultiplier;
   int               GlobalEventType;
   color             GlobalColor;
   string            GlobalImportance;
   int               GlobalEnumImportance;
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
   void              GetNextNews(string currency, int OffSet, bool reset_index, Importanza Imp);
   string            GetSummary();

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

CNews News;

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

   if(!FileIsExist("News\\newshistory.bin",FILE_COMMON))
     {
      filehandle=FileOpen("News\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
      if(filehandle!=INVALID_HANDLE)
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,": creating new file common/files/News/newshistory.bin");
           }
        }
      else
        {
         if(printlog_info)
           {
            Print(__FUNCTION__,"invalid filehandle, can't create News history file");
           }
         return 0;
        }
      FileSeek(filehandle,0,SEEK_SET);
      FileWriteLong(filehandle,(long)last_update);
     }
   else
     {
      filehandle=FileOpen("News\\newshistory.bin",FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_COMMON|FILE_BIN);
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
            Print(__FUNCTION__,": invalid filehandle; can't open previous News history file");
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
         Print(__FUNCTION__,": time of last News update is in the future relative to timestamp of request; the existing data won't be overwritten/replaced,",
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

   if(FileIsExist("News\\newshistory.bin", FILE_COMMON))
     {
      filehandle = FileOpen("News\\newshistory.bin", FILE_READ | FILE_WRITE | FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_COMMON | FILE_BIN);

      if(filehandle != INVALID_HANDLE)
        {
         FileSeek(filehandle, 0, SEEK_SET);
         last_update = (datetime)FileReadLong(filehandle);
         if(printlog_info)
            Print(__FUNCTION__, ": previous News history file found; last update was on ", last_update, " (GMT)");
        }
      else
        {
         if(printlog_info)
            Print(__FUNCTION__, ": can't open previous News history file; invalid file handle");
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
      Print(__FUNCTION__, ": loading of News history completed, ", number_of_events, " events in memory");

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

      if(ImportanceFilter && News.event[p].country_id == CurrencyToCountryId(currency) && News.event[p].sector != CALENDAR_SECTOR_BUSINESS)
        {
         return p;
        }
     }
   return -1;
  }
  
void CNews::GetNextNews(string currency, int OffSet, bool reset_index, Importanza Imp)
  {
   int country = News.CurrencyToCountryId(currency);
   
   if(reset_index)
     {
      last_event_index = 0;
      GlobalIndex = 0;
     }

   int total_events = News.update();

   if(total_events > 0)
     {
      datetime current_time = TimeCurrent();
      datetime closest_event_time = 0;
      int closest_event_index = -1;
      int highest_importance = -1;

      for(int next_event_index = News.next(last_event_index, currency, false, 0); next_event_index < total_events; next_event_index++)
        {
         bool ImportanceFilter = (Imp == Bassa) ? News.event[next_event_index].importance != CALENDAR_IMPORTANCE_NONE :
                                 (Imp == Media) ? News.event[next_event_index].importance == CALENDAR_IMPORTANCE_MODERATE ||
                                 News.event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH :
                                 (Imp == Alta)  ? News.event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH : false;

         if(ImportanceFilter && News.event[next_event_index].country_id == country && News.event[next_event_index].sector != CALENDAR_SECTOR_BUSINESS)
           {
            if(News.event[next_event_index].time >= current_time - PeriodSeconds(PERIOD_M10))
              {
               if(closest_event_index == -1 || News.event[next_event_index].time < closest_event_time)
                 {
                  closest_event_time = News.event[next_event_index].time;
                  closest_event_index = next_event_index;
                  highest_importance = News.event[next_event_index].importance;
                 }
               else
                  if(News.event[next_event_index].time == closest_event_time)
                    {
                     if(News.event[next_event_index].importance > highest_importance)
                       {
                        closest_event_index = next_event_index;
                        highest_importance = News.event[next_event_index].importance;
                       }
                    }
              }
           }
        }

      if(closest_event_index != -1)
        {
         last_event_index = closest_event_index;
         GlobalIndex = last_event_index;

         GlobalEventName = News.eventname[closest_event_index];

         StringSetLength(GlobalEventName, 52);

         GlobalEventTime = News.event[closest_event_index].time + OffSet;
         GlobalEventActualTime = News.event[closest_event_index].time;

         if(News.event[closest_event_index].unit == CALENDAR_UNIT_CURRENCY)
           {
            GlobalUnit = " "+currency;
           }
         else
            if(News.event[closest_event_index].unit == CALENDAR_UNIT_PERCENT)
              {
               GlobalUnit = " %";
              }
            else
              {
               GlobalUnit = "";
              }

         if(News.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_NONE)
           {
            GlobalMultiplier = "";
           }
         else
            if(News.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_THOUSANDS)
              {
               GlobalMultiplier = " K";
              }
            else
               if(News.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_MILLIONS)
                 {
                  GlobalMultiplier = " M";
                 }
               else
                  if(News.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_BILLIONS)
                    {
                     GlobalMultiplier = " B";
                    }
                  else
                     if(News.event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_TRILLIONS)
                       {
                        GlobalMultiplier = " T";
                       }

         if(News.event[closest_event_index].event_type == CALENDAR_TYPE_INDICATOR)
           {
            GlobalEventType = 1;
           }
         else
           {
            GlobalEventType = 0;
           }

         if(News.event[closest_event_index].importance == CALENDAR_IMPORTANCE_HIGH)
           {
            GlobalColor = Red;
            GlobalImportance = "Alta";
            GlobalEnumImportance = CALENDAR_IMPORTANCE_HIGH;
           }
         else
            if(News.event[closest_event_index].importance == CALENDAR_IMPORTANCE_MODERATE)
              {
               GlobalColor = Orange;
               GlobalImportance = "Media";
               GlobalEnumImportance = CALENDAR_IMPORTANCE_MODERATE;
              }
            else
               if(News.event[closest_event_index].importance == CALENDAR_IMPORTANCE_LOW)
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
  
   string CNews::GetSummary()
     {
      return GlobalImportance + ": " + GlobalEventName + " at " + TimeToString(GlobalEventTime, TIME_DATE|TIME_MINUTES);
     }  

//+------------------------------------------------------------------+
//|  Functions                                                       |
//+------------------------------------------------------------------+

CNews news;

//Enum//

enum Stato 
  {
   Attivo = 0,// Activated
   Disattivo = 1,// Deactivated
  };
  
enum RT
  {
   LR, // Low Risk Profile
   MR, // Medium Risk Profile
   HR, // High Risk Profile
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
         return "No Chronostory Available";
      default:
         return "Unknown Error. Error Code: " + IntegerToString(error_code);
     }
  }

//Punti//

double point(string Simbolo)
  {
   return SymbolInfoDouble(Simbolo, SYMBOL_POINT);
  }
  
double Bid(string Simbolo)
  {
   return NormalizeDouble(SymbolInfoDouble(Simbolo, SYMBOL_BID), Digit(Simbolo));
  }

double Ask(string Simbolo)
  {
   return NormalizeDouble(SymbolInfoDouble(Simbolo, SYMBOL_ASK), Digit(Simbolo));
  }

double Spread(string Simbolo)
  {
   return NormalizeDouble(Ask(Simbolo) - Bid(Simbolo), Digit(Simbolo));
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

int Digit(string Simbolo)
  {
   return (int)SymbolInfoInteger(Simbolo,SYMBOL_DIGITS);
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

//Chiudi i Buy//

void CloseBuy(string Simbolo, int MagicNumber)
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

//Chiudi i Sell//

void CloseSell(string Simbolo, int MagicNumber)
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

//Chiudi tutti i Buy//

void CloseAllBuy(int MagicNumber)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);
      
      if(PositionDirection == POSITION_TYPE_BUY && PositionMagicNumber == MagicNumber)
        {
         trade.PositionClose(ticket);
        }
     }
  }

//Chiudi tutti i Sell//

void CloseAllSell(int MagicNumber)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionDirection == POSITION_TYPE_SELL && PositionMagicNumber == MagicNumber)
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
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   string year = IntegerToString(dt.year);
   datetime Q1 = StringToTime(year + ".01.02 00:00");
   datetime Q2 = StringToTime(year + ".04.01 00:00");
   datetime Q3 = StringToTime(year + ".07.01 00:00");
   datetime Q4 = StringToTime(year + ".10.01 00:00");
   datetime inizio_quartile;
   double open_price[];
   
   if (now >= Q1 && now < Q2)
      inizio_quartile = Q1;
   else if (now >= Q2 && now < Q3)
      inizio_quartile = Q2;
   else if (now >= Q3 && now < Q4)
      inizio_quartile = Q3;
   else
      inizio_quartile = Q4;

   int shift = iBarShift(Simbolo, PERIOD_D1, inizio_quartile, true);
   if(shift == -1)
     {
      Print("Error: No Available Data for the start of the Quarter", TimeToString(inizio_quartile, TIME_DATE));
      return 0.0;
     }

   if(CopyOpen(Simbolo, PERIOD_D1, shift, 1, open_price) < 1)
     {
      Print("Error Retrieving Quarter starting Data", shift);
      return 0.0;
     }

   return ((Prezzo(Simbolo) - open_price[0]) / open_price[0]) * 100.0;;
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
   
double RendimentoAnnuale(string Simbolo)
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   string year = IntegerToString(dt.year);
   datetime inizio_anno = StringToTime(year + ".01.02 00:00");
   double open_price[];
   int shift = iBarShift(Simbolo, PERIOD_D1, inizio_anno, true);
   
   if(shift == -1)
     {
      Print("Error: no Data Available for the start of the year", year);
      return 0.0;
     }

   if(CopyOpen(Simbolo, PERIOD_D1, shift, 1, open_price) < 1)
     {
      Print("Error: retrieving open price");
      return 0.0;
     }

   return ((Prezzo(Simbolo) - open_price[0]) / open_price[0]) * 100.0;;
  }

int getYear()
  {
   MqlDateTime dt;
   datetime now = TimeCurrent();
   TimeToStruct(now,dt);
   int year = dt.year;
   return year;
  }

double RendimentoAnnualeRolling(string Simbolo)
   {
    double inizio = Open(Simbolo,PERIOD_MN1,11);
    double adesso = Prezzo(Simbolo);
    
    if(inizio <= 0.0) return 0.0;
    
    return ((adesso - inizio) / inizio) * 100; 
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

double CalculateDynamicRisk(int Attivo,double Maxrisk, double rischio, int rm)
   {
    double risk = rischio * rm;
    double Profit = AccountInfoDouble(ACCOUNT_BALANCE) - Saldo;
    double Monetary_Risk = (risk / 100) * AccountInfoDouble(ACCOUNT_BALANCE);
    double Monetary_Risk_Final;
    double Risk_Final;
    bool alert1 = false, alert2 = false;
   
    if(Profit >= Saldo * 0.005)
      {
       Monetary_Risk_Final = Monetary_Risk + (Profit * (risk/2));  
       
       if(Monetary_Risk_Final >= Profit)
         {
          Monetary_Risk_Final = Profit-5;   
         }
         
       Risk_Final = NormalizeDouble((Monetary_Risk_Final / AccountInfoDouble(ACCOUNT_BALANCE)) * 100,2);  
      }
     else
      {
       Monetary_Risk_Final = Monetary_Risk;
       Risk_Final = risk;
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
        Risk_Final = risk;
        Monetary_Risk_Final = Monetary_Risk;
        Alert("Your risking more than the max daily loss, Risk will be normalized without DVR");
        alert2 = true;
       }
     
     if(Attivo == 0)
      {
       Risk_Final = risk;
       Monetary_Risk_Final = Monetary_Risk;
      }
       
     if(Monetary_Risk_Final >= Profit)
       {
        GlobalRiskColor = Red;
        GlobalRiskColor2 = Red;
       }  
     else
       {
        GlobalRiskColor = ForestGreen;
        GlobalRiskColor2 = ForestGreen;
       } 
       
    return Risk_Final;
   }

//Perdita Giornaliera// 

double GetTodayLoss()
  {
   datetime oggi = TimeCurrent();
   datetime ieri = StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " 00:00");
   double profit_totale = 0;
   HistorySelect(ieri,oggi);
   int deals_total = HistoryDealsTotal();

   for(int i = 0; i < deals_total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
   
      if(ticket > 0)
        {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);

         profit_totale += profit + commission + swap;
        }
     }
     
   for(int j = 0; j < PositionsTotal(); j++)
      {
       double profit = PositionGetDouble(POSITION_PROFIT);
       double swap = PositionGetDouble(POSITION_SWAP);

       profit_totale += profit + swap;
      }
   return -profit_totale; 
  }

double GetTodayStartingBalance() 
  {
   datetime oggi = TimeCurrent();
   datetime ieri = StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " 00:00");
   double profit_totale = 0;
   HistorySelect(ieri,oggi);
   int deals_total = HistoryDealsTotal();

   for(int i = 0; i < deals_total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
   
      if(ticket > 0)
        {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);

         profit_totale += profit + commission + swap;
        }
     }
   return AccountInfoDouble(ACCOUNT_BALANCE) - profit_totale; 
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

//Creazione Chart//

void Chart(string Name, string Simbol, double Distance_X, double Distance_Y, double Size_X, double Size_Y, int Scale, bool exist, ENUM_TIMEFRAMES Periodo)
  {
   bool alreadyExists = ObjectFind(0, Name) >= 0;

   if(alreadyExists && exist)
     {
      ObjectSetInteger(0, Name, OBJPROP_CHART_SCALE, Scale);
      long subChartID = ObjectGetInteger(0, Name, OBJPROP_CHART_ID);
      if(subChartID > 0)
        {
         ChartSetInteger(subChartID, CHART_SCALE, Scale);
         ChartRedraw(subChartID);
        }
     }
   else
     {
      ObjectCreate(0, Name, OBJ_CHART, 0, TimeCurrent(), 0);
      ObjectSetString(0, Name, OBJPROP_SYMBOL, Simbol);
      ObjectSetInteger(0, Name, OBJPROP_PERIOD, Periodo);
      ObjectSetInteger(0, Name, OBJPROP_CHART_SCALE, Scale);
      ObjectSetInteger(0, Name, OBJPROP_DATE_SCALE, true);
      ObjectSetInteger(0, Name, OBJPROP_PRICE_SCALE, true);
      ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, (int)Distance_X);
      ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, (int)Distance_Y);
      ObjectSetInteger(0, Name, OBJPROP_XSIZE, (int)Size_X);
      ObjectSetInteger(0, Name, OBJPROP_YSIZE, (int)Size_Y);
      ObjectSetInteger(0, Name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, Name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, Name, OBJPROP_HIDDEN, true);

      long subChartID = ObjectGetInteger(0, Name, OBJPROP_CHART_ID);
      if(subChartID > 0)
        {
         ChartApplyTemplate(subChartID, "tester.tpl");
         ChartSetInteger(subChartID, CHART_MOUSE_SCROLL, false);
         ChartSetInteger(subChartID, CHART_AUTOSCROLL, false);
         ChartSetInteger(subChartID, CHART_SHOW_TRADE_LEVELS, true);
         ChartSetInteger(subChartID, CHART_MODE, CHART_CANDLES);
         ChartSetInteger(subChartID, CHART_SCALE, Scale);
         ChartRedraw(subChartID);
        }
     }

   string font = "Bahnschrift Bold";
   Button("ZP" + Name, CORNER_LEFT_UPPER, Distance_X + 10, Distance_Y + 20, 30, 30, "+", Black, White, font);
   Button("ZM" + Name, CORNER_LEFT_UPPER, Distance_X + 45, Distance_Y + 20, 30, 30, "-", Black, White, font);
  }

// Combo Box //

void ComboBox(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, string Text, color Color, color BackGround_Color, string Font, double FontSize, string& elenco[], bool OpenList, int MaxElements)
  {
   if(!ObjectFind(0,Name+"Apri") == 0)
     {
      Button(Name+"Apri",Corner,Distance_X+Size_X,Distance_Y,Size_Y,Size_Y,"«",Color,BackGround_Color,Font);
      RectangleLabel(Name+"Base",Corner,Distance_X,Distance_Y,Size_X,Size_Y,Color,BackGround_Color,BORDER_FLAT);
      Label(Name+"Testo",Corner,Distance_X+10,Distance_Y+Size_Y/8,Text,Color,Font,FontSize);
      return;
     }
   
   int size = ArraySize(elenco);
      
   if(ArraySize(elenco) >= MaxElements)
     {
      size = MaxElements;
     }
   
   if(!ObjectFind(0,Name+"Opzione1") == 0 && OpenList)
     {
      for(int i = 0;i < size;i++)
         {
          Button(Name+"Opzione"+DoubleToString(i+1,0),CORNER_LEFT_UPPER,Distance_X,Distance_Y+(Size_Y*(i+1)),Size_X,Size_Y,elenco[i],Color,BackGround_Color,Font);
         }
      Button(Name+"Apri",Corner,Distance_X+Size_X,Distance_Y,Size_Y,Size_Y,"»",Color,BackGround_Color,Font);
      Label(Name+"Testo",Corner,Distance_X+10,Distance_Y+Size_Y/8,Text,Color,Font,FontSize);
     }
   else
     {
      for(int i = 0;i < size;i++)
         {
          ObjectDelete(0,Name+"Opzione"+DoubleToString(i+1,0));
         }
      Button(Name+"Apri",Corner,Distance_X+Size_X,Distance_Y,Size_Y,Size_Y,"«",Color,BackGround_Color,Font);
      Label(Name+"Testo",Corner,Distance_X+10,Distance_Y+Size_Y/8,Text,Color,Font,FontSize);
     }
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

//Get Position Profit//

double GetPositionsProfit(string Simbolo, int MagicNumber)
  {
   double Profit = 0;
   
   for(int w = (PositionsTotal() - 1); w >= 0; w--)
     {
      ulong Ticket = PositionGetTicket(w);
      long PositionMagicNumber = PositionGetInteger(POSITION_MAGIC);
      string PositionSymbol = PositionGetString(POSITION_SYMBOL);
      double PositionProfit = PositionGetDouble(POSITION_PROFIT);
      double PositionSwap = PositionGetDouble(POSITION_SWAP);

      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber)
        {
         Profit += PositionProfit + PositionSwap;
        }
     }
   return Profit;
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
         double DimSL = 0;
         
         if(PositionTake != 0.0)
           {
            DimSL = PositionOpen - PositionSL;
           }
         
         
         if(PositionSL != PositionOpen)
           {
            if(Ask(Simbolo) >= PositionOpen + DimSL && DimSL != 0)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
               SendNotification("Trade Buy Moved To Break Even on "+Simbolo);
              }
           }
        }
      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_SELL)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),Digit(Simbolo));
         double PositionTake = NormalizeDouble(PositionGetDouble(POSITION_TP),Digit(Simbolo));
         double DimSL = 0;
         
         if(PositionTake != 0.0)
           {
            DimSL = PositionSL - PositionOpen;
           }

         if(PositionSL != PositionOpen)
           {
            if(Bid(Simbolo) <= PositionOpen - DimSL && DimSL != 0)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
               SendNotification("Trade Sell Moved To Break Even on "+Simbolo);
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

// TimeFrame to Integer //

int TimeframeToInteger(ENUM_TIMEFRAMES tf)
  {
   if(tf == PERIOD_CURRENT)
   {
    tf = (ENUM_TIMEFRAMES)Period();
   }
   
   switch(tf)
     {
      case PERIOD_M1:    return 1;
      case PERIOD_M2:    return 2;
      case PERIOD_M3:    return 3;
      case PERIOD_M4:    return 4;
      case PERIOD_M5:    return 5;
      case PERIOD_M6:    return 6;
      case PERIOD_M10:   return 10;
      case PERIOD_M12:   return 12;
      case PERIOD_M15:   return 15;
      case PERIOD_M20:   return 20;
      case PERIOD_M30:   return 30;
      case PERIOD_H1:    return 60;
      case PERIOD_H2:    return 120;
      case PERIOD_H3:    return 180;
      case PERIOD_H4:    return 240;
      case PERIOD_H6:    return 360;
      case PERIOD_H8:    return 480;
      case PERIOD_H12:   return 720;
      case PERIOD_D1:    return 1440;
      case PERIOD_W1:    return 10080;
      case PERIOD_MN1:   return 43200;
      default:           return -1;
     }
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
         bool ImportanceFilter = (Impo == Bassa) ? news.event[next_event_index].importance != CALENDAR_IMPORTANCE_NONE :
                                 (Impo == Media) ? news.event[next_event_index].importance == CALENDAR_IMPORTANCE_MODERATE ||
                                 news.event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH :
                                 (Impo == Alta)  ? news.event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH : false;

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

//Valuta Conto//

string valuta_conto()
  {
   string v = AccountInfoString(ACCOUNT_CURRENCY);
   string vs = "";
   
   if(v == "USD")
     {
      vs = "$";
     }
   
   if(v == "EUR")
     {
      vs = "€";
     }  
     
   if(v == "GBP")
     {
      vs = "£";
     }  
     
   if(v == "CHF")
     {
      vs = "CHF";
     }  
     
   if(v == "JPY")
     {
      vs = "¥";
     }     
    
   return vs;
  }

//Colore Per Rendimento//

color AssegnaColoreRendimento(double rendimento)
  {
   color colore = White;
   
   if(rendimento >= 0)
     {
      colore = ForestGreen;
     }
   else
     if(rendimento < 0)
       {
        colore = FireBrick;
       }  
   
   return colore;
  }

//Ottieni Simboli//

void getSimboliTerminale(ENUM_SYMBOL_SECTOR settore, string &res[])
  {
   string symbols[];
   int total = SymbolsTotal(false);  
   int j = 0;
   ArrayResize(symbols, total);
   
   for(int i = 0; i < total; i++)
      {
       symbols[i] = SymbolName(i, false);
      }
   
   for(int i = 0; i < ArraySize(symbols); i++)
      {
       if(settore == SymbolInfoInteger(symbols[i],SYMBOL_SECTOR))
         {
          ArrayResize(res,j+1);
          res[j] = symbols[i];
          j++;
         }
      }   
  }
  
//Interfaccia//

void InterfacciaInit(string simbolo, string simbolo_2, double conto, Importanza importance, int offSet)
  {
//Variabili Dinamiche//
   long fontsize = FontUI;
   string font = "Bahnschrift Bold";
   Periodos = ChartPeriod(0);
   
   if(Simbolo2 != "None")
     { 
//Creazione Sfondo//
      RectangleLabel("Bordo",CORNER_LEFT_UPPER,0,0,1200,800,Black,Gold,BORDER_FLAT);
      RectangleLabel("Sfondo",CORNER_LEFT_UPPER,5,5,1190,790,White,Black,BORDER_FLAT);
      RectangleLabel("BordoTitolo",CORNER_LEFT_UPPER,0,800,1200,heightscreen-800,Gold,Gold,BORDER_FLAT); 
      RectangleLabel("SfondoTitolo",CORNER_LEFT_UPPER,5,805,1190,heightscreen-810,Black,Black,BORDER_FLAT); 
      Label("AIM",CORNER_LEFT_UPPER,20,800+(heightscreen-800)/3,"A.I.M. Active Investment Management",DarkGoldenrod,font,fontsize*1.5);    
      Label("OraLocale",CORNER_LEFT_UPPER,500,800+(heightscreen-800)/3,TimeToString(TimeCurrent()+(PeriodSeconds(PERIOD_H1)*offSet),TIME_DATE)+" "+TimeToString(TimeCurrent()+(PeriodSeconds(PERIOD_H1)*offSet),TIME_MINUTES),White,font,fontsize*1.5);
      Label("Company",CORNER_LEFT_UPPER,800,800+(heightscreen-800)/3,"Broker : "+AccountInfoString(ACCOUNT_COMPANY),White,font,fontsize*1.5);
      RectangleLabel("Colonna1",CORNER_LEFT_UPPER,5,5,400,790,White,Black,BORDER_RAISED);
      RectangleLabel("Colonna2",CORNER_LEFT_UPPER,400,5,400,790,White,Black,BORDER_RAISED);
      RectangleLabel("Colonna3",CORNER_LEFT_UPPER,795,5,400,790,White,Black,BORDER_RAISED);
      Button("Aggiungi",CORNER_LEFT_UPPER,350,20,20,20,"-",Black,White,font);
      CW = widthscreen-1200;
      CH = heightscreen/2;
      Chart("Grafico",simbolo,1200,0,CW,CH,scale,true,PERIOD_CURRENT);
      Chart("Grafico1",simbolo_2,1200,CH,CW,CH,scale2,true,PERIOD_CURRENT);
//Tabella Mercato//
      ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,20,120,20,Settore1,White,Black,font,fontsize*1.1,Settore,false,MaxList);
      ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,20,120,20,Simbolo1,White,Black,font,fontsize*1.1,simbolo_settore_1,false,MaxList);
      Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask :  NA",ForestGreen,font,fontsize);
      Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread :  NA",White,font,fontsize);
      Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid :  NA",FireBrick,font,fontsize);
      Label("G",CORNER_LEFT_UPPER,15,110,"Daily Return : ",White,font,fontsize);
      Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,"NA",G,font,fontsize);
      Label("S",CORNER_LEFT_UPPER,15,160,"Weekly Return : ",White,font,fontsize);
      Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,"NA",S,font,fontsize);
      Label("M",CORNER_LEFT_UPPER,15,210,"Monthly Return : ",White,font,fontsize);
      Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,"NA",M,font,fontsize);
      Label("Q",CORNER_LEFT_UPPER,15,260,"Quarterly Return ("+GetCurrentQuarter()+") : ",White,font,fontsize);
      Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,"NA",Q,font,fontsize);
      Label("A",CORNER_LEFT_UPPER,15,310,"Yearly Return ("+DoubleToString(getYear(),0)+") : ",White,font,fontsize); 
      Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,"NA",A,font,fontsize);
      Label("AR",CORNER_LEFT_UPPER,15,360,"Yearly Rolling Return :  ",White,font,fontsize);
      Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,"NA",AR,font,fontsize);
//Tabella Operativa//
      Label("RiskProfile",CORNER_LEFT_UPPER,15,400,"Risk Profile : "+RP,DarkGoldenrod,font,fontsize*1.3);
      Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : NA",White,font,fontsize);
      Button("Conservative",CORNER_LEFT_UPPER,15,480,110,50,"Conservative",Black,LightGoldenrod,font);
      Button("Medium",CORNER_LEFT_UPPER,145,480,110,50,"Medium",Black,Gold,font);
      Button("Aggressive",CORNER_LEFT_UPPER,280,480,110,50,"Aggressive",Black,DarkGoldenrod,font);
      Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : 0.00%",GlobalRiskColor,font,fontsize);
      Label("SeLimite",CORNER_LEFT_UPPER,15,580,"Limit Order Price : ",White,font,fontsize);
      Edit("PrezzoLimite",CORNER_LEFT_UPPER,175,580,100,22.5,"",White,font,fontsize);
      Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : NA",White,font,fontsize);
      Label("SetSL",CORNER_LEFT_UPPER,15,620,"Stop Loss Price : ",White,font,fontsize);
      Edit("SL",CORNER_LEFT_UPPER,175,620,100,22.5,"",White,font,fontsize);
      Label("SetTP",CORNER_LEFT_UPPER,15,660,"Take Profit Price : ",White,font,fontsize);
      Edit("TP",CORNER_LEFT_UPPER,175,660,100,22.5,"",White,font,fontsize);
      Button("Compra",CORNER_LEFT_UPPER,15,690,90,50,"Buy",Black,LimeGreen,font);
      Button("Chiudi Buy",CORNER_LEFT_UPPER,15,740,90,50,"Close Buy",Black,FireBrick,font);
      Button("Vendi",CORNER_LEFT_UPPER,300,690,90,50,"Sell",Black,LimeGreen,font);
      Button("Chiudi Sell",CORNER_LEFT_UPPER,300,740,90,50,"Close Sell",Black,FireBrick,font);
      Button("BreakEven",CORNER_LEFT_UPPER,105,690,195,100,"Break Even",Black,Gold,font);
//Tabella Mercato 2//
      ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,20,120,20,Settore2,White,Black,font,fontsize*1.1,Settore,false,MaxList);
      ComboBox("SecondoSimbolo",CORNER_LEFT_UPPER,630,20,120,20,Simbolo2,White,Black,font,fontsize*1.1,simbolo_settore_2,false,MaxList);
      Label("Ask2",CORNER_LEFT_UPPER,410,70,"Ask :  NA",ForestGreen,font,fontsize);
      Label("Spread2",CORNER_LEFT_UPPER,525,70,"Spread :  NA",White,font,fontsize);
      Label("Bid2",CORNER_LEFT_UPPER,655,70,"Bid :  NA",FireBrick,font,fontsize);
      Label("G2",CORNER_LEFT_UPPER,410,110,"Daily Return : ",White,font,fontsize);
      Label("AndamentoGiornaliera2",CORNER_LEFT_UPPER,515,110,"NA",G2,font,fontsize);
      Label("S2",CORNER_LEFT_UPPER,410,160,"Weekly Return : ",White,font,fontsize);
      Label("AndamentoSettimanale2",CORNER_LEFT_UPPER,535,160,"NA",S2,font,fontsize);
      Label("M2",CORNER_LEFT_UPPER,410,210,"Monthly Return : ",White,font,fontsize);
      Label("AndamentoMensile2",CORNER_LEFT_UPPER,540,210,"NA",M2,font,fontsize);
      Label("Q2",CORNER_LEFT_UPPER,410,260,"Quarterly Return ("+GetCurrentQuarter()+") : ",White,font,fontsize);
      Label("AndamentoQuartile2",CORNER_LEFT_UPPER,585,260,"NA",Q_2,font,fontsize);
      Label("A2",CORNER_LEFT_UPPER,410,310,"Yearly Return ("+DoubleToString(getYear(),0)+") : ",White,font,fontsize); 
      Label("AndamentoAnnuale2",CORNER_LEFT_UPPER,580,310,"NA",A2,font,fontsize);
      Label("AR2",CORNER_LEFT_UPPER,410,360,"Yearly Rolling Return :  ",White,font,fontsize);
      Label("AndamentoAnnualeRolling2",CORNER_LEFT_UPPER,585,360,"NA",AR2,font,fontsize);
//Tabella Operativa 2//
      Label("RiskProfile2",CORNER_LEFT_UPPER,410,400,"Risk Profile : "+RP2,DarkGoldenrod,font,fontsize*1.3);
      Label("RiskSU2",CORNER_LEFT_UPPER,410,440,"Setup Risk : NA",White,font,fontsize);
      Button("Conservative2",CORNER_LEFT_UPPER,410,480,110,50,"Conservative",Black,LightGoldenrod,font);
      Button("Medium2",CORNER_LEFT_UPPER,540,480,110,50,"Medium",Black,Gold,font);
      Button("Aggressive2",CORNER_LEFT_UPPER,675,480,110,50,"Aggressive",Black,DarkGoldenrod,font);
      Label("Rischio2",CORNER_LEFT_UPPER,410,545,"Risk per Trade : 0.00%",GlobalRiskColor2,font,fontsize);
      Label("SeLimite2",CORNER_LEFT_UPPER,410,580,"Limit Order Price : ",White,font,fontsize);
      Edit("PrezzoLimite2",CORNER_LEFT_UPPER,570,580,100,22.5,"",White,font,fontsize);
      Label("Tipo2",CORNER_LEFT_UPPER,680,580,"Order Type : NA",White,font,fontsize);
      Label("SetSL2",CORNER_LEFT_UPPER,410,620,"Stop Loss Price : ",White,font,fontsize);
      Edit("SL2",CORNER_LEFT_UPPER,570,620,100,22.5,"",White,font,fontsize);
      Label("SetTP2",CORNER_LEFT_UPPER,410,660,"Take Profit Price : ",White,font,fontsize);
      Edit("TP2",CORNER_LEFT_UPPER,570,660,100,22.5,"",White,font,fontsize);
      Button("Compra2",CORNER_LEFT_UPPER,410,690,90,50,"Buy",Black,LimeGreen,font);
      Button("Chiudi Buy2",CORNER_LEFT_UPPER,410,740,90,50,"Close Buy",Black,FireBrick,font);
      Button("Vendi2",CORNER_LEFT_UPPER,695,690,90,50,"Sell",Black,LimeGreen,font);
      Button("Chiudi Sell2",CORNER_LEFT_UPPER,695,740,90,50,"Close Sell",Black,FireBrick,font);
      Button("BreakEven2",CORNER_LEFT_UPPER,500,690,195,100,"Break Even",Black,Gold,font);   
//Tabella Account//
      ObjectDelete(0,"Account");
      ObjectDelete(0,"PNL");
      ObjectDelete(0,"PNLToday");
      ObjectDelete(0,"PerditaGioraliera");
      ObjectDelete(0,"PerditaMassima");
      ObjectDelete(0,"ABE");
      ObjectDelete(0,"AttivaABE");
      ObjectDelete(0,"DisattivaABE");
      ObjectDelete(0,"DVR");
      ObjectDelete(0,"DVRAttiva");
      ObjectDelete(0,"DVRDisattiva");
      ObjectDelete(0,"TotalClose");
      Label("Account",CORNER_LEFT_UPPER,810,20,"Account Starting Balance : "+DoubleToString(Saldo,0)+" "+valuta_conto(),DarkGoldenrod,font,fontsize*1.3);
      Label("PNL",CORNER_LEFT_UPPER,810,70,"Total P&L :  NA",PL,font,fontsize);
      Label("PNLToday",CORNER_LEFT_UPPER,980,70,"Postion's P&L :  NA",PLToday,font,fontsize);
      Label("PerditaGioraliera",CORNER_LEFT_UPPER,810,112.5,"Max Daily Loss :  NA",PGclr,font,fontsize);
      Label("PerditaMassima",CORNER_LEFT_UPPER,810,155,"Max Total Loss :  NA",PTclr,font,fontsize);
      Label("ABE",CORNER_LEFT_UPPER,810,197.5,"Automatic Break Even :  NA",White,font,fontsize);
      Button("AttivaABE",CORNER_LEFT_UPPER,810,235,180,50,"Activate ABE",Black,Gold,font);
      Button("DisattivaABE",CORNER_LEFT_UPPER,1000,235,180,50,"Deactivate ABE",Black,Gold,font);
      Label("DVR",CORNER_LEFT_UPPER,810,295,"Dynamic Variable Risk :  NA",White,font,fontsize);
      Button("DVRAttiva",CORNER_LEFT_UPPER,810,330,180,50,"Activate DVR",Black,Gold,font);
      Button("DVRDisattiva",CORNER_LEFT_UPPER,1000,330,180,50,"Deactivate DVR",Black,Gold,font);
      Button("TotalClose",CORNER_LEFT_UPPER,1150,25,25,25,"X",Red,White,font);
     }  
   else
     {
//Creazione Sfondo//
      ObjectsDeleteAll(0,-1,-1);
      RectangleLabel("Bordo",CORNER_LEFT_UPPER,0,0,800,800,Black,Gold,BORDER_FLAT);
      RectangleLabel("Sfondo",CORNER_LEFT_UPPER,5,5,790,790,White,Black,BORDER_FLAT);
      RectangleLabel("BordoTitolo",CORNER_LEFT_UPPER,0,800,800,heightscreen-800,Gold,Gold,BORDER_FLAT);
      RectangleLabel("SfondoTitolo",CORNER_LEFT_UPPER,5,805,790,heightscreen-810,Black,Black,BORDER_FLAT);
      Label("AIM",CORNER_LEFT_UPPER,20,800+(heightscreen-800)/3,"A.I.M. Active Investment Management",DarkGoldenrod,font,fontsize*1.5);
      Label("OraLocale",CORNER_LEFT_UPPER,500,800+(heightscreen-800)/3,TimeToString(TimeCurrent()+(PeriodSeconds(PERIOD_H1)*offSet),TIME_DATE)+" "+TimeToString(TimeCurrent()+(PeriodSeconds(PERIOD_H1)*offSet),TIME_MINUTES),White,font,fontsize*1.5);
      RectangleLabel("Colonna1",CORNER_LEFT_UPPER,5,5,400,790,White,Black,BORDER_RAISED);
      RectangleLabel("Colonna2",CORNER_LEFT_UPPER,400,5,395,790,White,Black,BORDER_RAISED);
      Button("Aggiungi",CORNER_LEFT_UPPER,350,20,20,20,"+",Black,White,font);
      CW = widthscreen-800;
      CH = heightscreen;
      Chart("Grafico",simbolo,800,0,widthscreen-800,heightscreen,scale,true,PERIOD_CURRENT);
//Tabella Mercato//
      ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,20,120,20,Settore1,White,Black,font,fontsize*1.1,Settore,false,MaxList);
      ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,20,120,20,Simbolo1,White,Black,font,fontsize*1.1,simbolo_settore_1,false,MaxList);
      Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask :  NA",ForestGreen,font,fontsize);
      Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread :  NA",White,font,fontsize);
      Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid :  NA",FireBrick,font,fontsize);
      Label("G",CORNER_LEFT_UPPER,15,110,"Daily Return : ",White,font,fontsize);
      Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,"NA",G,font,fontsize);
      Label("S",CORNER_LEFT_UPPER,15,160,"Weekly Return : ",White,font,fontsize);
      Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,"NA",S,font,fontsize);
      Label("M",CORNER_LEFT_UPPER,15,210,"Monthly Return : ",White,font,fontsize);
      Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,"NA",M,font,fontsize);
      Label("Q",CORNER_LEFT_UPPER,15,260,"Quarterly Return ("+GetCurrentQuarter()+") : ",White,font,fontsize);
      Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,"NA",Q,font,fontsize);
      Label("A",CORNER_LEFT_UPPER,15,310,"Yearly Return ("+DoubleToString(getYear(),0)+") : ",White,font,fontsize); 
      Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,"NA",A,font,fontsize);
      Label("AR",CORNER_LEFT_UPPER,15,360,"Yearly Rolling Return :  ",White,font,fontsize);
      Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,"NA",AR,font,fontsize);
//Tabella Operativa//
      Label("RiskProfile",CORNER_LEFT_UPPER,15,400,"Risk Profile : "+RP,DarkGoldenrod,font,fontsize*1.3);
      Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : NA",White,font,fontsize);
      Button("Conservative",CORNER_LEFT_UPPER,15,480,110,50,"Conservative",Black,LightGoldenrod,font);
      Button("Medium",CORNER_LEFT_UPPER,145,480,110,50,"Medium",Black,Gold,font);
      Button("Aggressive",CORNER_LEFT_UPPER,280,480,110,50,"Aggressive",Black,DarkGoldenrod,font);
      Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : 0.00%",GlobalRiskColor,font,fontsize);
      Label("SeLimite",CORNER_LEFT_UPPER,15,580,"Limit Order Price : ",White,font,fontsize);
      Edit("PrezzoLimite",CORNER_LEFT_UPPER,175,580,100,22.5,"",White,font,fontsize);
      Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : NA",White,font,fontsize);
      Label("SetSL",CORNER_LEFT_UPPER,15,620,"Stop Loss Price : ",White,font,fontsize);
      Edit("SL",CORNER_LEFT_UPPER,175,620,100,22.5,"",White,font,fontsize);
      Label("SetTP",CORNER_LEFT_UPPER,15,660,"Take Profit Price : ",White,font,fontsize);
      Edit("TP",CORNER_LEFT_UPPER,175,660,100,22.5,"",White,font,fontsize);
      Button("Compra",CORNER_LEFT_UPPER,15,690,90,50,"Buy",Black,LimeGreen,font);
      Button("Chiudi Buy",CORNER_LEFT_UPPER,15,740,90,50,"Close Buy",Black,FireBrick,font);
      Button("Vendi",CORNER_LEFT_UPPER,300,690,90,50,"Sell",Black,LimeGreen,font);
      Button("Chiudi Sell",CORNER_LEFT_UPPER,300,740,90,50,"Close Sell",Black,FireBrick,font);
      Button("BreakEven",CORNER_LEFT_UPPER,105,690,195,100,"Break Even",Black,Gold,font);
//Tabella Account//
      Label("Account",CORNER_LEFT_UPPER,410,20,"Account Starting Balance : "+DoubleToString(Saldo,0)+" "+valuta_conto(),DarkGoldenrod,font,fontsize*1.3);
      Label("PNL",CORNER_LEFT_UPPER,410,70,"Total P&L :  NA",PL,font,fontsize);
      Label("PNLToday",CORNER_LEFT_UPPER,580,70,"Postion's P&L :  NA",PLToday,font,fontsize);
      Label("PerditaGioraliera",CORNER_LEFT_UPPER,410,112.5,"Max Daily Loss :  NA",PGclr,font,fontsize);
      Label("PerditaMassima",CORNER_LEFT_UPPER,410,155,"Max Total Loss :  NA",PTclr,font,fontsize);
      Label("ABE",CORNER_LEFT_UPPER,410,197.5,"Automatic Break Even :  NA",White,font,fontsize);
      Button("AttivaABE",CORNER_LEFT_UPPER,410,235,180,50,"Activate ABE",Black,Gold,font);
      Button("DisattivaABE",CORNER_LEFT_UPPER,600,235,180,50,"Deactivate ABE",Black,Gold,font);
      Label("DVR",CORNER_LEFT_UPPER,410,295,"Dynamic Variable Risk :  NA",White,font,fontsize);
      Button("DVRAttiva",CORNER_LEFT_UPPER,410,330,180,50,"Activate DVR",Black,Gold,font);
      Button("DVRDisattiva",CORNER_LEFT_UPPER,600,330,180,50,"Deactivate DVR",Black,Gold,font);
      Button("TotalClose",CORNER_LEFT_UPPER,750,25,25,25,"X",Red,White,font);
     }
//Tabella News//
   int Max_News = 12;
   string currency = ValuteToString(Valuta);
   int coun = news.CurrencyToCountryId(currency);
   int indexes = 0;
   int news_found = 0;
   int yOffset = 60;
   datetime event_time;

   for(int index = news.GetNextNewsEvent(0, currency,importance); index >= 0; index = news.GetNextNewsEvent(index + 1, currency,importance))
     {
      if(news_found >= Max_News)
         break;
      
      indexes = index;
      event_time = news.event[index].time;

      if(event_time >= TimeCurrent() - PeriodSeconds(PERIOD_H1))
        {
         string event_name = news.eventname[indexes];
         string eventtime = TimeToString(event_time + offSet * PeriodSeconds(PERIOD_H1), TIME_DATE | TIME_MINUTES);
         string eventimportance = news.event[indexes].importance == CALENDAR_IMPORTANCE_LOW ? "Bassa" :
                                  news.event[indexes].importance == CALENDAR_IMPORTANCE_MODERATE ? "Media" :
                                  news.event[indexes].importance == CALENDAR_IMPORTANCE_HIGH ? "Alta" : "";
         string label_name = Prefix + "Name" + IntegerToString(indexes);
         string label_time = Prefix + "Time" + IntegerToString(indexes);

         StringSetLength(event_name, 35);

         color clr = Black;

         if(eventimportance == "Bassa")
            clr = DarkGray;
         if(eventimportance == "Media")
            clr = Orange;
         if(eventimportance == "Alta")
            clr = FireBrick;
         
         Label(Prefix + "Nomes",CORNER_LEFT_UPPER,410,400,"Upcoming News",DarkGoldenrod,font,fontsize*1.3);
         Label(Prefix + "Times",CORNER_LEFT_UPPER,660,400,"Date and Time",DarkGoldenrod,font,fontsize*1.3);
         Label(label_name, CORNER_LEFT_UPPER, 410, yOffset + 380, event_name, White,font,fontsize*0.9);
         Label(label_time, CORNER_LEFT_UPPER, 675, yOffset + 380, eventtime, clr, font, fontsize*0.9);
         
         if(Simbolo2 != "None")
           {   
            ObjectDelete(0,Prefix + "Nomes");
            ObjectDelete(0,Prefix + "Times");
            ObjectDelete(0,label_name);
            ObjectDelete(0,label_time);
            Label(Prefix + "Nomes",CORNER_LEFT_UPPER,810,400,"Upcoming News",DarkGoldenrod,font,fontsize*1.3);
            Label(Prefix + "Times",CORNER_LEFT_UPPER,1060,400,"Date and Time",DarkGoldenrod,font,fontsize*1.3);
            Label(label_name, CORNER_LEFT_UPPER, 810, yOffset + 380, event_name, White,font,fontsize*0.9);
            Label(label_time, CORNER_LEFT_UPPER, 1075, yOffset + 380, eventtime, clr, font, fontsize*0.9);
           }

         yOffset += 30;
         news_found++;
        }
     }
  }

void InterfacciaTick(string simbolo, string simbolo_2, double conto, int offSet)
  {
//Variabili Dinamiche//
   long fontsize = FontUI;
   string font = "Bahnschrift Bold";
   long widthscreenupdate = ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   long heightscreenupdate = ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
      
   if(Simbolo2 != "None")
     {
//Sfondo//
      CW = widthscreen-1200;
      CH = heightscreen/2;
      if((widthscreenupdate - 1200 != CW || CH != heightscreenupdate/2) || Periodos != PERIOD_CURRENT)
        {
         Chart("Grafico",simbolo,1200,0,widthscreenupdate-1200,heightscreenupdate/2,scale,false,PERIOD_CURRENT);
         Chart("Grafico1",simbolo_2,1200,heightscreenupdate/2,widthscreenupdate-1200,heightscreenupdate/2,scale2,false,PERIOD_CURRENT);
         Periodos = PERIOD_CURRENT;
        }
//Tabella Mercato//
      Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask : "+DoubleToString(Ask(simbolo),Digit(simbolo)),ForestGreen,font,fontsize);
      Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread : "+DoubleToString(Spread(simbolo),Digit(simbolo)),White,font,fontsize);
      Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid : "+DoubleToString(Bid(simbolo),Digit(simbolo)),FireBrick,font,fontsize); 
      G  = AssegnaColoreRendimento(RendimentoGiornaliero(simbolo));
      S  = AssegnaColoreRendimento(RendimentoSettimanale(simbolo));
      M  = AssegnaColoreRendimento(RendimentoMensile(simbolo));
      Q  = AssegnaColoreRendimento(RendimentoQuartile(simbolo));
      A  = AssegnaColoreRendimento(RendimentoAnnuale(simbolo));
      AR = AssegnaColoreRendimento(RendimentoAnnualeRolling(simbolo));
      Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,DoubleToString(RendimentoGiornaliero(simbolo),2)+"%",G,font,fontsize);
      Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,DoubleToString(RendimentoSettimanale(simbolo),2)+"%",S,font,fontsize);
      Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,DoubleToString(RendimentoMensile(simbolo),2)+"%",M,font,fontsize);
      Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,DoubleToString(RendimentoQuartile(simbolo),2)+"%",Q,font,fontsize);
      Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,DoubleToString(RendimentoAnnuale(simbolo),2)+"%",A,font,fontsize);
      Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,DoubleToString(RendimentoAnnualeRolling(simbolo),2)+"%",AR,font,fontsize);
//Tabella Operativa//
      Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : "+SR,White,font,fontsize);
      Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : "+DoubleToString(Final_Risk,2)+"%",GlobalRiskColor,font,fontsize);
      Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : "+tipo,White,font,fontsize);
//Tabella Mercato 2//
      Label("Ask2",CORNER_LEFT_UPPER,410,70,"Ask : "+DoubleToString(Ask(simbolo_2),Digit(simbolo_2)),ForestGreen,font,fontsize);
      Label("Spread2",CORNER_LEFT_UPPER,525,70,"Spread : "+DoubleToString(Spread(simbolo_2),Digit(simbolo_2)),White,font,fontsize);
      Label("Bid2",CORNER_LEFT_UPPER,655,70,"Bid : "+DoubleToString(Bid(simbolo_2),Digit(simbolo_2)),FireBrick,font,fontsize); 
      G2  = AssegnaColoreRendimento(RendimentoGiornaliero(simbolo_2));
      S2  = AssegnaColoreRendimento(RendimentoSettimanale(simbolo_2));
      M2  = AssegnaColoreRendimento(RendimentoMensile(simbolo_2));
      Q_2  = AssegnaColoreRendimento(RendimentoQuartile(simbolo_2));
      A2  = AssegnaColoreRendimento(RendimentoAnnuale(simbolo_2));
      AR2 = AssegnaColoreRendimento(RendimentoAnnualeRolling(simbolo_2));
      Label("AndamentoGiornaliera2",CORNER_LEFT_UPPER,515,110,DoubleToString(RendimentoGiornaliero(simbolo_2),2)+"%",G2,font,fontsize);
      Label("AndamentoSettimanale2",CORNER_LEFT_UPPER,535,160,DoubleToString(RendimentoSettimanale(simbolo_2),2)+"%",S2,font,fontsize);
      Label("AndamentoMensile2",CORNER_LEFT_UPPER,540,210,DoubleToString(RendimentoMensile(simbolo_2),2)+"%",M2,font,fontsize);
      Label("AndamentoQuartile2",CORNER_LEFT_UPPER,585,260,DoubleToString(RendimentoQuartile(simbolo_2),2)+"%",Q_2,font,fontsize);
      Label("AndamentoAnnuale2",CORNER_LEFT_UPPER,580,310,DoubleToString(RendimentoAnnuale(simbolo_2),2)+"%",A2,font,fontsize);
      Label("AndamentoAnnualeRolling2",CORNER_LEFT_UPPER,585,360,DoubleToString(RendimentoAnnualeRolling(simbolo_2),2)+"%",AR2,font,fontsize);
//Tabella Operativa 2//
      Label("RiskSU2",CORNER_LEFT_UPPER,410,440,"Setup Risk : "+SR2,White,font,fontsize);
      Label("Rischio2",CORNER_LEFT_UPPER,410,545,"Risk per Trade : "+DoubleToString(Final_Risk2,2)+"%",GlobalRiskColor2,font,fontsize);
      Label("Tipo2",CORNER_LEFT_UPPER,680,580,"Order Type : "+tipo2,White,font,fontsize);
//Tabella Account//
      Label("PNL",CORNER_LEFT_UPPER,810,70,"Total P&L : "+segno+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)-conto,2)+" "+valuta_conto(),PL,font,fontsize);
      Label("PNLToday",CORNER_LEFT_UPPER,990,70,"Postion's P&L : "+segnoToday+DoubleToString(GetPositionsProfit(Simbolo1,magicNumber)+GetPositionsProfit(Simbolo2,magicNumber),2)+" "+valuta_conto(),PLToday,font,fontsize);
      Label("PerditaGioraliera",CORNER_LEFT_UPPER,810,112.5,"Max Daily Loss : "+PG+" "+valuta_conto(),PGclr,font,fontsize);
      Label("PerditaMassima",CORNER_LEFT_UPPER,810,155,"Max Total Loss : "+PT+" "+valuta_conto(),PTclr,font,fontsize);
      Label("ABE",CORNER_LEFT_UPPER,810,197.5,"Automatic Break Even : "+state,White,font,fontsize);
      Label("DVR",CORNER_LEFT_UPPER,810,295,"Dynamic Variable Risk : "+state_DVR,White,font,fontsize);
     }
   else 
     {
//Sfondo//
      Label("OraLocale",CORNER_LEFT_UPPER,500,800+(heightscreenupdate-800)/3,TimeToString(TimeCurrent()+(PeriodSeconds(PERIOD_H1)*offSet),TIME_DATE)+" "+TimeToString(TimeCurrent()+(PeriodSeconds(PERIOD_H1)*offSet),TIME_MINUTES),White,font,fontsize*1.5);
      CW = widthscreen-800;
      CH = heightscreen;
      if((widthscreenupdate - 800 != CW || CH != heightscreenupdate) || Periodos != PERIOD_CURRENT)
        {
         Chart("Grafico",simbolo,800,0,widthscreenupdate-800,heightscreenupdate,scale,false,PERIOD_CURRENT);
         Periodos = PERIOD_CURRENT;
        }
//Tabella Mercato//
      Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask : "+DoubleToString(Ask(simbolo),Digit(simbolo)),ForestGreen,font,fontsize);
      Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread : "+DoubleToString(Spread(simbolo),Digit(simbolo)),White,font,fontsize);
      Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid : "+DoubleToString(Bid(simbolo),Digit(simbolo)),FireBrick,font,fontsize); 
      G  = AssegnaColoreRendimento(RendimentoGiornaliero(simbolo));
      S  = AssegnaColoreRendimento(RendimentoSettimanale(simbolo));
      M  = AssegnaColoreRendimento(RendimentoMensile(simbolo));
      Q  = AssegnaColoreRendimento(RendimentoQuartile(simbolo));
      A  = AssegnaColoreRendimento(RendimentoAnnuale(simbolo));
      AR = AssegnaColoreRendimento(RendimentoAnnualeRolling(simbolo));
      Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,DoubleToString(RendimentoGiornaliero(simbolo),2)+"%",G,font,fontsize);
      Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,DoubleToString(RendimentoSettimanale(simbolo),2)+"%",S,font,fontsize);
      Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,DoubleToString(RendimentoMensile(simbolo),2)+"%",M,font,fontsize);
      Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,DoubleToString(RendimentoQuartile(simbolo),2)+"%",Q,font,fontsize);
      Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,DoubleToString(RendimentoAnnuale(simbolo),2)+"%",A,font,fontsize);
      Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,DoubleToString(RendimentoAnnualeRolling(simbolo),2)+"%",AR,font,fontsize);
//Tabella Operativa//
      Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : "+SR,White,font,fontsize);
      Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : "+DoubleToString(Final_Risk,2)+"%",GlobalRiskColor,font,fontsize);
      Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : "+tipo,White,font,fontsize);
//Tabella Account//
      Label("PNL",CORNER_LEFT_UPPER,410,70,"Total P&L : "+segno+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)-conto,2)+" "+valuta_conto(),PL,font,fontsize);
      Label("PNLToday",CORNER_LEFT_UPPER,590,70,"Postion's P&L : "+segnoToday+DoubleToString(GetPositionsProfit(Simbolo1,magicNumber)+GetPositionsProfit(Simbolo2,magicNumber),2)+" "+valuta_conto(),PLToday,font,fontsize);
      Label("PerditaGioraliera",CORNER_LEFT_UPPER,410,112.5,"Max Daily Loss : "+PG+" "+valuta_conto(),PGclr,font,fontsize);
      Label("PerditaMassima",CORNER_LEFT_UPPER,410,155,"Max Total Loss : "+PT+" "+valuta_conto(),PTclr,font,fontsize);
      Label("ABE",CORNER_LEFT_UPPER,410,197.5,"Automatic Break Even : "+state,White,font,fontsize);
      Label("DVR",CORNER_LEFT_UPPER,410,295,"Dynamic Variable Risk : "+state_DVR,White,font,fontsize);
     }
  }
  
//+------------------------------------------------------------------+
//| Inputs & Variables                                               |
//+------------------------------------------------------------------+

input double Saldo = 100000; // Account Starting Balance
input double Perdita_Massima_Giornaliera = 5;// Max Daily Loss in Percentage
input double Perdita_Massima_Totale = 10;// Max Total Loss in Percentage
input Stato CO = Attivo;// Close All trades on Max Loss (Daily and Total)
input RT RiskProfile = MR;// Risk Profile for the First Symbol
input RT RiskProfile2 = LR;// Risk Profile for the Second Symbol
input double MaxRisk = 2;// Max Risk Per Trade
input Valute Valuta = USD; // News Currency
input Importanza Impo = Media;// Minum Importance for the News
input int TimeOffSet = -1;// Offset in Hours from the Broker's Time
input int MaxList = 15;// Max Elements in List for Pairs and Sector
input int FontUI = 12;// Font Size for User Interface
input bool SendNotifications = true;// Send Notification

string Settore[] = {"Indexes","Forex","Crypto","Metals"}, Indexes[], Crypto[], Forex[], Metals[], simbolo_settore_1[], simbolo_settore_2[];

string commento = "AIM", GlobalEventName, GlobalImportance, GlobalUnit, GlobalMultiplier,Currency, valuta, SR = "Not Selected", SR2 = "Not Selected", Prefix = "N", tipo = "", tipo2 = "",state = "", state_DVR = "",
       segno = "", PLB = "", PLS = "", PLB2 = "", PLS2 = "",RP = "", RP2 = "", PT = "", PG = "", segnoToday = "" ,Simbolo1 = "" , Simbolo2 = "", Settore1 = Settore[0], Settore2 = Settore[2];

color GlobalColor = White, GlobalRiskColor = White, G = White, S = White, M = White, Q = White, A = White, AR = White, PL = White, PTclr = White, PGclr = White,
      GlobalColor2 = White, GlobalRiskColor2 = White, G2 = White, S2 = White, M2 = White, Q_2 = White, A2 = White, AR2 = White, PLToday = White, PTclr2 = White, PGclr2 = White;

datetime GlobalEventTime, last_news_event_time = 0, news_dates[], GlobalEventActualTime;

int last_event_index = 0, magicNumber = 322974,timezone_offset = TimeOffSet * PeriodSeconds(PERIOD_H1), GlobalEventType = -1, GlobalIndex, MaxNews = 10, RM = 1, RM2 = 1, scale = 1,scale2 = 1;

static int Limitexist = 0, Limitexist2 = 0, ABE = 1, DVR = 1;

double AvaragePrice, Lots, Take, Stop, Risk, Price, AvaragePrice2, Lots2, Take2, Stop2, Risk2, Price2, TodayLoss, Final_Risk, Final_Risk2, saldo_giornaliero = AccountInfoDouble(ACCOUNT_BALANCE), 
       Perdita_Giornaliera = saldo_giornaliero * (Perdita_Massima_Giornaliera/100), Perdita_Totale, sbs, sbb, sbs2, sbb2;

long widthscreen = ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0), heightscreen = ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0), CH, CW;

bool BO = false, SO = false, APT = false, APG = false, BO2 = false, SO2 = false, PR = false, Total = false;

ENUM_CALENDAR_EVENT_IMPORTANCE GlobalEnumImportance;

ENUM_TIMEFRAMES Periodos;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
// Symbols //

   getSimboliTerminale(SECTOR_CURRENCY,Forex);
   getSimboliTerminale(SECTOR_INDEXES,Indexes);
   getSimboliTerminale(SECTOR_CURRENCY_CRYPTO,Crypto);
   getSimboliTerminale(SECTOR_COMMODITIES,Metals);
   
   Simbolo1 = Indexes[1];
   Simbolo2 = Crypto[0];
   
// News //

   news.update();

   GetNextNews("USD",timezone_offset,true);

// Rischio //
   
   //Primo Simbolo//
   
   if(RiskProfile == LR)
     {
      RM = 1;
      RP = "Low Risk";
     }
   else
      if(RiskProfile == MR)
        {
         RM = 2;
         RP = "Medium Risk";
        }
      else
         if(RiskProfile == HR)
           {
            RM = 3;
            RP = "High Risk";
           }  
   //Secondo Simbolo//
   
   if(RiskProfile2 == LR)
     {
      RM2 = 1;
      RP2 = "Low Risk";
     }
   else
      if(RiskProfile2 == MR)
        {
         RM2 = 2;
         RP2 = "Medium Risk";
        }
      else
         if(RiskProfile2 == HR)
           {
            RM2 = 3;
            RP2 = "High Risk";
           } 
            
   Button("TotalOpen",CORNER_LEFT_UPPER,20,20,150,20,"Open Dashboard",White,Black,"Bahnschrift Bold");
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| On Tick                                                          |
//+------------------------------------------------------------------+

void OnTick()
  {
// Propietà Comuni //
   // Segno //

   if(Saldo <= AccountInfoDouble(ACCOUNT_EQUITY))
     {
      segno = "+";
      PL = ForestGreen;
     }
   else
     {
      segno = "";
      PL = FireBrick;
     }  
     
   if(GetPositionsProfit(Simbolo1,magicNumber)+GetPositionsProfit(Simbolo2,magicNumber) > 0)
     {
      segnoToday = "+";
      PLToday = ForestGreen;
     }
   else 
     if(GetPositionsProfit(Simbolo1,magicNumber)+GetPositionsProfit(Simbolo2,magicNumber) < 0)
       {
        segnoToday = "";
        PLToday = FireBrick;
       }  
     else 
       if(GetPositionsProfit(Simbolo1,magicNumber)+GetPositionsProfit(Simbolo2,magicNumber) == 0)
         {
          segnoToday = "";
          PLToday = White;
         }  

   // PNL e Perdite //     
   
   TodayLoss = GetTodayLoss();
   
   Perdita_Giornaliera = (GetTodayStartingBalance() * (Perdita_Massima_Giornaliera/100)) - TodayLoss;
   
   if(TodayLoss >= Perdita_Giornaliera && APG == false)
     {
      PG = "Reached";
      PGclr = FireBrick;
      SendNotification("Max Daily Loss Reached");
      Alert("Max Daily Loss Reached");
      
      if(CO == Attivo)
        {
         CloseAllBuy(magicNumber);
         CloseAllSell(magicNumber); 
         Alert("All Opened Positions got Closed and you cannot Open more Today");
         SendNotification("All Opened Positions got Closed and you cannot Open more Today");
        }
        
      APG = true;
     }
   else if(TodayLoss < Perdita_Giornaliera)
     {
      PG = DoubleToString(Perdita_Giornaliera,2);
      PGclr = White;
      APG = false; 
     }
     
   Perdita_Totale = (AccountInfoDouble(ACCOUNT_EQUITY) - Saldo) + (Saldo * (Perdita_Massima_Totale/100));
   
   if(AccountInfoDouble(ACCOUNT_EQUITY) <= Saldo-Perdita_Totale && APT == false)
     {
      PT = "Reached";
      PTclr = FireBrick;
      SendNotification("Max Total Loss Reached");
      Alert("Max Total Loss Reached");
      
      if(CO == Attivo)
           {
            PR = true;
            CloseAllBuy(magicNumber);
            CloseAllSell(magicNumber); 
            Alert("All Opened Positions got Closed and you cannot Open more Today");
            SendNotification("All Opened Positions got Closed and you cannot Open more Today");
           }
      
      APT = true;
     }
   else if(AccountInfoDouble(ACCOUNT_EQUITY) > Saldo-Perdita_Totale)
     {
      PT = DoubleToString(Perdita_Totale,2);  
      PTclr = White;
      APT = false;
     }

   // Stato //
   
   if(ABE == 1)
     {
      state = "Activated";
      ABE(Simbolo1,magicNumber,commento);
      
      if(Simbolo2 != "None")
        {
         ABE(Simbolo2,magicNumber,commento);
        }
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

// Primo Simbolo //
     
   // Tipo Ordine // 

   if(Limitexist == 0)
     {
      tipo = "M";
     }
   else
     {
      tipo = "L";
     }        

   // Lotti //
    
   Final_Risk = CalculateDynamicRisk(DVR,MaxRisk,Risk,RM); 
    
   if(Limitexist == 0)
     {
      if(Stop != 0.0)
        {
         if(Stop > Bid(Simbolo1))
           {
            Lots = CalculateLotSize(Simbolo1, Stop - Bid(Simbolo1), Final_Risk);     
           }
          else 
             if(Stop < Ask(Simbolo1))
               {
                Lots = CalculateLotSize(Simbolo1, Ask(Simbolo1) - Stop, Final_Risk);          
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
               Lots = CalculateLotSize(Simbolo1, Stop - Price, Final_Risk);     
              }
             else 
                if(Stop < Price)
                  {
                   Lots = CalculateLotSize(Simbolo1, Price - Stop, Final_Risk);          
                  } 
           }
         else
           {
            Lots = 0.0;
           }       
        }

   // Notifiche //
   
   if(SendNotifications)
     {
      if(CounterBuy(Simbolo1,magicNumber) > 0 && BO == false)
        {
         sbb = AccountInfoDouble(ACCOUNT_BALANCE);
         SendNotification("Order Buy Opened on "+Simbolo1);
         BO = true;
        }  
      
      if(AccountInfoDouble(ACCOUNT_BALANCE) > sbb)
        {
         PLB = "Profit";
        }
      else
        {
         PLB = "Loss";
        }
      
      if(BO == true && CounterBuy(Simbolo1,magicNumber) == 0)
        {
         SendNotification("Order Buy Closed in "+PLB+" on "+Simbolo1);
         BO = false;
        } 
      
      if(CounterSell(Simbolo1,magicNumber) > 0 && SO == false)
        {
         sbs = AccountInfoDouble(ACCOUNT_BALANCE);
         SendNotification("Order Sell Opened on "+Simbolo1);
         SO = true;
        }
      
      if(AccountInfoDouble(ACCOUNT_BALANCE) > sbs)
        {
         PLS = "Profit";
        }
      else
        {
         PLS = "Loss";
        }
      
      if(SO == true && CounterSell(Simbolo1,magicNumber) == 0)
        {
         SendNotification("Order Sell Closed in "+PLS+" on "+Simbolo1);
         SO = false;
        } 
     }
     
   // TP & SL per Ordini Limite //

   if(Price > 0)
     {
      Limitexist = 1;
     }
   if(Price == 0)
     {
      Limitexist = 0;
     } 
   
   if(CounterBuyLimit(Simbolo1, magicNumber) > 0)
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
         
          if(OrderSymbol == Simbolo1 && OrderMagicNumber == magicNumber && OrderType == ORDER_TYPE_BUY_LIMIT && OrderComment == commento)
            {             
             if(OrderSL == 0.0)
               {
                SetStopLossPriceBuyLimit(Simbolo1, magicNumber, Stop-Spread(Simbolo1), commento);        
               }
            
             if(OrderTP == 0.0)
               {
                SetTakeProfitPriceBuyLimit(Simbolo1, magicNumber, Take-Spread(Simbolo1), commento);
               } 
             break;                 
            }
        }          
     }
   
   if(CounterSellLimit(Simbolo1, magicNumber) > 0)
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
         
          if(OrderSymbol == Simbolo1 && OrderMagicNumber == magicNumber && OrderType == ORDER_TYPE_SELL_LIMIT && OrderComment == commento)
            {
             if(OrderSL == 0.0)
               {
                SetStopLossPriceSellLimit(Simbolo1, magicNumber, Stop+Spread(Simbolo1), commento);   
               }
            
             if(OrderTP == 0.0)
               {
                SetTakeProfitPriceSellLimit(Simbolo1, magicNumber, Take+Spread(Simbolo1), commento);             
               }
             break;                 
            }
         }       
     }  
 
   // TP & SL Ordini Mercato //
   
   if(CounterBuy(Simbolo1,magicNumber) > 0)
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
        
          if(PositionSymbol == Simbolo1 && PositionMagicNumber == magicNumber && PositionDirection == POSITION_TYPE_BUY && PositionComment == commento)     
            {             
             if(PositionSL == 0.0)
               {
                SetStopLossPriceBuy(Simbolo1,magicNumber,Stop-Spread(Simbolo1),commento);        
               }
             
             if(PositionTP == 0.0)
               {
                SetTakeProfitPriceBuy(Simbolo1,magicNumber,Take-Spread(Simbolo1),commento);
               }
             break;                 
            }
         }       
     }   
         
   if(CounterSell(Simbolo1,magicNumber) > 0)
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
        
          if(PositionSymbol == Simbolo1 && PositionMagicNumber == magicNumber && PositionDirection == POSITION_TYPE_SELL && PositionComment == commento)     
            {
             if(PositionSL == 0.0)
               {
                SetStopLossPriceSell(Simbolo1,magicNumber,Stop+Spread(Simbolo1),commento);   
               }
             
             if(PositionTP == 0.0)
               {
                SetTakeProfitPriceSell(Simbolo1,magicNumber,Take+Spread(Simbolo1),commento);             
               }
             break;                 
            }
         }       
     }

// Secondo Simbolo //

   // Tipo Ordine //
   
   if(Limitexist2 == 0)
     {
      tipo2 = "M";
     }
   else
     {
      tipo2 = "L";
     }       
   
   // Lotti //
   
   Final_Risk2 = CalculateDynamicRisk(DVR,MaxRisk,Risk2,RM2);
    
   if(Limitexist2 == 0)
     {
      if(Stop2 != 0.0)
        {
         if(Stop2 > Bid(Simbolo2))
           {
            Lots2 = CalculateLotSize(Simbolo2, Stop2 - Bid(Simbolo2), Final_Risk2);     
           }
          else 
             if(Stop2 < Ask(Simbolo2))
               {
                Lots2 = CalculateLotSize(Simbolo2, Ask(Simbolo2) - Stop2, Final_Risk2);          
               } 
        }
      else
        {
         Lots2 = 0.0;
        }
   }
   else
      if(Limitexist2 > 0)
        {
         if(Stop2 != 0.0)
           {
            if(Stop2 > Price2)
              {
               Lots2 = CalculateLotSize(Simbolo2, Stop2 - Price2, Final_Risk2);     
              }
             else 
                if(Stop2 < Price2)
                  {
                   Lots2 = CalculateLotSize(Simbolo2, Price2 - Stop2, Final_Risk2);          
                  } 
           }
         else
           {
            Lots2 = 0.0;
           }       
        }

   // Notifiche //
   
   if(SendNotifications)
     {
      if(CounterBuy(Simbolo2,magicNumber) > 0 && BO2 == false)
        {
         sbb2 = AccountInfoDouble(ACCOUNT_BALANCE);
         SendNotification("Order Buy Opened on "+Simbolo2);
         BO2 = true;
        }  
      
      if(AccountInfoDouble(ACCOUNT_BALANCE) > sbb2)
        {
         PLB2 = "Profit";
        }
      else
        {
         PLB2 = "Loss";
        }
      
      if(BO2 == true && CounterBuy(Simbolo2,magicNumber) == 0)
        {
         SendNotification("Order Buy Closed in "+PLB2+" on "+Simbolo2);
         BO2 = false;
        } 
      
      if(CounterSell(Simbolo2,magicNumber) > 0 && SO2 == false)
        {
         sbs2 = AccountInfoDouble(ACCOUNT_BALANCE);
         SendNotification("Order Sell Opened on "+Simbolo2);
         SO2 = true;
        }
      
      if(AccountInfoDouble(ACCOUNT_BALANCE) > sbs2)
        {
         PLS2 = "Profit";
        }
      else
        {
         PLS2 = "Loss";
        }
      
      if(SO2 == true && CounterSell(Simbolo2,magicNumber) == 0)
        {
         SendNotification("Order Sell Closed in "+PLS2+" on "+Simbolo2);
         SO2 = false;
        } 
    }

   // TP & SL per Ordini Limite //
   
   if(Price2 > 0)
     {
      Limitexist2 = 1;
     }
   if(Price2 == 0)
     {
      Limitexist2 = 0;
     } 
     
   if(CounterBuyLimit(Simbolo2, magicNumber) > 0)
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
         
          if(OrderSymbol == Simbolo2 && OrderMagicNumber == magicNumber && OrderType == ORDER_TYPE_BUY_LIMIT && OrderComment == commento)
            {             
             if(OrderSL == 0.0)
               {
                SetStopLossPriceBuyLimit(Simbolo2, magicNumber, Stop2-Spread(Simbolo2), commento);        
               }
            
             if(OrderTP == 0.0)
               {
                SetTakeProfitPriceBuyLimit(Simbolo2, magicNumber, Take2-Spread(Simbolo2), commento);
               } 
             break;                 
            }
        }          
     }
   
   if(CounterSellLimit(Simbolo2, magicNumber) > 0)
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
         
          if(OrderSymbol == Simbolo2 && OrderMagicNumber == magicNumber && OrderType == ORDER_TYPE_SELL_LIMIT && OrderComment == commento)
            {
             if(OrderSL == 0.0)
               {
                SetStopLossPriceSellLimit(Simbolo2, magicNumber, Stop2+Spread(Simbolo2), commento);   
               }
            
             if(OrderTP == 0.0)
               {
                SetTakeProfitPriceSellLimit(Simbolo2, magicNumber, Take2+Spread(Simbolo2), commento);             
               }
             break;                 
            }
         }       
     }  

   // TP & SL Ordini Mercato //

   
   if(CounterBuy(Simbolo2,magicNumber) > 0)
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
        
          if(PositionSymbol == Simbolo2 && PositionMagicNumber == magicNumber && PositionDirection == POSITION_TYPE_BUY && PositionComment == commento)     
            {             
             if(PositionSL == 0.0)
               {
                SetStopLossPriceBuy(Simbolo2,magicNumber,Stop2-Spread(Simbolo2),commento);        
               }
             
             if(PositionTP == 0.0)
               {
                SetTakeProfitPriceBuy(Simbolo2,magicNumber,Take2-Spread(Simbolo2),commento);
               }
             break;                 
            }
         }       
     }   
         
   if(CounterSell(Simbolo2,magicNumber) > 0)
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
        
          if(PositionSymbol == Simbolo2 && PositionMagicNumber == magicNumber && PositionDirection == POSITION_TYPE_SELL && PositionComment == commento)     
            {
             if(PositionSL == 0.0)
               {
                SetStopLossPriceSell(Simbolo2,magicNumber,Stop2+Spread(Simbolo2),commento);   
               }
             
             if(PositionTP == 0.0)
               {
                SetTakeProfitPriceSell(Simbolo2,magicNumber,Take2+Spread(Simbolo2),commento);             
               }
             break;                 
            }
         }       
     }
        
// Interfaccia //

   if(Total == true)
     InterfacciaTick(Simbolo1,Simbolo2,Saldo,TimeOffSet);
  }

//+------------------------------------------------------------------+
//| On Chart                                                         |
//+------------------------------------------------------------------+

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      // Simbolo 1 //
      if(sparam == "TP")
        {
         Take = NormalizeDouble(StringToDouble(ObjectGetString(0,"TP",OBJPROP_TEXT)),Digit(Simbolo1));
         Print("The Take Profit Price is set to : "+DoubleToString(Take,Digit(Simbolo1)));
        }
      if(sparam == "SL")
        {
         Stop = NormalizeDouble(StringToDouble(ObjectGetString(0,"SL",OBJPROP_TEXT)),Digit(Simbolo1));
         Print("The Stop Loss is set to : "+DoubleToString(Stop,Digit(Simbolo1)));
        }
      if(sparam == "PrezzoLimite")
        {
         Price = NormalizeDouble(StringToDouble(ObjectGetString(0,"PrezzoLimite",OBJPROP_TEXT)),Digit(Simbolo1));
         Print("The Entry Price is set to : "+DoubleToString(Price,Digit(Simbolo1)));
        }  
        
      // Simbolo 2 //
      if(sparam == "TP2")
        {
         Take2 = NormalizeDouble(StringToDouble(ObjectGetString(0,"TP2",OBJPROP_TEXT)),Digit(Simbolo2));
         Print("The Take Profit Price is set to : "+DoubleToString(Take2,Digit(Simbolo2)));
        }
      if(sparam == "SL2")
        {
         Stop2 = NormalizeDouble(StringToDouble(ObjectGetString(0,"SL2",OBJPROP_TEXT)),Digit(Simbolo2));
         Print("The Stop Loss is set to : "+DoubleToString(Stop2,Digit(Simbolo2)));
        }
      if(sparam == "PrezzoLimite2")
        {
         Price2 = NormalizeDouble(StringToDouble(ObjectGetString(0,"PrezzoLimite2",OBJPROP_TEXT)),Digit(Simbolo2));
         Print("The Entry Price is set to : "+DoubleToString(Price2,Digit(Simbolo2)));
        }            
     }   
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      // Comuni //
            
      if(sparam == "TotalOpen")
        {
         ObjectDelete(0,"TotalOpen");
         InterfacciaInit(Simbolo1,Simbolo2,Saldo,Impo,TimeOffSet);
         Total = true;
        }
        
      if(sparam == "TotalClose")
        {
         ObjectsDeleteAll(0,-1,-1);
         Button("TotalOpen",CORNER_LEFT_UPPER,20,20,150,20,"Open Dashboard",White,Black,"Bahnschrift Bold");
         Total = false;
        }

      if(sparam == "Aggiungi")
        {
         if(Simbolo2 != "None")
           {
            Simbolo2 = "None";
            InterfacciaInit(Simbolo1,Simbolo2,Saldo,Impo,TimeOffSet);
            Chart("Grafico",Simbolo1,800,0,widthscreen-800,heightscreen,scale,false,PERIOD_CURRENT);
            InterfacciaTick(Simbolo1,Simbolo2,Saldo,TimeOffSet);
           }
         else 
            if(Simbolo2 == "None")
              {
               Simbolo2 = "BTCUSD";
               InterfacciaInit(Simbolo1,Simbolo2,Saldo,Impo,TimeOffSet);
               Chart("Grafico",Simbolo1,1200,0,widthscreen-1200,heightscreen/2,scale,false,PERIOD_CURRENT);
               InterfacciaTick(Simbolo1,Simbolo2,Saldo,TimeOffSet);
              }  
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
        
      if(sparam == "ZP"+"Grafico")
        {
         if(scale < 5)
           {
            scale += 1;
           }
      
         if(Simbolo2 == "None")
            Chart("Grafico", Simbolo1, 800, 0, widthscreen - 800, heightscreen, scale, true,PERIOD_CURRENT);
         else
            Chart("Grafico", Simbolo1, 1200, 0, widthscreen - 1200, heightscreen / 2, scale, true,PERIOD_CURRENT);
        }
      if(sparam == "ZM"+"Grafico")
        {
         if(scale > 1)
           {
            scale -= 1;
           }
      
         if(Simbolo2 == "None")
            Chart("Grafico", Simbolo1, 800, 0, widthscreen - 800, heightscreen, scale, true,PERIOD_CURRENT);
         else
            Chart("Grafico", Simbolo1, 1200, 0, widthscreen - 1200, heightscreen / 2, scale, true,PERIOD_CURRENT);
        }
     
     // Simbolo 1 //
      
      if(sparam == "PrimoSettoreApri")
        {
         ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,20,120,20,Settore1,White,Black,"Bahnschrift Bold",FontUI,Settore,true,MaxList);
        }
      
      for(int i = 0; i < ArraySize(Settore);i++)
         {
         if(sparam == "PrimoSettoreOpzione"+DoubleToString(i+1,0))
           {
            Settore1 = Settore[i];
            if(Settore1 == "Indexes")
              {
               ArrayFree(simbolo_settore_1);
               ArrayCopy(simbolo_settore_1,Indexes,0,0,WHOLE_ARRAY);
              }
            if(Settore1 == "Crypto")
              {
               ArrayFree(simbolo_settore_1);
               ArrayCopy(simbolo_settore_1,Crypto,0,0,WHOLE_ARRAY);
              }
            if(Settore1 == "Forex")
              {
               ArrayFree(simbolo_settore_1);
               ArrayCopy(simbolo_settore_1,Forex,0,0,WHOLE_ARRAY);
              }
            if(Settore1 == "Metals")
              {
               ArrayFree(simbolo_settore_1);
               ArrayCopy(simbolo_settore_1,Metals,0,0,WHOLE_ARRAY);
              }
            ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,20,120,20,Settore1,White,Black,"Bahnschrift Bold",FontUI,Settore,false,MaxList);
           } 
         }

      if(sparam == "PrimoSimboloApri")
        {
         ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,20,120,20,Simbolo1,White,Black,"Bahnschrift Bold",FontUI,simbolo_settore_1,true,MaxList);
        }   
      
      for(int i = 0; i < ArraySize(simbolo_settore_1);i++)
         {
         if(sparam == "PrimoSimboloOpzione"+DoubleToString(i+1,0))
           {
            Simbolo1 = simbolo_settore_1[i];
            ObjectsDeleteAll(0,-1,-1);
            if(Simbolo2 == "None")
               Chart("Grafico", Simbolo1, 800, 0, widthscreen - 800, heightscreen, scale, false, PERIOD_CURRENT);
            else
               Chart("Grafico", Simbolo1, 1200, 0, widthscreen - 1200, heightscreen / 2, scale, false, PERIOD_CURRENT);
            InterfacciaInit(Simbolo1,Simbolo2,Saldo,Impo,TimeOffSet);
            InterfacciaTick(Simbolo1,Simbolo2,Saldo,TimeOffSet);
           }      
         }  
         
      if(sparam == "Conservative")
        {
         Risk = 0.25;
         SR = "Conservative";
        }
      if(sparam == "Medium")
        {
         Risk = 0.50;
         SR = "Medium";
        }
      if(sparam == "Aggressive")
        {
         Risk = 0.75;
         SR = "Aggressive";
        }

      if(sparam == "ZP"+"Grafico")
        {
         if(scale < 5)
           {
            scale += 1;
           }
      
         if(Simbolo2 == "None")
            Chart("Grafico", Simbolo1, 800, 0, widthscreen - 800, heightscreen, scale, true,PERIOD_CURRENT);
         else
            Chart("Grafico", Simbolo1, 1200, 0, widthscreen - 1200, heightscreen / 2, scale, true,PERIOD_CURRENT);
        }
      if(sparam == "ZM"+"Grafico")
        {
         if(scale > 1)
           {
            scale -= 1;
           }
      
         if(Simbolo2 == "None")
            Chart("Grafico", Simbolo1, 800, 0, widthscreen - 800, heightscreen, scale, true,PERIOD_CURRENT);
         else
            Chart("Grafico", Simbolo1, 1200, 0, widthscreen - 1200, heightscreen / 2, scale, true,PERIOD_CURRENT);
        }

      if(sparam == "Compra" && Lots != 0.0 && Limitexist == 0 && PR == false)
        {
         if(Stop < Ask(Simbolo1) && (Take == 0.0 || Take > Ask(Simbolo1)))
           {
            SendBuy(Lots,Simbolo1,commento,magicNumber);
            SetTakeProfitPriceBuy(Simbolo1,magicNumber,Take-Spread(Simbolo1),commento);
            SetStopLossPriceBuy(Simbolo1,magicNumber,Stop-Spread(Simbolo1),commento);             
           }
         else
           {
            Alert("Incorrect parameters to Open a Buy Order on "+Simbolo1);
           }              
        }
        
      if(sparam == "Vendi"  && Lots != 0.0 && Limitexist == 0 && PR == false)
        {
         if(Stop > Ask(Simbolo1) && (Take == 0.0 || Take < Ask(Simbolo1)))
           {
            SendSell(Lots,Simbolo1,commento,magicNumber);
            SetTakeProfitPriceSell(Simbolo1,magicNumber,Take+Spread(Simbolo1),commento);
            SetStopLossPriceSell(Simbolo1,magicNumber,Stop+Spread(Simbolo1),commento);  
           }
          else
           {
            Alert("Incorrect parameters to Open a Sell Order on "+Simbolo1);
           }                
        }
        
      if(sparam == "Compra" && Lots != 0.0 && Limitexist > 0 && PR == false)
        {
         if(Stop < Price && (Take == 0.0 || Take > Price))
           {
            SendBuyLimit(Price,Lots,Simbolo1,commento,magicNumber);
            SetTakeProfitPriceBuyLimit(Simbolo1,magicNumber,Take-Spread(Simbolo1),commento);
            SetStopLossPriceBuyLimit(Simbolo1,magicNumber,Stop-Spread(Simbolo1),commento);             
           }
         else
           {
            Alert("Incorrect parameters to Open a Buy Limit Order on "+Simbolo1);
           }              
        }
        
      if(sparam == "Vendi"  && Lots != 0.0 && Limitexist > 0 && PR == false)
        {
         if(Stop > Price && (Take == 0.0 || Take < Price))
           {
            SendSellLimit(Price,Lots,Simbolo1,commento,magicNumber);
            SetTakeProfitPriceSellLimit(Simbolo1,magicNumber,Take+Spread(Simbolo1),commento);
            SetStopLossPriceSellLimit(Simbolo1,magicNumber,Stop+Spread(Simbolo1),commento);  
           }
          else
           {
            Alert("Incorrect parameters to Open a Sell Limit Order on "+Simbolo1);
           }                
        }
        
      if(sparam == "Chiudi Buy")
        {
         CloseBuy(Simbolo1,magicNumber);
        }
      if(sparam == "Chiudi Sell")
        {
         CloseSell(Simbolo1,magicNumber);
        }
        
      if(sparam == "BreakEven")
        {
         BreakEven(Simbolo1,magicNumber,commento);
        }   
               
      // Simbolo 2 //
            
      if(sparam == "SecondoSettoreApri")
        {
         ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,20,120,20,Settore2,White,Black,"Bahnschrift Bold",FontUI,Settore,true,MaxList);
        }
      
      for(int i = 0; i < ArraySize(Settore);i++)
         {
         if(sparam == "SecondoSettoreOpzione"+DoubleToString(i+1,0))
           {
            Settore2 = Settore[i];
            if(Settore2 == "Indexes")
              {
               ArrayFree(simbolo_settore_2);
               ArrayCopy(simbolo_settore_2,Indexes,0,0,WHOLE_ARRAY);
              }
            if(Settore2 == "Crypto")
              {
               ArrayFree(simbolo_settore_2);
               ArrayCopy(simbolo_settore_2,Crypto,0,0,WHOLE_ARRAY);
              }
            if(Settore2 == "Forex")
              {
               ArrayFree(simbolo_settore_2);
               ArrayCopy(simbolo_settore_2,Forex,0,0,WHOLE_ARRAY);
              }
            if(Settore2 == "Metals")
              {
               ArrayFree(simbolo_settore_2);
               ArrayCopy(simbolo_settore_2,Metals,0,0,WHOLE_ARRAY);
              }
            ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,20,120,20,Settore2,White,Black,"Bahnschrift Bold",FontUI,Settore,false,MaxList);
           } 
         }

      if(sparam == "SecondoSimboloApri")
        {
         ComboBox("SecondoSimbolo",CORNER_LEFT_UPPER,630,20,120,20,Simbolo2,White,Black,"Bahnschrift Bold",FontUI,simbolo_settore_2,true,MaxList);
        }   
      
      for(int i = 0; i < ArraySize(simbolo_settore_2);i++)
         {
         if(sparam == "SecondoSimboloOpzione"+DoubleToString(i+1,0))
           {
            Simbolo2 = simbolo_settore_2[i];
            ObjectsDeleteAll(0,-1,-1);
            Chart("Grafico1", Simbolo2, 1200, 0, widthscreen - 1200, heightscreen / 2, scale, false, PERIOD_CURRENT);
            InterfacciaInit(Simbolo1,Simbolo2,Saldo,Impo,TimeOffSet);
            InterfacciaTick(Simbolo1,Simbolo2,Saldo,TimeOffSet);
           }      
         }  
                  
      if(sparam == "Conservative2")
        {
         Risk2 = 0.25;
         SR2 = "Conservative";
        }
      if(sparam == "Medium2")
        {
         Risk2 = 0.50;
         SR2 = "Medium";
        }
      if(sparam == "Aggressive2")
        {
         Risk2 = 0.75;
         SR2 = "Aggressive";
        }
        
      if(sparam == "ZP"+"Grafico1")
        {
         if(scale2 < 5)
           {
            scale2 += 1;
           }
         Chart("Grafico1", Simbolo2, 1200, heightscreen / 2, widthscreen - 1200, heightscreen / 2, scale2, true,PERIOD_CURRENT);
        }
        
      if(sparam == "ZM"+"Grafico1")
        {
         if(scale2 > 1)
           {
            scale2 -= 1;
           }
         Chart("Grafico1", Simbolo2, 1200, heightscreen / 2, widthscreen - 1200, heightscreen / 2, scale2, true,PERIOD_CURRENT);
        }
        
      if(sparam == "Compra2" && Lots2 != 0.0 && Limitexist2 == 0 && PR == false)
        {
         if(Stop2 < Ask(Simbolo2) && (Take2 == 0.0 || Take2 > Ask(Simbolo2)))
           {
            SendBuy(Lots2,Simbolo2,commento,magicNumber);
            SetTakeProfitPriceBuy(Simbolo2,magicNumber,Take2-Spread(Simbolo2),commento);
            SetStopLossPriceBuy(Simbolo2,magicNumber,Stop2-Spread(Simbolo2),commento);             
           }
         else
           {
            Alert("Incorrect parameters to Open a Buy Order on "+Simbolo2);
           }              
        }
        
      if(sparam == "Vendi2"  && Lots2 != 0.0 && Limitexist2 == 0 && PR == false)
        {
         if(Stop2 > Ask(Simbolo2) && (Take2 == 0.0 || Take2 < Ask(Simbolo2)))
           {
            SendSell(Lots2,Simbolo2,commento,magicNumber);
            SetTakeProfitPriceSell(Simbolo2,magicNumber,Take2+Spread(Simbolo2),commento);
            SetStopLossPriceSell(Simbolo2,magicNumber,Stop2+Spread(Simbolo2),commento);  
           }
          else
           {
            Alert("Incorrect parameters to Open a Sell Order on "+Simbolo2);
           }                
        }
        
      if(sparam == "Compra2" && Lots2 != 0.0 && Limitexist2 > 0 && PR == false)
        {
         if(Stop2 < Price2 && (Take2 == 0.0 || Take2 > Price2))
           {
            SendBuyLimit(Price2,Lots2,Simbolo2,commento,magicNumber);
            SetTakeProfitPriceBuyLimit(Simbolo2,magicNumber,Take2-Spread(Simbolo2),commento);
            SetStopLossPriceBuyLimit(Simbolo2,magicNumber,Stop2-Spread(Simbolo2),commento);             
           }
         else
           {
            Alert("Incorrect parameters to Open a Buy Limit Order on "+Simbolo2);
           }              
        }
        
      if(sparam == "Vendi2"  && Lots2 != 0.0 && Limitexist2 > 0 && PR == false)
        {
         if(Stop2 > Price2 && (Take2 == 0.0 || Take2 < Price2))
           {
            SendSellLimit(Price2,Lots2,Simbolo2,commento,magicNumber);
            SetTakeProfitPriceSellLimit(Simbolo2,magicNumber,Take2+Spread(Simbolo2),commento);
            SetStopLossPriceSellLimit(Simbolo2,magicNumber,Stop2+Spread(Simbolo2),commento);  
           }
          else
           {
            Alert("Incorrect parameters to Open a Sell Limit Order on "+Simbolo2);
           }                
        }
        
      if(sparam == "Chiudi Buy2")
        {
         CloseBuy(Simbolo2,magicNumber);
        }
        
      if(sparam == "Chiudi Sell2")
        {
         CloseSell(Simbolo2,magicNumber);
        }
        
      if(sparam == "BreakEven2")
        {
         BreakEven(Simbolo2,magicNumber,commento);
        }  
     }
  }
  
//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {
   if(reason == 0 || reason == 1 || reason == 2 || reason == 4 || reason == 6 || reason == 8 || reason == 9)
     {
      ObjectsDeleteAll(0,-1,-1);
     }
  }
  
//+------------------------------------------------------------------+
