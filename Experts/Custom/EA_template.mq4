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

#include <Custom/OrderHandler.mqh>>
#include <Custom/OrderHandler.mqh>>
#include <Custom/HelperFunctions.mqh>
OrderHandler trade;
OrderCounter count;


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

sinput string TradeSettings;    	// Trade Settings
input int MagicNumber = 101;
input int Slippage = 10;
input double FixedLotSize = 0.1;


//+------------------------------------------------------------------+
//| Global variable and indicators                                   |
//+------------------------------------------------------------------+

int gBuyTicket, gSellTicket;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   // Set magic number
   trade.setMagicNumber(MagicNumber);
   trade.setSlippage(Slippage);
   
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   // Trading
   if(tradeEnabled == true)
   {
	   bool tradeEnabled = true;
      double lotSize = FixedLotSize;
      
      // Open buy order
      if(  )
      {
         gBuyTicket = trade.openBuyOrder(_Symbol,lotSize);
         trade.setOrderStopAndProfit(gBuyTicket,StopLoss,TakeProfit);
      }
      
      // Open sell order
      else if(  )
      {
         gSellTicket = trade.openSellOrder(_Symbol,lotSize);
         trade.setOrderStopAndProfit(gSellTicket,StopLoss,TakeProfit);
      }
   }   
 
}