//+------------------------------------------------------------------+
//|                                               TradeManagement.mqh|
//|                                      Developed by Riccardo Moreo |
//+------------------------------------------------------------------+

#property copyright "Riccardo Moreo"

#include<Trade/Trade.mqh>
#include <CMarket.mqh>
CMarket market;
CTrade trade;
CPositionInfo position;
CObject object;
CHistoryOrderInfo info;
CDealInfo dealinfo;

class CTradeManagement
  {
public:
   CTradeManagement(void) {}
  ~CTradeManagement(void) {}

//+------------------------------------------------------------------+
//| Open Orders                                                      |
//+------------------------------------------------------------------+

void SendBuy(double lotti, string simbolo, string commento, int magic)
  {
   trade.SetExpertMagicNumber(magic);
   if(!trade.Buy(lotti, simbolo, SymbolInfoDouble(simbolo, SYMBOL_BID), 0.0, 0.0, commento))
     {
      int error_code = GetLastError();
      Print("Error opening BUY order for ", simbolo, ". Error Code : ", error_code);
      ResetLastError();
     }
   else
      SendNotification("Order BUY opened for " + simbolo + " at " + DoubleToString(SymbolInfoDouble(simbolo, SYMBOL_BID),market.Digit(simbolo)));
  }

void SendSell(double lotti, string simbolo, string commento, int magic)
  {
   trade.SetExpertMagicNumber(magic);
   if(!trade.Sell(lotti, simbolo, SymbolInfoDouble(simbolo, SYMBOL_ASK), 0.0, 0.0, commento))
     {
      int error_code = GetLastError();
      Print("Error opening SELL order for ", simbolo, ". Error Code : ", error_code);
      ResetLastError();
     }
   else
      SendNotification("Order SELL opened for " + simbolo + " at " + DoubleToString(SymbolInfoDouble(simbolo, SYMBOL_ASK),market.Digit(simbolo)));
  }

//Ordini Limite//

void SendBuyLimit(double Prezzo, double Lotti, string Simbolo, string Commento, int MagicNumber)
  {
   trade.SetExpertMagicNumber(MagicNumber);

   if(!trade.BuyLimit(Lotti, Prezzo, Simbolo, 0.0, 0.0, 0, 0, Commento))
     {
      int error_code = GetLastError();
      Print("Error opening BUY order for ", Simbolo, ". Error Code : ", error_code);
      ResetLastError();
     }
   else
     {
      SendNotification("Order BUY LIMIT placed for " + Simbolo + " at " + DoubleToString(Prezzo,market.Digit(Simbolo)));
     }
  }

void SendSellLimit(double Prezzo, double Lotti, string Simbolo, string Commento, int MagicNumber)
  {
   trade.SetExpertMagicNumber(MagicNumber);

   if(!trade.SellLimit(Lotti, Prezzo, Simbolo, 0.0, 0.0, 0, 0, Commento))
     {
      int error_code = GetLastError();
      Print("Error opening SELL order for ", Simbolo, ". Error Code: ", error_code);
      ResetLastError();
     }
   else
     {
      SendNotification("Order SELL LIMIT placed for " + Simbolo + " at " + DoubleToString(Prezzo,market.Digit(Simbolo)));
     }
  }
  
//+------------------------------------------------------------------+
//| Close Orders                                                     |
//+------------------------------------------------------------------+

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

void CloseAllBuy()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);
      
      if(PositionDirection == POSITION_TYPE_BUY)
        {
         trade.PositionClose(ticket);
        }
     }
  }

void CloseAllSell()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long PositionDirection = PositionGetInteger(POSITION_TYPE);

      if(PositionDirection == POSITION_TYPE_SELL)
        {
         trade.PositionClose(ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//| Count Orders                                                     |
//+------------------------------------------------------------------+

double CounterBuy(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, POSITION_TYPE_BUY);
  }

double CounterSell(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, POSITION_TYPE_SELL);
  }

double CounterBuyLimit(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, ORDER_TYPE_BUY_LIMIT);
  }

double CounterSellLimit(string Simbolo, int MagicNumber)
  {
   return CountOrders(Simbolo, MagicNumber, ORDER_TYPE_SELL_LIMIT);
  }
  
//+------------------------------------------------------------------+
//| Risk per Orders                                                  |
//+------------------------------------------------------------------+

double CalculateLotSize(string Simbolo, double SL, double Risk_Per_Trade)
  {
   double StopLoss = NormalizeDouble(SL,market.Digit(Simbolo));
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

double CalculateDynamicRisk(int Attivo,double Maxrisk, double rischio, int rm, double Saldo_iniziale, double Perdita_massima_giornaliera_percentuale)
   {
    double risk = rischio * rm;
    double Profit = AccountInfoDouble(ACCOUNT_BALANCE) - Saldo_iniziale;
    double Monetary_Risk = (risk / 100) * AccountInfoDouble(ACCOUNT_BALANCE);
    double Monetary_Risk_Final;
    double Risk_Final;
    bool alert1 = false, alert2 = false;
   
    if(Profit >= Saldo_iniziale * 0.005)
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
        Monetary_Risk_Final = Saldo_iniziale * (Maxrisk/100);
        Alert("Risk too high, your risking more than "+DoubleToString(Maxrisk/100,2)+"% so it will be set at "+DoubleToString(Maxrisk/100,2)+"%");
        alert1 = true;
       }
     
     if(Monetary_Risk_Final >= (AccountInfoDouble(ACCOUNT_BALANCE) * (Perdita_massima_giornaliera_percentuale/100)) && alert2 == false)
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
       
    return Risk_Final;
   }

//+------------------------------------------------------------------+
//| Risk Color for Interface                                         |
//+------------------------------------------------------------------+

color RiskColor(int Attivo, double rischio, int rm, double Saldo_iniziale)
   {
    double risk = rischio * rm;
    double Profit = AccountInfoDouble(ACCOUNT_BALANCE) - Saldo_iniziale;
    double Monetary_Risk = (risk / 100) * AccountInfoDouble(ACCOUNT_BALANCE);
    double Monetary_Risk_Final;
    double Risk_Final;
    color RiskColor = White;
   
    if(Profit >= Saldo_iniziale * 0.005)
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
     
     if(Attivo == 0)
      {
       Risk_Final = risk;
       Monetary_Risk_Final = Monetary_Risk;
      }
      
     if(Monetary_Risk_Final >= Profit)
       {
        RiskColor = FireBrick;
       }  
     else
       {
        RiskColor = ForestGreen;
       } 
       
    return RiskColor;
   }
   
//+------------------------------------------------------------------+
//| Set TP & SL for Orders                                           |
//+------------------------------------------------------------------+

void SetStopLossPriceBuyLimit(string Simbolo, int MagicNumber, double Entry_Price, double StopLoss, string comment)
  {
   if(StopLoss != 0)
     {
      double SL = NormalizeDouble(StopLoss-market.Spread(Simbolo),market.Digit(Simbolo));
   
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
               int j = trade.OrderModify(Ticket, Entry_Price, SL, OrderGetDouble(ORDER_TP),ORDER_TIME_DAY,0,0);
              }
           }
        }
     }
  }

void SetStopLossPriceSellLimit(string Simbolo, int MagicNumber, double Entry_Price, double StopLoss, string comment)
  {
   if(StopLoss != 0)
     {
      double SL = NormalizeDouble(StopLoss+market.Spread(Simbolo),market.Digit(Simbolo));

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
               int j = trade.OrderModify(Ticket, Entry_Price, SL, OrderGetDouble(ORDER_TP),ORDER_TIME_DAY,0,0);
              }
           }
        }
     }
  }

void SetTakeProfitPriceBuyLimit(string Simbolo, int MagicNumber, double Entry_Price, double TakeProfit, string comment)
  {
   if(TakeProfit != 0)
     {
      double TP = NormalizeDouble(TakeProfit-market.Spread(Simbolo),market.Digit(Simbolo));

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
               int j = trade.OrderModify(Ticket, Entry_Price, OrderGetDouble(ORDER_SL), TP,ORDER_TIME_DAY,0,0);
              }
           }
        }
     }
  }

void SetTakeProfitPriceSellLimit(string Simbolo, int MagicNumber, double Entry_Price, double TakeProfit, string comment)
  {
   if(TakeProfit != 0)
     {
      double TP = NormalizeDouble(TakeProfit+market.Spread(Simbolo),market.Digit(Simbolo));

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
               int j = trade.OrderModify(Ticket, Entry_Price, OrderGetDouble(ORDER_SL), TP,ORDER_TIME_DAY,0,0);
              }
           }
        }
     }
  }

void SetStopLossPriceBuy(string Simbolo, int MagicNumber, double StopLoss, string comment)
  {
   if(StopLoss != 0)
     {
      double SL = NormalizeDouble(StopLoss-market.Spread(Simbolo),market.Digit(Simbolo));

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
  }

void SetStopLossPriceSell(string Simbolo, int MagicNumber, double StopLoss, string comment)
  {
   if(StopLoss != 0)
     {
      double SL = NormalizeDouble(StopLoss+market.Spread(Simbolo),market.Digit(Simbolo));
      
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
  }

void SetTakeProfitPriceBuy(string Simbolo, int MagicNumber, double TakeProfit, string comment)
  {
   if(TakeProfit != 0)
     {
      double TP = NormalizeDouble(TakeProfit-market.Spread(Simbolo),market.Digit(Simbolo));
      
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
  }

void SetTakeProfitPriceSell(string Simbolo, int MagicNumber, double TakeProfit, string comment)
  {
   if(TakeProfit != 0)
     {
      double TP = NormalizeDouble(TakeProfit+market.Spread(Simbolo),market.Digit(Simbolo));
      
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
  }

//+------------------------------------------------------------------+
//| Break Even for Orders                                            |
//+------------------------------------------------------------------+

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
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),market.Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),market.Digit(Simbolo));

         if(PositionSL != PositionOpen)
           {
            if(market.Ask(Simbolo) > PositionOpen)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
              }
           }
        }
      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_SELL)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),market.Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),market.Digit(Simbolo));

         if(PositionSL != PositionOpen)
           {
            if(market.Bid(Simbolo) < PositionOpen)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
              }
           }
        }
     }
  }

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
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),market.Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),market.Digit(Simbolo));
         double PositionTake = NormalizeDouble(PositionGetDouble(POSITION_TP),market.Digit(Simbolo));
         double DimSL = 0;
         
         if(PositionTake != 0.0)
           {
            DimSL = PositionOpen - PositionSL;
           }
         
         
         if(PositionSL != PositionOpen)
           {
            if(market.Ask(Simbolo) >= PositionOpen + DimSL && DimSL != 0)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
               SendNotification("Trade Buy Moved To Break Even on "+Simbolo);
              }
           }
        }
      if(PositionSymbol == Simbolo && PositionMagicNumber == MagicNumber && PositionComment == comment && PositionDirection == POSITION_TYPE_SELL)
        {
         double PositionSL = NormalizeDouble(PositionGetDouble(POSITION_SL),market.Digit(Simbolo));
         double PositionOpen = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN),market.Digit(Simbolo));
         double PositionTake = NormalizeDouble(PositionGetDouble(POSITION_TP),market.Digit(Simbolo));
         double DimSL = 0;
         
         if(PositionTake != 0.0)
           {
            DimSL = PositionSL - PositionOpen;
           }

         if(PositionSL != PositionOpen)
           {
            if(market.Bid(Simbolo) <= PositionOpen - DimSL && DimSL != 0)
              {
               int j = trade.PositionModify(Ticket, PositionOpen, position.TakeProfit());
               SendNotification("Trade Sell Moved To Break Even on "+Simbolo);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Time Filter                                                      |
//+------------------------------------------------------------------+

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

private:

//+------------------------------------------------------------------+
//| Count Orders                                                     |
//+------------------------------------------------------------------+

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
};
  
