//+------------------------------------------------------------------+
//|                                                     CObjects.mqh |
//|                                                   Moreo Riccardo |
//|                             https://www.mql5.com/it/users/moreor |
//+------------------------------------------------------------------+
#property copyright "Moreo Riccardo"

 class CObjects
  {
public:
   CObjects(void) {}
   ~CObjects(void) {}

   enum azione
     {
      Crea = 0,
      Aggiorna = 1,
      Elimina = 2,
     };
      
   void Label(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, string Text, color Color, string Font, double Size, bool Hidden, int Azione)
     {
      if(Azione == 0 && ObjectFind(0,Name) < 0)
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
         ObjectSetInteger(0,Name,OBJPROP_HIDDEN,Hidden);
        }
      else 
         if(Azione == 1 && ObjectFind(0,Name) >= 0)
           {
            ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
            ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
            ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
            ObjectSetString(0, Name, OBJPROP_TEXT, Text);
            ObjectSetString(0, Name, OBJPROP_FONT, Font);
            ObjectSetInteger(0, Name, OBJPROP_FONTSIZE, long(Size));
            ObjectSetInteger(0, Name, OBJPROP_COLOR, Color);
            ObjectSetInteger(0,Name,OBJPROP_HIDDEN,Hidden);
           }
         else
            if(Azione == 2 && ObjectFind(0,Name) >= 0)
              {
               ObjectDelete(0,Name);
              }
     }
   
   void Edit(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, string Text, color Color, color BackColor, string Font, double Size, bool Hidden, int Azione)
     {
      if(Azione == 0 && ObjectFind(0,Name) < 0)
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
         ObjectSetInteger(0, Name, OBJPROP_BGCOLOR, BackColor);
         ObjectSetInteger(0, Name, OBJPROP_READONLY, false);
         ObjectSetInteger(0,Name, OBJPROP_ZORDER, 0);
         ObjectSetInteger(0,Name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,Name,OBJPROP_SELECTED,false);
         ObjectSetInteger(0,Name,OBJPROP_HIDDEN,Hidden);
        }
      else 
         if(Azione == 1 && ObjectFind(0,Name) >= 0)
           {
            ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
            ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
            ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
            ObjectSetInteger(0, Name, OBJPROP_XSIZE, long(Size_X));
            ObjectSetInteger(0, Name, OBJPROP_YSIZE, long(Size_Y));
            ObjectSetString(0, Name, OBJPROP_TEXT, Text);
            ObjectSetString(0, Name, OBJPROP_FONT, Font);
            ObjectSetInteger(0, Name, OBJPROP_FONTSIZE, long(Size));
            ObjectSetInteger(0, Name, OBJPROP_COLOR, Color);
            ObjectSetInteger(0, Name, OBJPROP_BGCOLOR, BackColor);
            ObjectSetInteger(0,Name,OBJPROP_HIDDEN,Hidden);        
           }  
         else
            if(Azione == 2 && ObjectFind(0,Name) >= 0)
              {
               ObjectDelete(0,Name);
              } 
     }
   
   void Button(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, string Text, color Color, color BackGround_Color, string Font, bool Hidden, int Azione)
     {
      if(Azione == 0 && ObjectFind(0,Name) < 0)
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
         ObjectSetInteger(0, Name,OBJPROP_HIDDEN,Hidden);
         ObjectSetInteger(0, Name,OBJPROP_STATE,false);   
        }
      else 
         if(Azione == 1 && ObjectFind(0,Name) >= 0)
           {
            ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
            ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
            ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
            ObjectSetInteger(0, Name, OBJPROP_XSIZE, long(Size_X));
            ObjectSetInteger(0, Name, OBJPROP_YSIZE, long(Size_Y));
            ObjectSetInteger(0, Name, OBJPROP_BGCOLOR, BackGround_Color);
            ObjectSetInteger(0, Name, OBJPROP_BORDER_COLOR, Color);
            ObjectSetInteger(0, Name, OBJPROP_COLOR, Color);
            ObjectSetString(0, Name, OBJPROP_TEXT, Text);
            ObjectSetString(0, Name, OBJPROP_FONT, Font);
            ObjectSetInteger(0, Name,OBJPROP_HIDDEN,Hidden);
           }
         else
            if(Azione == 2 && ObjectFind(0,Name) >= 0)
              {
               ObjectDelete(0,Name);
              }
     }
   
   void RectangleLabel(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, color Border_Color, color BackGround_Color, ENUM_BORDER_TYPE Border_Type, bool Hidden, int Azione)
     {
      if(Azione == 0 && ObjectFind(0,Name) < 0)
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
         ObjectSetInteger(0,Name,OBJPROP_HIDDEN,Hidden);   
        }
      else 
         if(Azione == 1 && ObjectFind(0,Name) >= 0)
           {
            ObjectSetInteger(0, Name, OBJPROP_CORNER, Corner);
            ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, long(Distance_X));
            ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, long(Distance_Y));
            ObjectSetInteger(0, Name, OBJPROP_XSIZE, long(Size_X));
            ObjectSetInteger(0, Name, OBJPROP_YSIZE, long(Size_Y));
            ObjectSetInteger(0, Name, OBJPROP_BGCOLOR, BackGround_Color);
            ObjectSetInteger(0, Name, OBJPROP_BORDER_COLOR, Border_Color);
            ObjectSetInteger(0, Name, OBJPROP_BORDER_TYPE, Border_Type);
            ObjectSetInteger(0,Name,OBJPROP_HIDDEN,Hidden);            
           }
         else
            if(Azione == 2 && ObjectFind(0,Name) >= 0)
              {
               ObjectDelete(0,Name);
              }  
     }
   
   void Chart(string Name, string Simbol, double Distance_X, double Distance_Y, double Size_X, double Size_Y, int Scale, bool Hidden, ENUM_TIMEFRAMES Periodo, int Azione)
     {
      if(Azione == 0 && ObjectFind(0,"ZM"+Name) < 0)
        {
         ObjectCreate(0, Name, OBJ_CHART, 0, TimeCurrent(), 0);
         ObjectSetString(0, Name, OBJPROP_SYMBOL, Simbol);
         ObjectSetInteger(0, Name, OBJPROP_PERIOD, Periodo);
         ObjectSetInteger(0, Name, OBJPROP_CHART_SCALE, Scale);
         ObjectSetInteger(0, Name, OBJPROP_DATE_SCALE, true);
         ObjectSetInteger(0, Name, OBJPROP_PRICE_SCALE, true);
         ObjectSetInteger(0, Name, OBJPROP_XDISTANCE, (int)(Distance_X));
         ObjectSetInteger(0, Name, OBJPROP_YDISTANCE, (int)(Distance_Y));
         ObjectSetInteger(0, Name, OBJPROP_XSIZE, (int)Size_X);
         ObjectSetInteger(0, Name, OBJPROP_YSIZE, (int)Size_Y);
         ObjectSetInteger(0, Name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, Name, OBJPROP_SELECTED, false);
         ObjectSetInteger(0, Name, OBJPROP_HIDDEN, Hidden);
   
         long subChartID = ObjectGetInteger(0, Name, OBJPROP_CHART_ID);
         if(subChartID > 0)
           {
            ChartApplyTemplate(subChartID, "tester.tpl");
            ChartRedraw(subChartID);
           }
         string font = "Bahnschrift Bold";
         Button("ZP" + Name, CORNER_LEFT_UPPER, Distance_X + 10, Distance_Y + 20, 30, 30, "+", Black, White, font,false,0);
         Button("ZM" + Name, CORNER_LEFT_UPPER, Distance_X + 45, Distance_Y + 20, 30, 30, "-", Black, White, font,false,0);
        }
      else
         if(Azione == 1 && ObjectFind(0,"ZM"+Name) >= 0)
           {
            ObjectSetInteger(0, Name, OBJPROP_CHART_SCALE, Scale);
            ObjectSetInteger(0, Name, OBJPROP_PERIOD, Periodo);
            long subChartID = ObjectGetInteger(0, Name, OBJPROP_CHART_ID);
            if(subChartID > 0)
              {
               ChartRedraw(subChartID);
              }
           }
         else
            if(Azione == 2  && ObjectFind(0,"ZM"+Name) >= 0)
              {
               ObjectDelete(0,Name);
               ObjectDelete(0,"ZP"+Name);
               ObjectDelete(0,"ZM"+Name);
              }
     }
   
   void ComboBox(string Name, ENUM_BASE_CORNER Corner, double Distance_X, double Distance_Y, double Size_X, double Size_Y, string Text, color Color, color BackGround_Color, string Font, double FontSize, string& elenco[], bool OpenList, int MaxElements, int Azione)
     {
      int size = ArraySize(elenco);
      if(ArraySize(elenco) >= MaxElements)
         size = MaxElements;
   
      if(Azione == 0  && ObjectFind(0,Name+"Testo") < 0)
        {
         Button(Name+"Apri",Corner,Distance_X+Size_X,Distance_Y,Size_Y,Size_Y,"«",Color,BackGround_Color,Font,false,0);
         RectangleLabel(Name+"Base",Corner,Distance_X,Distance_Y,Size_X,Size_Y,Color,BackGround_Color,BORDER_FLAT,false,0);
         Label(Name+"Testo",Corner,Distance_X+10,Distance_Y,Text,Color,Font,FontSize,false,0);
        }
      else 
         if(Azione == 1 && OpenList && ObjectFind(0,Name+"Apri") >= 0)
           {      
            for(int i = 0;i < size;i++)
               {
                Button(Name+"Opzione"+IntegerToString(i+1),CORNER_LEFT_UPPER,Distance_X,Distance_Y+(Size_Y*(i+1)),Size_X,Size_Y,elenco[i],Color,BackGround_Color,Font,false,0);
               }
            Button(Name+"Apri",Corner,Distance_X+Size_X,Distance_Y,Size_Y,Size_Y,"»",Color,BackGround_Color,Font,false,1);
            Label(Name+"Testo",Corner,Distance_X+10,Distance_Y,Text,Color,Font,FontSize,false,1);
           }
         else
            if(Azione == 1 && !OpenList && ObjectFind(0,Name+"Apri") >= 0)
              {
               for(int i = 0;i < size;i++)
                  {
                   ObjectDelete(0,Name+"Opzione"+IntegerToString(i+1));
                  }
               Button(Name+"Apri",Corner,Distance_X+Size_X,Distance_Y,Size_Y,Size_Y,"«",Color,BackGround_Color,Font,false,1);
               Label(Name+"Testo",Corner,Distance_X+10,Distance_Y,Text,Color,Font,FontSize,false,1);
              }
            else
               if(Azione == 2 && ObjectFind(0,Name+"Apri") >= 0)
                 {
                  ObjectDelete(0,Name);
                  ObjectDelete(0,Name+"Base");
                  ObjectDelete(0,Name+"Testo");
                  for(int i = 0;i < size;i++)
                     {
                      ObjectDelete(0,Name+"Opzione"+IntegerToString(i+1));
                     }
                  ObjectDelete(0,Name+"Apri");
                 }
     }
   
   color AssegnaColoreRendimento(double rendimento, color positive,color negative)
     {
      return rendimento >= 0 ? positive : negative;
     }
     
   string GetSegno(bool condizione)
     {
      if(condizione)
        return "+";
      else
        return "";  
     }
  };
