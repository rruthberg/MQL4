//+------------------------------------------------------------------+
//|                                                  Bollinger.mqh |
//|                                                 Richard Ruthberg |
//+------------------------------------------------------------------+

#property copyright   "Richard Ruthberg"
#property description "Bollinger Band Trader"
#property strict


//+------------------------------------------------------------------+
//| Includes and object initialization                               |
//+------------------------------------------------------------------+

#include <Custom/OrderHandler.mqh>


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input int MagicNumber = 101;
input int Slippage = 10;
input double LotSize = 0.1;
input int StopLoss = 0;
input int TakeProfit = 0;

input int MaPeriod = 10;
input double BandStdDev = 1.56;

//+------------------------------------------------------------------+
//| Global variable and indicators                                   |
//+------------------------------------------------------------------+

OrderHandler trade = OrderHandler();


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   trade.setMagicNumber(MagicNumber);
   trade.setSlippage(Slippage);
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
    int bShift = 0;
    int iShift = 0;

    double main = iBands(_Symbol, _Period, MaPeriod, BandStdDev, bShift, PRICE_CLOSE, MODE_MAIN, iShift);
    double upper = iBands(_Symbol, _Period, MaPeriod, BandStdDev, bShift, PRICE_CLOSE, MODE_UPPER, iShift);
    double lower = iBands(_Symbol, _Period, MaPeriod, BandStdDev, bShift, PRICE_CLOSE, MODE_LOWER, iShift);


    double lastClose = Close[iShift];
    double prevClose = Close[iShift+1];
   
    bool lowerCrossFromBelow = lastClose > lower && ( prevClose < lower && prevClose < lastClose );
    bool upperCrossFromAbove = lastClose < upper && ( prevClose > upper && prevClose > lastClose );

    bool mainCrossFromBelow = prevClose < main && lastClose > main;
    bool mainCrossFromAbove = prevClose > main && lastClose < main;

    bool lowerCrossFromAbove = lastClose < lower && ( prevClose > lower && prevClose > lastClose );
    bool upperCrossFromBelow = lastClose > upper && ( prevClose < upper && prevClose < lastClose );

   
   if(  lowerCrossFromBelow ){ //LONG condition
      trade.goLong(_Symbol,LotSize, StopLoss, TakeProfit);
   } else if( upperCrossFromAbove ){ //SHORT condition
      trade.goShort(_Symbol,LotSize, StopLoss, TakeProfit);
   } else if( mainCrossFromBelow && trade.isLong() ){ //SET Stop loss when main cross
      trade.setLongStopLossAndProfit(main, 0, true);
   } else if( mainCrossFromAbove && trade.isShort() ){ //SET Stop loss when main cross
      trade.setShortStopLossAndProfit(main, 0, true);
   } else if (lowerCrossFromAbove && trade.isShort() ){ //SHORT take profit condition
      trade.setShortStopLossAndProfit(lower, 0, true);
   } else if( upperCrossFromBelow && trade.isLong() ){ //LONG take profit condition{
      trade.setLongStopLossAndProfit(upper, 0, true);
   }
 
}