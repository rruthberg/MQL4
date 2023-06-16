//+------------------------------------------------------------------+
//|                                                        Simple.mqh |
//|                                                 Richard Ruthberg |
//+------------------------------------------------------------------+

#property copyright   "Richard Ruthberg"
#property description "Simple expert advisor test"
#property strict


// Include and objects
#include <Custom/OrderHandler.mqh>
#include <Custom/HelperFunctions.mqh>



// Input variables
input int MagicNumber = 101;
input int Slippage = 10;

input double LotSize = 0.1;
input int StopLoss = 0;
input int TakeProfit = 0;

input int MaPeriod = 5;
input ENUM_MA_METHOD MaMethod = MODE_EMA;
input ENUM_APPLIED_PRICE MaPrice = PRICE_CLOSE;

OrderHandler trade = OrderHandler();


// OnInit() event handler
int OnInit()
{
   // Set magic number
   trade.setMagicNumber(MagicNumber);
   trade.setSlippage(Slippage);
   
   return(INIT_SUCCEEDED);
}


// OnTick() event handler
void OnTick()
{

   // Moving average and close price from last bar
   double ma = iMA(_Symbol,_Period,MaPeriod,0,MaMethod,MaPrice,1);
   double close = Close[1];
   
   
   // Buy order condition
   if(close > ma)
   {
      trade.goLong(_Symbol,LotSize, StopLoss, TakeProfit);
   }
   
   
   // Sell order condition
   if(close < ma )
   {
      trade.goShort(_Symbol,LotSize, StopLoss, TakeProfit);
   }
   
}