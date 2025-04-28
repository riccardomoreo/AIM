//+------------------------------------------------------------------+
//|                                                        CNews.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Riccardo Moreo"

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

      if(ImportanceFilter && event[p].country_id == CurrencyToCountryId(currency) && event[p].sector != CALENDAR_SECTOR_BUSINESS)
        {
         return p;
        }
     }
   return -1;
  }
  
void CNews::GetNextNews(string currency, int OffSet, bool reset_index, Importanza Imp)
  {
   int country = CurrencyToCountryId(currency);
   
   if(reset_index)
     {
      last_event_index = 0;
      GlobalIndex = 0;
     }

   int total_events = update();

   if(total_events > 0)
     {
      datetime current_time = TimeCurrent();
      datetime closest_event_time = 0;
      int closest_event_index = -1;
      int highest_importance = -1;

      for(int next_event_index = next(last_event_index, currency, false, 0); next_event_index < total_events; next_event_index++)
        {
         bool ImportanceFilter = (Imp == Bassa) ? event[next_event_index].importance != CALENDAR_IMPORTANCE_NONE :
                                 (Imp == Media) ? event[next_event_index].importance == CALENDAR_IMPORTANCE_MODERATE ||
                                 event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH :
                                 (Imp == Alta)  ? event[next_event_index].importance == CALENDAR_IMPORTANCE_HIGH : false;

         if(ImportanceFilter && event[next_event_index].country_id == country && event[next_event_index].sector != CALENDAR_SECTOR_BUSINESS)
           {
            if(event[next_event_index].time >= current_time - PeriodSeconds(PERIOD_M10))
              {
               if(closest_event_index == -1 || event[next_event_index].time < closest_event_time)
                 {
                  closest_event_time = event[next_event_index].time;
                  closest_event_index = next_event_index;
                  highest_importance = event[next_event_index].importance;
                 }
               else
                  if(event[next_event_index].time == closest_event_time)
                    {
                     if(event[next_event_index].importance > highest_importance)
                       {
                        closest_event_index = next_event_index;
                        highest_importance = event[next_event_index].importance;
                       }
                    }
              }
           }
        }

      if(closest_event_index != -1)
        {
         last_event_index = closest_event_index;
         GlobalIndex = last_event_index;

         GlobalEventName = eventname[closest_event_index];

         StringSetLength(GlobalEventName, 52);

         GlobalEventTime = event[closest_event_index].time + OffSet;
         GlobalEventActualTime = event[closest_event_index].time;

         if(event[closest_event_index].unit == CALENDAR_UNIT_CURRENCY)
           {
            GlobalUnit = " "+currency;
           }
         else
            if(event[closest_event_index].unit == CALENDAR_UNIT_PERCENT)
              {
               GlobalUnit = " %";
              }
            else
              {
               GlobalUnit = "";
              }

         if(event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_NONE)
           {
            GlobalMultiplier = "";
           }
         else
            if(event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_THOUSANDS)
              {
               GlobalMultiplier = " K";
              }
            else
               if(event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_MILLIONS)
                 {
                  GlobalMultiplier = " M";
                 }
               else
                  if(event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_BILLIONS)
                    {
                     GlobalMultiplier = " B";
                    }
                  else
                     if(event[closest_event_index].multiplier == CALENDAR_MULTIPLIER_TRILLIONS)
                       {
                        GlobalMultiplier = " T";
                       }

         if(event[closest_event_index].event_type == CALENDAR_TYPE_INDICATOR)
           {
            GlobalEventType = 1;
           }
         else
           {
            GlobalEventType = 0;
           }

         if(event[closest_event_index].importance == CALENDAR_IMPORTANCE_HIGH)
           {
            GlobalColor = Red;
            GlobalImportance = "Alta";
            GlobalEnumImportance = CALENDAR_IMPORTANCE_HIGH;
           }
         else
            if(event[closest_event_index].importance == CALENDAR_IMPORTANCE_MODERATE)
              {
               GlobalColor = Orange;
               GlobalImportance = "Media";
               GlobalEnumImportance = CALENDAR_IMPORTANCE_MODERATE;
              }
            else
               if(event[closest_event_index].importance == CALENDAR_IMPORTANCE_LOW)
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
