//+------------------------------------------------------------------+
//| AIM                                                              |
//+------------------------------------------------------------------+
#property copyright "Riccardo Moreo"
#property strict
#property icon   "AIM.ico"
#property version   "6.4"

#include <CObjects.mqh>
#include <CAccount.mqh>
#include <CMarket.mqh>
#include <CNews.mqh>
#include <CTradeManagement.mqh>

CObjects Obj;
CAccount Account;
CMarket Market;
CNews news;
CTradeManagement Trade;

//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+

// ENUM //

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

enum azione
  {
   Crea = 0,
   Aggiorna = 1,
   Elimina = 2,
  };

// SELEZIONE SIMBOLI //

void AssegnaSimboliPerSettore(string settore, string &simboli[])
   {
   ArrayFree(simboli);

   if(settore == "Indexes")
      ArrayCopy(simboli, Indexes, 0, 0, WHOLE_ARRAY);
   else if(settore == "Crypto")
      ArrayCopy(simboli, Crypto, 0, 0, WHOLE_ARRAY);
   else if(settore == "Forex")
      ArrayCopy(simboli, Forex, 0, 0, WHOLE_ARRAY);
   else if(settore == "Metals")
      ArrayCopy(simboli, Metals, 0, 0, WHOLE_ARRAY);
   else if(settore == "Preferred")
      ArrayCopy(simboli, Preferred, 0, 0, WHOLE_ARRAY);
   }


// INTERFACCIA //

void Interfaccia(string Simbolo1, string Simbolo2, double Saldo, int offSet, azione Azione)
   {
    bool Simbolo2Exist = Simbolo2 != "None";
    long fontsize = FontUI;
    string font = "Bahnschrift Bold";
    long heightscreen = ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
    long widthscreen = ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);

    if(Azione == Crea)
      {
       if(!Simbolo2Exist)
         {
         //Apertura//
         Obj.Button("TotalOpen",CORNER_LEFT_UPPER,75,30,150,20,"Open Dashboard",Black,Silver,"Bahnschrift Bold",false,Elimina);
         //Creazione Sfondo//       
         Obj.RectangleLabel("Bordo",CORNER_LEFT_UPPER,0,0,800,800,Gold,Gold,BORDER_FLAT,false,Crea);
         Obj.RectangleLabel("Sfondo",CORNER_LEFT_UPPER,5,5,790,790,Silver,Silver,BORDER_FLAT,false,Crea);
         Obj.RectangleLabel("BordoTitolo",CORNER_LEFT_UPPER,0,800,widthscreen,heightscreen-800,Gold,Gold,BORDER_FLAT,false,Crea);
         Obj.RectangleLabel("SfondoTitolo",CORNER_LEFT_UPPER,5,805,widthscreen-10,heightscreen-810,Black,Silver,BORDER_FLAT,false,Crea);
         Obj.Label("AIM",CORNER_LEFT_UPPER,20,800+(heightscreen-800)/2-15,"A.I.M. Active Investment Management",DarkGoldenrod,font,fontsize*1.5,false,Crea);
         Obj.Label("OraLocale",CORNER_LEFT_UPPER,widthscreen/2.5,800+(heightscreen-800)/2-15,TimeToString(TimeCurrent()+offSet,TIME_DATE|TIME_MINUTES),Black,font,fontsize*1.5,false,Crea);
         Obj.Label("Company",CORNER_LEFT_UPPER,widthscreen/1.5,800+(heightscreen-800)/2-15,"Broker : "+AccountInfoString(ACCOUNT_COMPANY),Black,font,fontsize*1.5,false,Crea);
         Obj.RectangleLabel("Colonna1",CORNER_LEFT_UPPER,5,5,400,790,DarkGoldenrod,Silver,BORDER_RAISED,false,Crea);
         Obj.RectangleLabel("Colonna2",CORNER_LEFT_UPPER,400,5,395,790,DarkGoldenrod,Silver,BORDER_RAISED,false,Crea);
         Obj.Button("Aggiungi",CORNER_LEFT_UPPER,375,10,20,20,"+",Black,White,font,false,Crea);
         Obj.RectangleLabel("SfondoGrafico",CORNER_LEFT_UPPER,800,0,widthscreen-800,800,Gold,Gold,BORDER_FLAT,false,Crea);
         Obj.Chart("Grafico",Simbolo1,805,5,widthscreen-810,790,scale1,true,PERIOD_CURRENT,Crea);
         //Tabella Mercato//
         Obj.Label("PSI",CORNER_LEFT_UPPER,20,10,"Sector :",DarkGoldenrod,font,fontsize*1.3,false,Crea);
         Obj.Label("PSY",CORNER_LEFT_UPPER,200,10,"Symbol :",DarkGoldenrod,font,fontsize*1.3,false,Crea);
         Obj.ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,40,120,20,Settore1,Black,White,font,fontsize,Settore,false,MaxList,Crea);
         Obj.ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,40,120,20,Simbolo1,Black,White,font,fontsize,simbolo_settore_1,false,MaxList,Crea);
         Obj.Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask :  NA",ForestGreen,font,fontsize,false,Crea);
         Obj.Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread :  NA",Black,font,fontsize,false,Crea);
         Obj.Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid :  NA",FireBrick,font,fontsize,false,Crea);
         Obj.Label("G",CORNER_LEFT_UPPER,15,110,"Daily Return : ",Black,font,fontsize,false,Crea);
         Obj.Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_D1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("S",CORNER_LEFT_UPPER,15,160,"Weekly Return : ",Black,font,fontsize,false,Crea);
         Obj.Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_W1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("M",CORNER_LEFT_UPPER,15,210,"Monthly Return : ",Black,font,fontsize,false,Crea);
         Obj.Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_MN1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("Q",CORNER_LEFT_UPPER,15,260,"Quarterly Return ("+Market.GetCurrentQuarter()+") : ",Black,font,fontsize,false,Crea);
         Obj.Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,"NA",Obj.AssegnaColoreRendimento(Market.QuarterReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("A",CORNER_LEFT_UPPER,15,310,"Yearly Return ("+DoubleToString(Market.getYear(),0)+") : ",Black,font,fontsize,false,Crea); 
         Obj.Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,"NA",Obj.AssegnaColoreRendimento(Market.YTDReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("AR",CORNER_LEFT_UPPER,15,360,"Yearly Rolling Return :  ",Black,font,fontsize,false,Crea);
         Obj.Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,"NA",Obj.AssegnaColoreRendimento(Market.YearReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         //Tabella Operativa//
         Obj.Label("RiskProfile",CORNER_LEFT_UPPER,15,400,"Risk Profile : "+RP,DarkGoldenrod,font,fontsize*1.3,false,Crea);
         Obj.Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : NA",Black,font,fontsize,false,Crea);
         Obj.Button("Conservative",CORNER_LEFT_UPPER,15,480,110,50,"Conservative",Black,LightGoldenrod,font,false,Crea);
         Obj.Button("Medium",CORNER_LEFT_UPPER,145,480,110,50,"Medium",Black,Gold,font,false,Crea);
         Obj.Button("Aggressive",CORNER_LEFT_UPPER,280,480,110,50,"Aggressive",Black,DarkGoldenrod,font,false,Crea);
         Obj.Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : 0.00%",Trade.RiskColor(DVRState,Risk1,Saldo),font,fontsize,false,Crea);
         Obj.Label("PF",CORNER_LEFT_UPPER,210,545,"Position P&L : 0.0"+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionProfitPerSymbol(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("SeLimite",CORNER_LEFT_UPPER,15,580,"Limit Order Price : ",Black,font,fontsize,false,Crea);
         Obj.Edit("PrezzoLimite",CORNER_LEFT_UPPER,175,580,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
         Obj.Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : NA",Black,font,fontsize,false,Crea);
         Obj.Label("SetSL",CORNER_LEFT_UPPER,15,620,"Stop Loss Price : ",Black,font,fontsize,false,Crea);
         Obj.Edit("SL",CORNER_LEFT_UPPER,175,620,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
         Obj.Label("SetTP",CORNER_LEFT_UPPER,15,660,"Take Profit Price : ",Black,font,fontsize,false,Crea);
         Obj.Edit("TP",CORNER_LEFT_UPPER,175,660,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
         Obj.Button("Compra",CORNER_LEFT_UPPER,15,690,90,50,"Buy",Black,LimeGreen,font,false,Crea);
         Obj.Button("Chiudi Buy",CORNER_LEFT_UPPER,15,740,90,50,"Close Buy",Black,FireBrick,font,false,Crea);
         Obj.Button("Vendi",CORNER_LEFT_UPPER,300,690,90,50,"Sell",Black,LimeGreen,font,false,Crea);
         Obj.Button("Chiudi Sell",CORNER_LEFT_UPPER,300,740,90,50,"Close Sell",Black,FireBrick,font,false,Crea);
         Obj.Button("BreakEven",CORNER_LEFT_UPPER,105,690,195,100,"Break Even",Black,Gold,font,false,Crea);
         //Tabella Account//
         Obj.Label("Account",CORNER_LEFT_UPPER,410,20,"Account Starting Balance : "+DoubleToString(Saldo,0)+" "+Account.valuta_conto(),DarkGoldenrod,font,fontsize*1.3,false,Crea);
         Obj.Label("PNL",CORNER_LEFT_UPPER,410,70,"Total P&L :  NA",Obj.AssegnaColoreRendimento(AccountInfoDouble(ACCOUNT_EQUITY)-Saldo,ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("PNLToday",CORNER_LEFT_UPPER,580,70,"Postion's P&L :  NA",Obj.AssegnaColoreRendimento(Account.GetPositionsProfit(),ForestGreen,FireBrick),font,fontsize,false,Crea);
         Obj.Label("PerditaGioraliera",CORNER_LEFT_UPPER,410,112.5,"Max Daily Loss :  NA",PGclr,font,fontsize,false,Crea);
         Obj.Label("PerditaMassima",CORNER_LEFT_UPPER,410,155,"Max Total Loss :  NA",PTclr,font,fontsize,false,Crea);
         Obj.Label("ABE",CORNER_LEFT_UPPER,410,197.5,"Automatic Break Even :  NA",Black,font,fontsize,false,Crea);
         Obj.Button("AttivaABE",CORNER_LEFT_UPPER,410,235,180,50,"Activate ABE",Black,Gold,font,false,Crea);
         Obj.Button("DisattivaABE",CORNER_LEFT_UPPER,600,235,180,50,"Deactivate ABE",Black,Gold,font,false,Crea);
         Obj.Label("DVR",CORNER_LEFT_UPPER,410,295,"Dynamic Variable Risk :  NA",Black,font,fontsize,false,Crea);
         Obj.Button("DVRAttiva",CORNER_LEFT_UPPER,410,330,180,50,"Activate DVR",Black,Gold,font,false,Crea);
         Obj.Button("DVRDisattiva",CORNER_LEFT_UPPER,600,330,180,50,"Deactivate DVR",Black,Gold,font,false,Crea);
         Obj.Button("TotalClose",CORNER_LEFT_UPPER,765,10,25,25,"X",Red,White,font,false,Crea);
         //Tabella News//
         int Max_News = 12;
         string currency = Account.ValuteToString(Valuta);
         int coun = news.CurrencyToCountryId(currency);
         int indexes = 0;
         int news_found = 0;
         int yOffset = 60;
         datetime event_time;
         string Prefix = "news";
      
         for(int index = news.GetNextNewsEvent(0, currency, Impo); index >= 0; index = news.GetNextNewsEvent(index + 1, currency,Impo))
           {
            if(news_found >= Max_News)
               break;
            
            indexes = index;
            event_time = news.event[index].time;
      
            if(event_time >= TimeCurrent() - PeriodSeconds(PERIOD_H1))
              {
               string event_name = news.eventname[indexes];
               string eventtime = TimeToString(event_time + offSet, TIME_DATE | TIME_MINUTES);
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
                  clr = Peru;
               if(eventimportance == "Alta")
                  clr = FireBrick;
               
               Obj.Label(Prefix + "Nomes",CORNER_LEFT_UPPER,410,400,"Upcoming News",DarkGoldenrod,font,fontsize*1.3,false,Crea);
               Obj.Label(Prefix + "Times",CORNER_LEFT_UPPER,660,400,"Date and Time",DarkGoldenrod,font,fontsize*1.3,false,Crea);
               Obj.Label(label_name, CORNER_LEFT_UPPER, 410, yOffset + 380, event_name, Black,font,fontsize*0.9,false,Crea);
               Obj.Label(label_time, CORNER_LEFT_UPPER, 675, yOffset + 380, eventtime, clr, font, fontsize*0.9,false,Crea);
               
               yOffset += 30;
               news_found++;
              }
           }
         }
       else 
          if(Simbolo2Exist)
            {
            //Apertura//
            Obj.Button("TotalOpen",CORNER_LEFT_UPPER,20,20,150,20,"Open Dashboard",Black,Silver,"Bahnschrift Bold",false,Elimina);
            //Creazione Sfondo//
            Obj.RectangleLabel("Bordo",CORNER_LEFT_UPPER,0,0,1200,800,Gold,Gold,BORDER_FLAT,false,Crea);
            Obj.RectangleLabel("Sfondo",CORNER_LEFT_UPPER,5,5,1190,790,Silver,Silver,BORDER_FLAT,false,Crea);
            Obj.RectangleLabel("BordoTitolo",CORNER_LEFT_UPPER,0,800,widthscreen,heightscreen-800,Gold,Gold,BORDER_FLAT,false,Crea);
            Obj.RectangleLabel("SfondoTitolo",CORNER_LEFT_UPPER,5,805,widthscreen-10,heightscreen-810,Black,Silver,BORDER_FLAT,false,Crea);
            Obj.Label("AIM",CORNER_LEFT_UPPER,20,800+(heightscreen-800)/2-15,"A.I.M. Active Investment Management",DarkGoldenrod,font,fontsize*1.5,false,Crea);
            Obj.Label("OraLocale",CORNER_LEFT_UPPER,widthscreen/2.5,800+(heightscreen-800)/2-15,TimeToString(TimeCurrent()+offSet,TIME_DATE|TIME_MINUTES),Black,font,fontsize*1.5,false,Crea);
            Obj.Label("Company",CORNER_LEFT_UPPER,widthscreen/1.5,800+(heightscreen-800)/2-15,"Broker : "+AccountInfoString(ACCOUNT_COMPANY),Black,font,fontsize*1.5,false,Crea);
            Obj.RectangleLabel("Colonna1",CORNER_LEFT_UPPER,5,5,400,790,DarkGoldenrod,Silver,BORDER_RAISED,false,Crea);
            Obj.RectangleLabel("Colonna2",CORNER_LEFT_UPPER,400,5,400,790,DarkGoldenrod,Silver,BORDER_RAISED,false,Crea);
            Obj.RectangleLabel("Colonna3",CORNER_LEFT_UPPER,795,5,400,790,DarkGoldenrod,Silver,BORDER_RAISED,false,Crea);
            Obj.Button("Aggiungi",CORNER_LEFT_UPPER,375,10,20,20,"-",Black,White,font,false,Crea);
            Obj.RectangleLabel("SfondoGrafico",CORNER_LEFT_UPPER,1200,0,widthscreen-1200,800,Gold,Gold,BORDER_FLAT,false,Crea);
            Obj.Chart("Grafico",Simbolo1,1205,5,widthscreen-1210,395,scale1,true,PERIOD_CURRENT,Crea);
            Obj.Chart("Grafico1",Simbolo2,1205,395,widthscreen-1210,400,scale2,true,PERIOD_CURRENT,Crea);
            //Tabella Mercato//
            Obj.Label("PSI",CORNER_LEFT_UPPER,20,10,"Sector :",DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.Label("PSY",CORNER_LEFT_UPPER,200,10,"Symbol :",DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,40,120,20,Settore1,Black,White,font,fontsize,Settore,false,MaxList,Crea);
            Obj.ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,40,120,20,Simbolo1,Black,White,font,fontsize,simbolo_settore_1,false,MaxList,Crea);
            Obj.Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask :  NA",ForestGreen,font,fontsize,false,Crea);
            Obj.Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread :  NA",Black,font,fontsize,false,Crea);
            Obj.Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid :  NA",FireBrick,font,fontsize,false,Crea);
            Obj.Label("G",CORNER_LEFT_UPPER,15,110,"Daily Return : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_D1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("S",CORNER_LEFT_UPPER,15,160,"Weekly Return : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_W1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("M",CORNER_LEFT_UPPER,15,210,"Monthly Return : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_MN1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("Q",CORNER_LEFT_UPPER,15,260,"Quarterly Return ("+Market.GetCurrentQuarter()+") : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,"NA",Obj.AssegnaColoreRendimento(Market.QuarterReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("A",CORNER_LEFT_UPPER,15,310,"Yearly Return ("+DoubleToString(Market.getYear(),0)+") : ",Black,font,fontsize,false,Crea); 
            Obj.Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,"NA",Obj.AssegnaColoreRendimento(Market.YTDReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("AR",CORNER_LEFT_UPPER,15,360,"Yearly Rolling Return :  ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,"NA",Obj.AssegnaColoreRendimento(Market.YearReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            //Tabella Operativa//
            Obj.Label("RiskProfile",CORNER_LEFT_UPPER,15,400,"Risk Profile : "+RP,DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : NA",Black,font,fontsize,false,Crea);
            Obj.Button("Conservative",CORNER_LEFT_UPPER,15,480,110,50,"Conservative",Black,LightGoldenrod,font,false,Crea);
            Obj.Button("Medium",CORNER_LEFT_UPPER,145,480,110,50,"Medium",Black,Gold,font,false,Crea);
            Obj.Button("Aggressive",CORNER_LEFT_UPPER,280,480,110,50,"Aggressive",Black,DarkGoldenrod,font,false,Crea);
            Obj.Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : 0.00%",Trade.RiskColor(DVRState,Final_Risk,Saldo),font,fontsize,false,Crea);
            Obj.Label("PF",CORNER_LEFT_UPPER,210,545,"Position P&L : 0.0"+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionProfitPerSymbol(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("SeLimite",CORNER_LEFT_UPPER,15,580,"Limit Order Price : ",Black,font,fontsize,false,Crea);
            Obj.Edit("PrezzoLimite",CORNER_LEFT_UPPER,175,580,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
            Obj.Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : NA",Black,font,fontsize,false,Crea);
            Obj.Label("SetSL",CORNER_LEFT_UPPER,15,620,"Stop Loss Price : ",Black,font,fontsize,false,Crea);
            Obj.Edit("SL",CORNER_LEFT_UPPER,175,620,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
            Obj.Label("SetTP",CORNER_LEFT_UPPER,15,660,"Take Profit Price : ",Black,font,fontsize,false,Crea);
            Obj.Edit("TP",CORNER_LEFT_UPPER,175,660,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
            Obj.Button("Compra",CORNER_LEFT_UPPER,15,690,90,50,"Buy",Black,LimeGreen,font,false,Crea);
            Obj.Button("Chiudi Buy",CORNER_LEFT_UPPER,15,740,90,50,"Close Buy",Black,FireBrick,font,false,Crea);
            Obj.Button("Vendi",CORNER_LEFT_UPPER,300,690,90,50,"Sell",Black,LimeGreen,font,false,Crea);
            Obj.Button("Chiudi Sell",CORNER_LEFT_UPPER,300,740,90,50,"Close Sell",Black,FireBrick,font,false,Crea);
            Obj.Button("BreakEven",CORNER_LEFT_UPPER,105,690,195,100,"Break Even",Black,Gold,font,false,Crea);
            //Tabella Mercato 2//
            Obj.Label("PSI2",CORNER_LEFT_UPPER,410,10,"Sector :",DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.Label("PSY2",CORNER_LEFT_UPPER,630,10,"Symbol :",DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,40,120,20,Settore2,Black,White,font,fontsize*1.1,Settore,false,MaxList,Crea);
            Obj.ComboBox("SecondoSimbolo",CORNER_LEFT_UPPER,630,40,120,20,Simbolo2,Black,White,font,fontsize*1.1,simbolo_settore_2,false,MaxList,Crea);
            Obj.Label("Ask2",CORNER_LEFT_UPPER,410,70,"Ask :  NA",ForestGreen,font,fontsize,false,Crea);
            Obj.Label("Spread2",CORNER_LEFT_UPPER,525,70,"Spread :  NA",Black,font,fontsize,false,Crea);
            Obj.Label("Bid2",CORNER_LEFT_UPPER,655,70,"Bid :  NA",FireBrick,font,fontsize,false,Crea);
            Obj.Label("G2",CORNER_LEFT_UPPER,410,110,"Daily Return : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoGiornaliera2",CORNER_LEFT_UPPER,515,110,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo2,PERIOD_D1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("S2",CORNER_LEFT_UPPER,410,160,"Weekly Return : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoSettimanale2",CORNER_LEFT_UPPER,535,160,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo2,PERIOD_W1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("M2",CORNER_LEFT_UPPER,410,210,"Monthly Return : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoMensile2",CORNER_LEFT_UPPER,540,210,"NA",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo2,PERIOD_MN1),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("Q2",CORNER_LEFT_UPPER,410,260,"Quarterly Return ("+Market.GetCurrentQuarter()+") : ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoQuartile2",CORNER_LEFT_UPPER,585,260,"NA",Obj.AssegnaColoreRendimento(Market.QuarterReturn(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("A2",CORNER_LEFT_UPPER,410,310,"Yearly Return ("+DoubleToString(Market.getYear(),0)+") : ",Black,font,fontsize,false,Crea); 
            Obj.Label("AndamentoAnnuale2",CORNER_LEFT_UPPER,580,310,"NA",Obj.AssegnaColoreRendimento(Market.YTDReturn(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("AR2",CORNER_LEFT_UPPER,410,360,"Yearly Rolling Return :  ",Black,font,fontsize,false,Crea);
            Obj.Label("AndamentoAnnualeRolling2",CORNER_LEFT_UPPER,585,360,"NA",Obj.AssegnaColoreRendimento(Market.YearReturn(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Crea);
            //Tabella Operativa 2//
            Obj.Label("RiskProfile2",CORNER_LEFT_UPPER,410,400,"Risk Profile : "+RP2,DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.Label("RiskSU2",CORNER_LEFT_UPPER,410,440,"Setup Risk : NA",Black,font,fontsize,false,Crea);
            Obj.Button("Conservative2",CORNER_LEFT_UPPER,410,480,110,50,"Conservative",Black,LightGoldenrod,font,false,Crea);
            Obj.Button("Medium2",CORNER_LEFT_UPPER,540,480,110,50,"Medium",Black,Gold,font,false,Crea);
            Obj.Button("Aggressive2",CORNER_LEFT_UPPER,675,480,110,50,"Aggressive",Black,DarkGoldenrod,font,false,Crea);
            Obj.Label("Rischio2",CORNER_LEFT_UPPER,410,545,"Risk per Trade : 0.00%",Trade.RiskColor(DVRState,Final_Risk2,Saldo),font,fontsize,false,Crea);
            Obj.Label("PF2",CORNER_LEFT_UPPER,610,545,"Position P&L : 0.0"+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionProfitPerSymbol(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("SeLimite2",CORNER_LEFT_UPPER,410,580,"Limit Order Price : ",Black,font,fontsize,false,Crea);
            Obj.Edit("PrezzoLimite2",CORNER_LEFT_UPPER,570,580,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
            Obj.Label("Tipo2",CORNER_LEFT_UPPER,680,580,"Order Type : NA",Black,font,fontsize,false,Crea);
            Obj.Label("SetSL2",CORNER_LEFT_UPPER,410,620,"Stop Loss Price : ",Black,font,fontsize,false,Crea);
            Obj.Edit("SL2",CORNER_LEFT_UPPER,570,620,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
            Obj.Label("SetTP2",CORNER_LEFT_UPPER,410,660,"Take Profit Price : ",Black,font,fontsize,false,Crea);
            Obj.Edit("TP2",CORNER_LEFT_UPPER,570,660,100,22.5,"",Black,Silver,font,fontsize,false,Crea);
            Obj.Button("Compra2",CORNER_LEFT_UPPER,410,690,90,50,"Buy",Black,LimeGreen,font,false,Crea);
            Obj.Button("Chiudi Buy2",CORNER_LEFT_UPPER,410,740,90,50,"Close Buy",Black,FireBrick,font,false,Crea);
            Obj.Button("Vendi2",CORNER_LEFT_UPPER,695,690,90,50,"Sell",Black,LimeGreen,font,false,Crea);
            Obj.Button("Chiudi Sell2",CORNER_LEFT_UPPER,695,740,90,50,"Close Sell",Black,FireBrick,font,false,Crea);
            Obj.Button("BreakEven2",CORNER_LEFT_UPPER,500,690,195,100,"Break Even",Black,Gold,font,false,Crea);   
            //Tabella Account//
            Obj.Label("Account",CORNER_LEFT_UPPER,810,20,"Account Starting Balance : "+DoubleToString(Saldo,0)+" "+Account.valuta_conto(),DarkGoldenrod,font,fontsize*1.3,false,Crea);
            Obj.Label("PNL",CORNER_LEFT_UPPER,810,70,"Total P&L :  NA",Obj.AssegnaColoreRendimento(AccountInfoDouble(ACCOUNT_EQUITY)-Saldo,ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("PNLToday",CORNER_LEFT_UPPER,980,70,"Postion's P&L :  NA",Obj.AssegnaColoreRendimento(Account.GetPositionsProfit(),ForestGreen,FireBrick),font,fontsize,false,Crea);
            Obj.Label("PerditaGioraliera",CORNER_LEFT_UPPER,810,112.5,"Max Daily Loss :  NA",PGclr,font,fontsize,false,Crea);
            Obj.Label("PerditaMassima",CORNER_LEFT_UPPER,810,155,"Max Total Loss :  NA",PTclr,font,fontsize,false,Crea);
            Obj.Label("ABE",CORNER_LEFT_UPPER,810,197.5,"Automatic Break Even :  NA",Black,font,fontsize,false,Crea);
            Obj.Button("AttivaABE",CORNER_LEFT_UPPER,810,235,180,50,"Activate ABE",Black,Gold,font,false,Crea);
            Obj.Button("DisattivaABE",CORNER_LEFT_UPPER,1000,235,180,50,"Deactivate ABE",Black,Gold,font,false,Crea);
            Obj.Label("DVR",CORNER_LEFT_UPPER,810,295,"Dynamic Variable Risk :  NA",Black,font,fontsize,false,Crea);
            Obj.Button("DVRAttiva",CORNER_LEFT_UPPER,810,330,180,50,"Activate DVR",Black,Gold,font,false,Crea);
            Obj.Button("DVRDisattiva",CORNER_LEFT_UPPER,1000,330,180,50,"Deactivate DVR",Black,Gold,font,false,Crea);
            Obj.Button("TotalClose",CORNER_LEFT_UPPER,1165,10,25,25,"X",Red,White,font,false,Crea);
            //Tabella News//
            int Max_News = 12;
            string currency = Account.ValuteToString(Valuta);
            int coun = news.CurrencyToCountryId(currency);
            int indexes = 0;
            int news_found = 0;
            int yOffset = 60;
            datetime event_time;
            string Prefix = "news";
         
            for(int index = news.GetNextNewsEvent(0, currency, Impo); index >= 0; index = news.GetNextNewsEvent(index + 1, currency,Impo))
              {
               if(news_found >= Max_News)
                  break;
               
               indexes = index;
               event_time = news.event[index].time;
         
               if(event_time >= TimeCurrent() - PeriodSeconds(PERIOD_H1))
                 {
                  string event_name = news.eventname[indexes];
                  string eventtime = TimeToString(event_time + offSet, TIME_DATE | TIME_MINUTES);
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
                     clr = Peru;
                  if(eventimportance == "Alta")
                     clr = FireBrick;
                  
                  Obj.Label(Prefix + "Nomes",CORNER_LEFT_UPPER,810,400,"Upcoming News",DarkGoldenrod,font,fontsize*1.3,false,Crea);
                  Obj.Label(Prefix + "Times",CORNER_LEFT_UPPER,1060,400,"Date and Time",DarkGoldenrod,font,fontsize*1.3,false,Crea);
                  Obj.Label(label_name, CORNER_LEFT_UPPER, 810, yOffset + 380, event_name, Black,font,fontsize*0.9,false,Crea);
                  Obj.Label(label_time, CORNER_LEFT_UPPER, 1075, yOffset + 380, eventtime, clr, font, fontsize*0.9,false,Crea);
                  
                  yOffset += 30;
                  news_found++;
                 }
              }
            }
      }
    else 
       if(Azione == Aggiorna)
         {
          if(!Simbolo2Exist)
            {
            //Sfondo//
            Obj.Label("OraLocale",CORNER_LEFT_UPPER,widthscreen/2.5,800+(heightscreen-800)/2-15,TimeToString(TimeCurrent()+offSet,TIME_DATE|TIME_MINUTES),Black,font,fontsize*1.5,false,Aggiorna);
            //Tabella Mercato//
            Obj.Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask : "+DoubleToString(Market.Ask(Simbolo1),Market.Digit(Simbolo1)),ForestGreen,font,fontsize,false,Aggiorna);
            Obj.Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread : "+DoubleToString(Market.Spread(Simbolo1),Market.Digit(Simbolo1)),Black,font,fontsize,false,Aggiorna);
            Obj.Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid : "+DoubleToString(Market.Bid(Simbolo1),Market.Digit(Simbolo1)),FireBrick,font,fontsize,false,Aggiorna); 
            Obj.Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,DoubleToString(Market.TimeReturn(Simbolo1,PERIOD_D1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_D1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,DoubleToString(Market.TimeReturn(Simbolo1,PERIOD_W1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_W1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,DoubleToString(Market.TimeReturn(Simbolo1,PERIOD_MN1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_MN1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,DoubleToString(Market.QuarterReturn(Simbolo1),2)+"%",Obj.AssegnaColoreRendimento(Market.QuarterReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,DoubleToString(Market.YTDReturn(Simbolo1),2)+"%",Obj.AssegnaColoreRendimento(Market.YTDReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,DoubleToString(Market.YearReturn(Simbolo1),2)+"%",Obj.AssegnaColoreRendimento(Market.YearReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            //Tabella Operativa//
            Obj.Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : "+SR,Black,font,fontsize,false,Aggiorna);
            Obj.Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : "+DoubleToString(Final_Risk,2)+"%",Trade.RiskColor(DVRState,Final_Risk,Saldo),font,fontsize,false,Aggiorna);
            Obj.Label("PF",CORNER_LEFT_UPPER,210,545,"Position P&L : "+Obj.GetSegno(Account.GetPositionProfitPerSymbol(Simbolo1) >= 0)+DoubleToString(Account.GetPositionProfitPerSymbol(Simbolo1),2)+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionProfitPerSymbol(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : "+tipo,Black,font,fontsize,false,Aggiorna);
            //Tabella Account//
            Obj.Label("PNL",CORNER_LEFT_UPPER,410,70,"Total P&L : "+Obj.GetSegno(Saldo_Iniziale <= AccountInfoDouble(ACCOUNT_EQUITY))+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)-Saldo,2)+" "+Account.valuta_conto(),Obj.AssegnaColoreRendimento(AccountInfoDouble(ACCOUNT_EQUITY)-Saldo,ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("PNLToday",CORNER_LEFT_UPPER,590,70,"Postion's P&L : "+Obj.GetSegno(Account.GetPositionsProfit() >= 0)+DoubleToString(Account.GetPositionsProfit(),2)+" "+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionsProfit(),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
            Obj.Label("PerditaGioraliera",CORNER_LEFT_UPPER,410,112.5,"Max Daily Loss : "+PG+" "+Account.valuta_conto(),PGclr,font,fontsize,false,Aggiorna);
            Obj.Label("PerditaMassima",CORNER_LEFT_UPPER,410,155,"Max Total Loss : "+PT+" "+Account.valuta_conto(),PTclr,font,fontsize,false,Aggiorna);
            Obj.Label("ABE",CORNER_LEFT_UPPER,410,197.5,"Automatic Break Even : "+state_ABE,Black,font,fontsize,false,Aggiorna);
            Obj.Label("DVR",CORNER_LEFT_UPPER,410,295,"Dynamic Variable Risk : "+state_DVR,Black,font,fontsize,false,Aggiorna);
            }
          else 
             if(Simbolo2Exist)
               {
               //Sfondo//
               Obj.Label("OraLocale",CORNER_LEFT_UPPER,widthscreen/2.5,800+(heightscreen-800)/2-15,TimeToString(TimeCurrent()+offSet,TIME_DATE|TIME_MINUTES),Black,font,fontsize*1.5,false,Aggiorna);
               //Tabella Mercato//
               Obj.Label("Ask",CORNER_LEFT_UPPER,15,70,"Ask : "+DoubleToString(Market.Ask(Simbolo1),Market.Digit(Simbolo1)),ForestGreen,font,fontsize,false,Aggiorna);
               Obj.Label("Spread",CORNER_LEFT_UPPER,130,70,"Spread : "+DoubleToString(Market.Spread(Simbolo1),Market.Digit(Simbolo1)),Black,font,fontsize,false,Aggiorna);
               Obj.Label("Bid",CORNER_LEFT_UPPER,260,70,"Bid : "+DoubleToString(Market.Bid(Simbolo1),Market.Digit(Simbolo1)),FireBrick,font,fontsize,false,Aggiorna); 
               Obj.Label("AndamentoGiornaliera",CORNER_LEFT_UPPER,120,110,DoubleToString(Market.TimeReturn(Simbolo1,PERIOD_D1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_D1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoSettimanale",CORNER_LEFT_UPPER,140,160,DoubleToString(Market.TimeReturn(Simbolo1,PERIOD_W1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_W1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoMensile",CORNER_LEFT_UPPER,145,210,DoubleToString(Market.TimeReturn(Simbolo1,PERIOD_MN1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo1,PERIOD_MN1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoQuartile",CORNER_LEFT_UPPER,190,260,DoubleToString(Market.QuarterReturn(Simbolo1),2)+"%",Obj.AssegnaColoreRendimento(Market.QuarterReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoAnnuale",CORNER_LEFT_UPPER,185,310,DoubleToString(Market.YTDReturn(Simbolo1),2)+"%",Obj.AssegnaColoreRendimento(Market.YTDReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoAnnualeRolling",CORNER_LEFT_UPPER,190,360,DoubleToString(Market.YearReturn(Simbolo1),2)+"%",Obj.AssegnaColoreRendimento(Market.YearReturn(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               //Tabella Operativa//
               Obj.Label("RiskSU",CORNER_LEFT_UPPER,15,440,"Setup Risk : "+SR,Black,font,fontsize,false,Aggiorna);
               Obj.Label("Rischio",CORNER_LEFT_UPPER,15,545,"Risk per Trade : "+DoubleToString(Final_Risk,2)+"%",Trade.RiskColor(DVRState,Final_Risk,Saldo),font,fontsize,false,Aggiorna);
               Obj.Label("PF",CORNER_LEFT_UPPER,210,545,"Position P&L : "+Obj.GetSegno(Account.GetPositionProfitPerSymbol(Simbolo1) >= 0)+DoubleToString(Account.GetPositionProfitPerSymbol(Simbolo1),2)+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionProfitPerSymbol(Simbolo1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("Tipo",CORNER_LEFT_UPPER,285,580,"Order Type : "+tipo,Black,font,fontsize,false,Aggiorna);
               //Tabella Mercato 2//
               Obj.Label("Ask2",CORNER_LEFT_UPPER,410,70,"Ask : "+DoubleToString(Market.Ask(Simbolo2),Market.Digit(Simbolo2)),ForestGreen,font,fontsize,false,Aggiorna);
               Obj.Label("Spread2",CORNER_LEFT_UPPER,530,70,"Spread : "+DoubleToString(Market.Spread(Simbolo2),Market.Digit(Simbolo2)),Black,font,fontsize,false,Aggiorna);
               Obj.Label("Bid2",CORNER_LEFT_UPPER,660,70,"Bid : "+DoubleToString(Market.Bid(Simbolo2),Market.Digit(Simbolo2)),FireBrick,font,fontsize,false,Aggiorna); 
               Obj.Label("AndamentoGiornaliera2",CORNER_LEFT_UPPER,520,110,DoubleToString(Market.TimeReturn(Simbolo2,PERIOD_D1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo2,PERIOD_D1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoSettimanale2",CORNER_LEFT_UPPER,540,160,DoubleToString(Market.TimeReturn(Simbolo2,PERIOD_W1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo2,PERIOD_W1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoMensile2",CORNER_LEFT_UPPER,545,210,DoubleToString(Market.TimeReturn(Simbolo2,PERIOD_MN1),2)+"%",Obj.AssegnaColoreRendimento(Market.TimeReturn(Simbolo2,PERIOD_MN1),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoQuartile2",CORNER_LEFT_UPPER,590,260,DoubleToString(Market.QuarterReturn(Simbolo2),2)+"%",Obj.AssegnaColoreRendimento(Market.QuarterReturn(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoAnnuale2",CORNER_LEFT_UPPER,585,310,DoubleToString(Market.YTDReturn(Simbolo2),2)+"%",Obj.AssegnaColoreRendimento(Market.YTDReturn(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("AndamentoAnnualeRolling2",CORNER_LEFT_UPPER,590,360,DoubleToString(Market.YearReturn(Simbolo2),2)+"%",Obj.AssegnaColoreRendimento(Market.YearReturn(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               //Tabella Operativa 2//
               Obj.Label("RiskSU2",CORNER_LEFT_UPPER,410,440,"Setup Risk : "+SR2,Black,font,fontsize,false,Aggiorna);
               Obj.Label("Rischio2",CORNER_LEFT_UPPER,410,545,"Risk per Trade : "+DoubleToString(Final_Risk2,2)+"%",Trade.RiskColor(DVRState,Final_Risk2,Saldo),font,fontsize,false,Aggiorna);
               Obj.Label("PF2",CORNER_LEFT_UPPER,610,545,"Position P&L : "+Obj.GetSegno(Account.GetPositionProfitPerSymbol(Simbolo2) >= 0)+DoubleToString(Account.GetPositionProfitPerSymbol(Simbolo2),2)+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionProfitPerSymbol(Simbolo2),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("Tipo2",CORNER_LEFT_UPPER,680,580,"Order Type : "+tipo2,Black,font,fontsize,false,Aggiorna);
               //Tabella Account//
               Obj.Label("PNL",CORNER_LEFT_UPPER,810,70,"Total P&L : "+Obj.GetSegno(Saldo_Iniziale <= AccountInfoDouble(ACCOUNT_EQUITY))+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)-Saldo,2)+" "+Account.valuta_conto(),Obj.AssegnaColoreRendimento(AccountInfoDouble(ACCOUNT_EQUITY)-Saldo,ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("PNLToday",CORNER_LEFT_UPPER,990,70,"Postion's P&L : "+Obj.GetSegno(Account.GetPositionsProfit() >= 0)+DoubleToString(Account.GetPositionsProfit(),2)+" "+Account.valuta_conto(),Obj.AssegnaColoreRendimento(Account.GetPositionsProfit(),ForestGreen,FireBrick),font,fontsize,false,Aggiorna);
               Obj.Label("PerditaGioraliera",CORNER_LEFT_UPPER,810,112.5,"Max Daily Loss : "+PG+" "+Account.valuta_conto(),PGclr,font,fontsize,false,Aggiorna);
               Obj.Label("PerditaMassima",CORNER_LEFT_UPPER,810,155,"Max Total Loss : "+PT+" "+Account.valuta_conto(),PTclr,font,fontsize,false,Aggiorna);
               Obj.Label("ABE",CORNER_LEFT_UPPER,810,197.5,"Automatic Break Even : "+state_ABE,Black,font,fontsize,false,Aggiorna);
               Obj.Label("DVR",CORNER_LEFT_UPPER,810,295,"Dynamic Variable Risk : "+state_DVR,Black,font,fontsize,false,Aggiorna);                
               }
         }
       else  
          if(Azione == Elimina)
            {
             ObjectsDeleteAll(0,-1,-1);
             Obj.Button("TotalOpen",CORNER_LEFT_UPPER,20,20,150,20,"Open Dashboard",Black,Silver,"Bahnschrift Bold",false,Crea);
            }
   }

//+------------------------------------------------------------------+
//| Variables                                                        |
//+------------------------------------------------------------------+

input double Saldo_Iniziale = 100000; // Initial Balance of the Account
input double Perdita_Massima_Giornaliera = 5; // Max Daily Loss Percent
input double Perdita_Massima_Totale = 10; // Max Total Loss Percent
input Stato CO = Attivo;// Close All trades on Max Loss (Daily and Total)
input RT RiskProfile = MR;// Risk Profile for the First Symbol
input RT RiskProfile2 = LR;// Risk Profile for the Second Symbol
input Valute Valuta = USD; // News Currency
input Importanza Impo = Media;// Minum Importance for the News
input int TimeOffSet = -1;// Offset in Hours from the Broker's Time
input int FontUI = 12;// Font Size for User Interface
input string PreferredPairs = "US500.cash, BTCUSD, TSLA, XAUUSD";// Pairs in case the broker didn't add the sector (Make sure the name is correct and to use , as divider)

int scale1 = 1, scale2 = 1, RM, RM2, timezone_offset = TimeOffSet * PeriodSeconds(PERIOD_H1), DVRState = 0, Magicnumber = 322974, MaxList = 20;

static int Limitexist = 0, Limitexist2 = 0, ABE = 1, DVR = 1;

string Settore[] = {"Indexes","Crypto","Metals","Forex","Preferred"}, Indexes[], Crypto[], Forex[], Metals[], Preferred[], simbolo_settore_1[], simbolo_settore_2[];

string PrimoSimbolo = "" , SecondoSimbolo = "", Settore1 = Settore[4], Settore2 = Settore[4], RP, RP2, PG, PT, SR = "Not Selected", SR2 = "Not Selected", tipo = "M", tipo2 = "M", state_ABE = "", state_DVR = "",
       comm = "AIM";

double Risk1, Risk2, saldo_giornaliero = AccountInfoDouble(ACCOUNT_BALANCE), Perdita_Giornaliera = saldo_giornaliero * (Perdita_Massima_Giornaliera/100), Perdita_Totale, TodayLoss, Final_Risk, Final_Risk2, Stop, Price, Take, 
       Stop2, Take2, Price2, Lots, Lots2;

bool BO = false, SO = false, APT = false, APG = false, BO2 = false, SO2 = false, PR = false, Total = false;

color PGclr = Black, PTclr = Black;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
   // Timer //
  
   EventSetTimer(1);
  
   // Symbols //

   Market.getSimboliTerminale(SECTOR_CURRENCY,Forex);
   Market.getSimboliTerminale(SECTOR_INDEXES,Indexes);
   Market.getSimboliTerminale(SECTOR_CURRENCY_CRYPTO,Crypto);
   Market.getSimboliTerminale(SECTOR_COMMODITIES,Metals);
   Market.SplitPreferredPairs(PreferredPairs,Preferred);
   
   AssegnaSimboliPerSettore(Settore1, simbolo_settore_1);
   AssegnaSimboliPerSettore(Settore2, simbolo_settore_2);

   if(PrimoSimbolo == "")  
     {
      PrimoSimbolo = simbolo_settore_1[0];
     }
     
   if(SecondoSimbolo == "")
     {
      SecondoSimbolo = "None";
     }
     
   // News //

   news.update();

   news.GetNextNews("USD",timezone_offset,true,Impo);

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
   
   // Interfaccia //
   
   if(ObjectFind(0,"Sfondo") < 0)         
     {
      Obj.Button("TotalOpen",CORNER_LEFT_UPPER,20,20,150,20,"Open Dashboard",Black,Silver,"Bahnschrift Bold",false,Crea);
     }
   else
     {
     scale1 = 1;
     scale2 = 1;
     }
      
   return(INIT_SUCCEEDED);
  }
    
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+

void OnTimer()
  {
   Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
// Comuni //
   
   // Segno //
   
   Obj.GetSegno(Saldo_Iniziale <= AccountInfoDouble(ACCOUNT_EQUITY));

   Obj.GetSegno(Account.GetPositionsProfit() >= 0);
   
   // PNL e Perdite //     
   
   TodayLoss = Account.GetTodayLoss();
   
   Perdita_Giornaliera = (Account.GetTodayStartingBalance() * (Perdita_Massima_Giornaliera/100)) - TodayLoss;
   
   if(TodayLoss >= Perdita_Giornaliera && APG == false)
     {
      PG = "Reached";
      PGclr = FireBrick;
      SendNotification("Max Daily Loss Reached");
      Alert("Max Daily Loss Reached");
      
      if(CO == Attivo)
        {
         Trade.CloseAllBuy();
         Trade.CloseAllSell(); 
         Alert("All Opened Positions got Closed and you cannot Open more Today");
         SendNotification("All Opened Positions got Closed and you cannot Open more Today");
        }
        
      APG = true;
     }
   else if(TodayLoss < Perdita_Giornaliera)
     {
      PG = DoubleToString(Perdita_Giornaliera,2);
      PGclr = Black;
      APG = false; 
     }
     
   Perdita_Totale = (AccountInfoDouble(ACCOUNT_EQUITY) - Saldo_Iniziale) + (Saldo_Iniziale * (Perdita_Massima_Totale/100));
   
   if(AccountInfoDouble(ACCOUNT_EQUITY) <= Saldo_Iniziale-Perdita_Totale && APT == false)
     {
      PT = "Reached";
      PTclr = FireBrick;
      SendNotification("Max Total Loss Reached");
      Alert("Max Total Loss Reached");
      
      if(CO == Attivo)
           {
            PR = true;
            Trade.CloseAllBuy();
            Trade.CloseAllSell(); 
            Alert("All Opened Positions got Closed and you cannot Open more Today");
            SendNotification("All Opened Positions got Closed and you cannot Open more Today");
           }
      
      APT = true;
     }
   else if(AccountInfoDouble(ACCOUNT_EQUITY) > Saldo_Iniziale-Perdita_Totale)
     {
      PT = DoubleToString(Perdita_Totale,2);  
      PTclr = Black;
      APT = false;
     }
     
   // Stato //
   
   if(ABE == 1)
     {
      state_ABE = "Activated";
      Trade.ABE(PrimoSimbolo,Magicnumber,comm);
      
      if(SecondoSimbolo != "None")
        {
         Trade.ABE(SecondoSimbolo,Magicnumber,comm);
        }
     }  
   else
     {
      state_ABE = "Deactivated";
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
        
   if(Limitexist == 0)
     {
      if(Stop != 0.0)
        {
         if(Stop > Market.Bid(PrimoSimbolo))
           {
            Lots = Trade.CalculateLotSize(PrimoSimbolo, Stop - Market.Bid(PrimoSimbolo), Final_Risk);     
           }
          else 
             if(Stop < Market.Ask(PrimoSimbolo))
               {
                Lots = Trade.CalculateLotSize(PrimoSimbolo, Market.Ask(PrimoSimbolo) - Stop, Final_Risk);          
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
               Lots = Trade.CalculateLotSize(PrimoSimbolo, Stop - Price, Final_Risk);     
              }
             else 
                if(Stop < Price)
                  {
                   Lots = Trade.CalculateLotSize(PrimoSimbolo, Price - Stop, Final_Risk);          
                  } 
           }
         else
           {
            Lots = 0.0;
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
   
   if(Trade.CounterBuyLimit(PrimoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceBuyLimit(PrimoSimbolo,Magicnumber,Price,Stop,comm);
      Trade.SetTakeProfitPriceBuyLimit(PrimoSimbolo,Magicnumber,Price,Take,comm);
     }
     
   if(Trade.CounterSellLimit(PrimoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceSellLimit(PrimoSimbolo,Magicnumber,Price,Stop,comm);
      Trade.SetTakeProfitPriceSellLimit(PrimoSimbolo,Magicnumber,Price,Take,comm);
     }
     
   // TP & SL Ordini Mercato //
   
   if(Trade.CounterBuy(PrimoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceBuy(PrimoSimbolo,Magicnumber,Stop,comm);
      Trade.SetTakeProfitPriceBuy(PrimoSimbolo,Magicnumber,Take,comm);
     }
     
   if(Trade.CounterSell(PrimoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceSell(PrimoSimbolo,Magicnumber,Stop,comm);
      Trade.SetTakeProfitPriceSell(PrimoSimbolo,Magicnumber,Take,comm);
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
       
   if(Limitexist2 == 0)
     {
      if(Stop2 != 0.0)
        {
         if(Stop2 > Market.Bid(SecondoSimbolo))
           {
            Lots2 = Trade.CalculateLotSize(SecondoSimbolo, Stop2 - Market.Bid(SecondoSimbolo), Final_Risk2);     
           }
          else 
             if(Stop2 < Market.Ask(SecondoSimbolo))
               {
                Lots2 = Trade.CalculateLotSize(SecondoSimbolo, Market.Ask(SecondoSimbolo) - Stop2, Final_Risk2);          
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
               Lots2 = Trade.CalculateLotSize(SecondoSimbolo, Stop2 - Price2, Final_Risk2);     
              }
             else 
                if(Stop2 < Price2)
                  {
                   Lots2 = Trade.CalculateLotSize(SecondoSimbolo, Price2 - Stop2, Final_Risk2);          
                  } 
           }
         else
           {
            Lots2 = 0.0;
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
     
   if(Trade.CounterBuyLimit(SecondoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceBuyLimit(SecondoSimbolo,Magicnumber,Price2,Stop2,comm);
      Trade.SetTakeProfitPriceBuyLimit(SecondoSimbolo,Magicnumber,Price2,Take2,comm);
     }
     
   if(Trade.CounterSellLimit(SecondoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceSellLimit(SecondoSimbolo,Magicnumber,Price2,Stop2,comm);
      Trade.SetTakeProfitPriceSellLimit(SecondoSimbolo,Magicnumber,Price2,Take2,comm);
     }
     
   // TP & SL Ordini Mercato //
   
   if(Trade.CounterBuy(SecondoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceBuy(SecondoSimbolo,Magicnumber,Stop2,comm);
      Trade.SetTakeProfitPriceBuy(SecondoSimbolo,Magicnumber,Take2,comm);
     }
     
   if(Trade.CounterSell(SecondoSimbolo,Magicnumber) > 0)
     {
      Trade.SetStopLossPriceSell(SecondoSimbolo,Magicnumber,Stop2,comm);
      Trade.SetTakeProfitPriceSell(SecondoSimbolo,Magicnumber,Take2,comm);
     }
   
// Interfaccia //   
     
   Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
  }

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   long widthscreen = ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   long heightscreen = ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      // Simbolo 1 //
      if(sparam == "TP")
        {
         Take = NormalizeDouble(StringToDouble(ObjectGetString(0,"TP",OBJPROP_TEXT)),Market.Digit(PrimoSimbolo));
        }
      if(sparam == "SL")
        {
         Stop = NormalizeDouble(StringToDouble(ObjectGetString(0,"SL",OBJPROP_TEXT)),Market.Digit(PrimoSimbolo));
        }
      if(sparam == "PrezzoLimite")
        {
         Price = NormalizeDouble(StringToDouble(ObjectGetString(0,"PrezzoLimite",OBJPROP_TEXT)),Market.Digit(PrimoSimbolo));
        }  
        
      // Simbolo 2 //
      if(sparam == "TP2")
        {
         Take2 = NormalizeDouble(StringToDouble(ObjectGetString(0,"TP2",OBJPROP_TEXT)),Market.Digit(SecondoSimbolo));
        }
      if(sparam == "SL2")
        {
         Stop2 = NormalizeDouble(StringToDouble(ObjectGetString(0,"SL2",OBJPROP_TEXT)),Market.Digit(SecondoSimbolo));
        }
      if(sparam == "PrezzoLimite2")
        {
         Price2 = NormalizeDouble(StringToDouble(ObjectGetString(0,"PrezzoLimite2",OBJPROP_TEXT)),Market.Digit(SecondoSimbolo));
        }            
     }   
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      // Comuni //
            
      if(sparam == "TotalOpen")
        {
         Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Crea);
         Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
        }
        
      if(sparam == "TotalClose")
        {
         Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Elimina);
        }

      if(sparam == "Aggiungi")
        {
         if(SecondoSimbolo != "None")
           {
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Elimina);
            SecondoSimbolo = "None";
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Crea);
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
           }
         else 
            if(SecondoSimbolo == "None")
              {
               Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Elimina);
               SecondoSimbolo = simbolo_settore_2[1];
               Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Crea);
               Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
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
     
// Primo Simbolo //
      
      if(sparam == "PrimoSettoreApri")
        {
         if(ObjectFind(0,"PrimoSettoreOpzione1") < 0)
           {
            Obj.ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,40,120,20,Settore1,Black,White,"Bahnschrift Bold",FontUI,Settore,true,MaxList,Aggiorna);
           }
         else
            if(ObjectFind(0,"PrimoSettoreOpzione1") >= 0)
              {
               Obj.ComboBox("PrimoSettore",CORNER_LEFT_UPPER,20,40,120,20,Settore1,Black,White,"Bahnschrift Bold",FontUI,Settore,false,MaxList,Aggiorna);
              }
        }
      

      for(int i = 0; i < ArraySize(Settore); i++)
         {
         if(sparam == "PrimoSettoreOpzione" + IntegerToString(i+1))
            {
            Settore1 = Settore[i];
            AssegnaSimboliPerSettore(Settore1, simbolo_settore_1);
      
            Obj.ComboBox("PrimoSettore", CORNER_LEFT_UPPER, 20, 40, 120, 20,Settore1, Black, White, "Bahnschrift Bold", FontUI,Settore, false, MaxList, Aggiorna);
            break;
            }
         }

      if(sparam == "PrimoSimboloApri")
        {
         if(ObjectFind(0,"PrimoSimboloOpzione1") < 0)
           {
             Obj.ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,40,120,20,PrimoSimbolo,Black,White,"Bahnschrift Bold",FontUI,simbolo_settore_1,true,MaxList,Aggiorna);          
           }
         else
            if(ObjectFind(0,"PrimoSimboloOpzione1") >= 0)
              {
               Obj.ComboBox("PrimoSimbolo",CORNER_LEFT_UPPER,200,40,120,20,PrimoSimbolo,Black,White,"Bahnschrift Bold",FontUI,simbolo_settore_1,false,MaxList,Aggiorna);           
              }
        }   
      
      for(int i = 0; i < ArraySize(simbolo_settore_1);i++)
         {
         if(sparam == "PrimoSimboloOpzione"+DoubleToString(i+1,0))
           {
            PrimoSimbolo = simbolo_settore_1[i];
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Elimina);
            
            if(SecondoSimbolo == "None")
               Obj.Chart("Grafico", PrimoSimbolo, 805, 5, widthscreen - 810, heightscreen-10, scale1, false, PERIOD_CURRENT, Aggiorna);
            else
               Obj.Chart("Grafico", PrimoSimbolo, 1205, 5, widthscreen - 1210, 395, scale1, false, PERIOD_CURRENT, Aggiorna);
            
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Crea);
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
            break;
           }      
         }  
         
      if(sparam == "Conservative")
        {
         Risk1 = 0.25;
         SR = "Conservative";
         Final_Risk = Trade.CalculateDynamicRisk(DVR,Risk1,RM,Saldo_Iniziale,Perdita_Massima_Giornaliera); 
        }
      if(sparam == "Medium")
        {
         Risk1 = 0.50;
         SR = "Medium";
         Final_Risk = Trade.CalculateDynamicRisk(DVR,Risk1,RM,Saldo_Iniziale,Perdita_Massima_Giornaliera); 
        }
      if(sparam == "Aggressive")
        {
         Risk1 = 0.75;
         SR = "Aggressive";
         Final_Risk = Trade.CalculateDynamicRisk(DVR,Risk1,RM,Saldo_Iniziale,Perdita_Massima_Giornaliera); 
        }

      if(sparam == "ZP"+"Grafico")
        {
         if(scale1 < 5)
           {
            scale1 += 1;
           }
      
         if(SecondoSimbolo == "None")
            Obj.Chart("Grafico", PrimoSimbolo, 805, 5, widthscreen - 810, heightscreen-10, scale1, false, PERIOD_CURRENT, Aggiorna);
         else
            Obj.Chart("Grafico", PrimoSimbolo, 1205, 5, widthscreen - 1210, 395, scale1, false, PERIOD_CURRENT, Aggiorna);
        }
      if(sparam == "ZM"+"Grafico")
        {
         if(scale1 > 1)
           {
            scale1 -= 1;
           }
      
         if(SecondoSimbolo == "None")
            Obj.Chart("Grafico", PrimoSimbolo, 805, 5, widthscreen - 810, heightscreen-10, scale1, false, PERIOD_CURRENT, Aggiorna);
         else
            Obj.Chart("Grafico", PrimoSimbolo, 1205, 5, widthscreen - 1210, 395, scale1, false, PERIOD_CURRENT, Aggiorna);
        }

      if(sparam == "Compra" && Lots != 0.0 && Limitexist == 0 && PR == false)
        {
         if(Stop < Market.Ask(PrimoSimbolo) && (Take == 0.0 || Take > Market.Ask(PrimoSimbolo)))
           {
            Trade.SendBuy(Lots,PrimoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceBuy(PrimoSimbolo,Magicnumber,Take,comm);
            Trade.SetStopLossPriceBuy(PrimoSimbolo,Magicnumber,Stop,comm);             
           }
        }
        
      if(sparam == "Vendi"  && Lots != 0.0 && Limitexist == 0 && PR == false)
        {
         if(Stop > Market.Ask(PrimoSimbolo) && (Take == 0.0 || Take < Market.Ask(PrimoSimbolo)))
           {
            Trade.SendSell(Lots,PrimoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceSell(PrimoSimbolo,Magicnumber,Take,comm);
            Trade.SetStopLossPriceSell(PrimoSimbolo,Magicnumber,Stop,comm);  
           }
        }
        
      if(sparam == "Compra" && Lots != 0.0 && Limitexist > 0 && PR == false)
        {
         if(Stop < Price && (Take == 0.0 || Take > Price))
           {
            Trade.SendBuyLimit(Price,Lots,PrimoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceBuyLimit(PrimoSimbolo,Magicnumber,Price,Take,comm);
            Trade.SetStopLossPriceBuyLimit(PrimoSimbolo,Magicnumber,Price,Stop,comm);             
           }
        }
        
      if(sparam == "Vendi"  && Lots != 0.0 && Limitexist > 0 && PR == false)
        {
         if(Stop > Price && (Take == 0.0 || Take < Price))
           {
            Trade.SendSellLimit(Price,Lots,PrimoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceSellLimit(PrimoSimbolo,Magicnumber,Price,Take,comm);
            Trade.SetStopLossPriceSellLimit(PrimoSimbolo,Magicnumber,Price,Stop,comm);  
           }
        }
        
      if(sparam == "Chiudi Buy")
        {
         Trade.CloseBuy(PrimoSimbolo,Magicnumber);
        }
      if(sparam == "Chiudi Sell")
        {
         Trade.CloseSell(PrimoSimbolo,Magicnumber);
        }
        
      if(sparam == "BreakEven")
        {
         Trade.BreakEven(PrimoSimbolo,Magicnumber,comm);
        }   
               
// Secondo Simbolo //
            
      if(sparam == "SecondoSettoreApri")
        {
         if(ObjectFind(0,"SecondoSettoreOpzione1") < 0)
           {
            Obj.ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,40,120,20,Settore2,Black,White,"Bahnschrift Bold",FontUI,Settore,true,MaxList,Aggiorna);
           }
         else
            if(ObjectFind(0,"SecondoSettoreOpzione1") >= 0)
              {
               Obj.ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,40,120,20,Settore2,Black,White,"Bahnschrift Bold",FontUI,Settore,false,MaxList,Aggiorna);
              }
        }
      
      for(int i = 0; i < ArraySize(Settore); i++)
         {
         if(sparam == "SecondoSettoreOpzione" + IntegerToString(i+1))
            {
            Settore2 = Settore[i];
            AssegnaSimboliPerSettore(Settore2, simbolo_settore_2);
      
            Obj.ComboBox("SecondoSettore",CORNER_LEFT_UPPER,410,40,120,20,Settore2,Black,White,"Bahnschrift Bold",FontUI,Settore,false,MaxList,Aggiorna);
            break;
            }
         }


      if(sparam == "SecondoSimboloApri")
        {
         if(ObjectFind(0,"SecondoSimboloOpzione1") < 0)
           {
            Obj.ComboBox("SecondoSimbolo",CORNER_LEFT_UPPER,630,40,120,20,SecondoSimbolo,Black,White,"Bahnschrift Bold",FontUI,simbolo_settore_2,true,MaxList,Aggiorna);           
           }  
         else 
            if(ObjectFind(0,"SecondoSimboloOpzione1") >= 0)
              {
               Obj.ComboBox("SecondoSimbolo",CORNER_LEFT_UPPER,630,40,120,20,SecondoSimbolo,Black,White,"Bahnschrift Bold",FontUI,simbolo_settore_2,false,MaxList,Aggiorna);           
              }
        }   
      
      for(int i = 0; i < ArraySize(simbolo_settore_2);i++)
         {
         if(sparam == "SecondoSimboloOpzione"+DoubleToString(i+1,0))
           {
            SecondoSimbolo = simbolo_settore_2[i];
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Elimina);
            Obj.Chart("Grafico1", SecondoSimbolo, 1205, 395, widthscreen - 1210, 395, scale2, false, PERIOD_CURRENT,Aggiorna);
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Crea);
            Interfaccia(PrimoSimbolo,SecondoSimbolo,Saldo_Iniziale,timezone_offset,Aggiorna);
            break;
           }      
         }  
                  
      if(sparam == "Conservative2")
        {
         Risk2 = 0.25;
         SR2 = "Conservative";
         Final_Risk2 = Trade.CalculateDynamicRisk(DVR,Risk2,RM2,Saldo_Iniziale,Perdita_Massima_Giornaliera);
        }
      if(sparam == "Medium2")
        {
         Risk2 = 0.50;
         SR2 = "Medium";
         Final_Risk2 = Trade.CalculateDynamicRisk(DVR,Risk2,RM2,Saldo_Iniziale,Perdita_Massima_Giornaliera);
        }
      if(sparam == "Aggressive2")
        {
         Risk2 = 0.75;
         SR2 = "Aggressive";
         Final_Risk2 = Trade.CalculateDynamicRisk(DVR,Risk2,RM2,Saldo_Iniziale,Perdita_Massima_Giornaliera);
        }
        
      if(sparam == "ZP"+"Grafico1")
        {
         if(scale2 < 5)
           {
            scale2 += 1;
           }
         Obj.Chart("Grafico1", SecondoSimbolo, 1205, 395, widthscreen - 1210, 395, scale2, false, PERIOD_CURRENT,Aggiorna);
        }
        
      if(sparam == "ZM"+"Grafico1")
        {
         if(scale2 > 1)
           {
            scale2 -= 1;
           }
         Obj.Chart("Grafico1", SecondoSimbolo, 1205, 395, widthscreen - 1210, 395, scale2, false, PERIOD_CURRENT,Aggiorna);
        }
        
      if(sparam == "Compra2" && Lots2 != 0.0 && Limitexist2 == 0 && PR == false)
        {
         if(Stop2 < Market.Ask(SecondoSimbolo) && (Take2 == 0.0 || Take2 > Market.Ask(SecondoSimbolo)))
           {
            Trade.SendBuy(Lots2,SecondoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceBuy(SecondoSimbolo,Magicnumber,Take2,comm);
            Trade.SetStopLossPriceBuy(SecondoSimbolo,Magicnumber,Stop2,comm);             
           }
        }
        
      if(sparam == "Vendi2"  && Lots2 != 0.0 && Limitexist2 == 0 && PR == false)
        {
         if(Stop2 > Market.Ask(SecondoSimbolo) && (Take2 == 0.0 || Take2 < Market.Ask(SecondoSimbolo)))
           {
            Trade.SendSell(Lots2,SecondoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceSell(SecondoSimbolo,Magicnumber,Take2,comm);
            Trade.SetStopLossPriceSell(SecondoSimbolo,Magicnumber,Stop2,comm);  
           }
        }
        
      if(sparam == "Compra2" && Lots2 != 0.0 && Limitexist2 > 0 && PR == false)
        {
         if(Stop2 < Price2 && (Take2 == 0.0 || Take2 > Price2))
           {
            Trade.SendBuyLimit(Price2,Lots2,SecondoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceBuyLimit(SecondoSimbolo,Magicnumber,Price2,Take2,comm);
            Trade.SetStopLossPriceBuyLimit(SecondoSimbolo,Magicnumber,Price2,Stop2,comm);             
           }
        }
        
      if(sparam == "Vendi2"  && Lots2 != 0.0 && Limitexist2 > 0 && PR == false)
        {
         if(Stop2 > Price2 && (Take2 == 0.0 || Take2 < Price2))
           {
            Trade.SendSellLimit(Price2,Lots2,SecondoSimbolo,comm,Magicnumber);
            Trade.SetTakeProfitPriceSellLimit(SecondoSimbolo,Magicnumber,Price2,Take2,comm);
            Trade.SetStopLossPriceSellLimit(SecondoSimbolo,Magicnumber,Price2,Stop2,comm);  
           }
        }
        
      if(sparam == "Chiudi Buy2")
        {
         Trade.CloseBuy(SecondoSimbolo,Magicnumber);
        }
        
      if(sparam == "Chiudi Sell2")
        {
         Trade.CloseSell(SecondoSimbolo,Magicnumber);
        }
        
      if(sparam == "BreakEven2")
        {
         Trade.BreakEven(SecondoSimbolo,Magicnumber,comm);
        }  
     }
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {
   if(reason == 9 || reason == 0 || reason == 5 || reason == 4 || reason == 8 || reason == 6 || reason == 1 || reason == 2)
     {
      EventKillTimer();
      ObjectsDeleteAll(0,-1,-1);
     }   
  }

//+------------------------------------------------------------------+
