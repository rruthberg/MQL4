//+------------------------------------------------------------------+
//|                                                  EA_template.mqh |
//|                                                 Richard Ruthberg |
//+------------------------------------------------------------------+

#property copyright   "Richard Ruthberg"
#property description "Expert advisor template"
#property strict


//+------------------------------------------------------------------+
//| Includes and object initialization                               |
//+------------------------------------------------------------------+

#include <Custom/OrderHandler.mqh>
#include <Custom/HelperFunctions.mqh>


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input int MagicNumber = 101;
input int Slippage = 10;
input double LotSize = 0.1;
input int StopLoss = 0;
input int TakeProfit = 0;

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
   // LONG
   if(  )
   {
      trade.goLong(_Symbol,LotSize, StopLoss, TakeProfit);
    }
     
   // SHORT
   else if(  )
   {
      trade.goShort(_Symbol,LotSize, StopLoss, TakeProfit);
   } 
 
}