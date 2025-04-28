//+------------------------------------------------------------------+
//|                                                     CAccount.mqh |
//|                                                   Moreo Riccardo |
//|                             https://www.mql5.com/it/users/moreor |
//+------------------------------------------------------------------+
#property copyright "Moreo Riccardo"
#property link      "https://www.mql5.com/it/users/moreor"

class CAccount
  {
public:
   CAccount(void) {}
   ~CAccount(void) {}

//+------------------------------------------------------------------+
//| Currency                                                         |
//+------------------------------------------------------------------+

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
   
   string ValuteToString(int valut)
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
  
//+------------------------------------------------------------------+
//| Accoount Stats                                                   |
//+------------------------------------------------------------------+  
   
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
     
   double GetTodayProfit()
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
      return profit_totale; 
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
     
   double GetPositionsProfit()
     {
      double Profit = 0;
      
      for(int w = (PositionsTotal() - 1); w >= 0; w--)
        {
         ulong Ticket = PositionGetTicket(w);
         double PositionProfit = PositionGetDouble(POSITION_PROFIT);
         double PositionSwap = PositionGetDouble(POSITION_SWAP);
         Profit += PositionProfit + PositionSwap;
        }
      return Profit;
     }
     
   double GetPositionProfitPerSymbol(string Simbolo)
     {
      double Profit = 0;
      
      for(int w = (PositionsTotal() - 1); w >= 0; w--)
        {
         ulong Ticket = PositionGetTicket(w);
         double PositionProfit = PositionGetDouble(POSITION_PROFIT);
         double PositionSwap = PositionGetDouble(POSITION_SWAP);
         string PositionSymbol = PositionGetString(POSITION_SYMBOL);
         
         if(Simbolo == PositionSymbol)
           {
            Profit += PositionProfit + PositionSwap;
           }
        }
      return Profit;
     }
  };
