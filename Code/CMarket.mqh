//+------------------------------------------------------------------+
//|                                                      CMarket.mqh |
//|                                                   Moreo Riccardo |
//|                             https://www.mql5.com/it/users/moreor |
//+------------------------------------------------------------------+
#property copyright "Moreo Riccardo"

class CMarket
 {
public:
   CMarket(void) {}
   ~CMarket(void) {}

//+------------------------------------------------------------------+
//| Market Variables                                                 |
//+------------------------------------------------------------------+

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
      return NormalizeDouble(iLow(symbol,TimeFrame,iLowest(symbol,TimeFrame,MODE_LOW,count,0)), Digit(symbol));
     }
   
   double HighestHigh(string symbol, ENUM_TIMEFRAMES TimeFrame, int count)
     {
      return NormalizeDouble(iHigh(symbol,TimeFrame,iHighest(symbol,TimeFrame,MODE_HIGH,count,0)), Digit(symbol));
     }

   int Digit(string Simbolo)
     {
      return (int)SymbolInfoInteger(Simbolo,SYMBOL_DIGITS);
     }
     
//+------------------------------------------------------------------+
//| Markets In Platform                                              |
//+------------------------------------------------------------------+
   
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

   void SplitPreferredPairs(const string source, string &result[])
      {
      int count = StringSplit(source, ',', result);
      
      if(count <= 0)
        {
         ArrayResize(result, 0);
         Print("No Pair found or error in writing the Pairs name");
         return;
        }
   
      for(int i = 0; i < count; i++)
         {
          string temp = result[i];
          StringTrimLeft(temp);
          StringTrimRight(temp);
          result[i] = temp;
         }
      }

//+------------------------------------------------------------------+
//| Markets Return                                                   |
//+------------------------------------------------------------------+

   double TimeReturn(string Simbolo, ENUM_TIMEFRAMES Tempo)
      {
       double inizio = Close(Simbolo,Tempo,1);
       double adesso = Prezzo(Simbolo);
       
       if(inizio <= 0.0) return 0.0;
       
       return ((adesso - inizio) / inizio) * 100; 
      }
 
   double YearReturn(string Simbolo)
      {
       double inizio = Close(Simbolo,PERIOD_MN1,12);
       double adesso = Prezzo(Simbolo);
       
       if(inizio <= 0.0) return 0.0;
       
       return ((adesso - inizio) / inizio) * 100; 
      } 
      
   double QuarterReturn(string Simbolo)
     {
      datetime now = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(now, dt);
   
      string year = IntegerToString(dt.year);
      datetime Q1 = StringToTime(IntegerToString(dt.year-1) + ".12.31 00:00");
      datetime Q2 = StringToTime(year + ".03.31 00:00");
      datetime Q3 = StringToTime(year + ".06.30 00:00");
      datetime Q4 = StringToTime(year + ".09.30 00:00");
      datetime inizio_quartile;
      double close_price[];
      
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
   
      if(CopyClose(Simbolo, PERIOD_D1, shift, 1, close_price) < 1)
        {
         Print("Error Retrieving Quarter starting Data", shift);
         return 0.0;
        }
   
      return ((Prezzo(Simbolo) - close_price[0]) / close_price[0]) * 100.0;;
     }

   double YTDReturn(string Simbolo)
     {
      datetime now = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(now, dt);
      string year = IntegerToString(dt.year-1);
      datetime inizio_anno = StringToTime(year + ".12.31 00:00");
      double close_price[];
      int shift = iBarShift(Simbolo, PERIOD_D1, inizio_anno, true);
      
      if(shift == -1)
        {
         Print("Error: no Data Available for the start of the year", year);
         return 0.0;
        }
   
      if(CopyClose(Simbolo, PERIOD_D1, shift, 1, close_price) < 1)
        {
         Print("Error: retrieving close price");
         return 0.0;
        }
   
      return ((Prezzo(Simbolo) - close_price[0]) / close_price[0]) * 100.0;;
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
   
   int getYear()
     {
      MqlDateTime dt;
      datetime now = TimeCurrent();
      TimeToStruct(now,dt);
      int year = dt.year;
      return year;
     }

//+------------------------------------------------------------------+
//| Utils                                                            |
//+------------------------------------------------------------------+
           
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
 };
