//+------------------------------------------------------------------+
//|                                                 OrderHandler.mqh |
//|                                                 Richard Ruthberg |
//+------------------------------------------------------------------+

#property copyright   "Richard Ruthberg"
#property description "Trading operations class"
#property strict

#include <stdlib.mqh>
#include <Custom/OrderCounter.mqh>
#include <Custom/HelperFunctions.mqh>

#define MAX_RETRIES 3		// Max retries on error
#define RETRY_DELAY 3000	// Retry delay in ms


//+------------------------------------------------------------------+
//| Order handler class - use for managing orders in MT4             |
//+------------------------------------------------------------------+

class OrderHandler
{
   private:
      static int _magicNumber;
      static int _slippage;
      static OrderCounter _counter;
      static bool _uniDirectional;
      static bool _singleOrderPerDirection;
      static ticket_tracker _tickets;

      double getOrderPrice(int pType, string pSymbol, bool isClose = false);
      bool isNoActiveOrdersForType(int pType);
      bool selectOrder(int pTicket);
      
      int openMarketOrder(string pSymbol, int pType, double pVolume, string pComment, color pArrow);
      bool closeMarketOrders(CLOSE_MARKET_TYPE pCloseType);


      

   
   public:
      int openBuyOrder(string pSymbol, double pVolume, string pComment = "Buy order", color pArrow = clrGreen);
      int openSellOrder(string pSymbol, double pVolume, string pComment = "Sell order", color pArrow = clrRed);

      void setShortStopLossAndProfit(double pStopLoss = 0, double pTakeProfit = 0, bool absolute = false);
      void setLongStopLossAndProfit(double pStopLoss = 0, double pTakeProfit = 0, bool absolute = false);
      
      bool closeMarketOrder(int pTicket, double pVolume = 0, color pArrow = clrRed);
      bool closeAllBuyOrders();
      bool closeAllSellOrders();
      bool closeAllMarketOrders();

	   bool modifyOrder(int pTicket, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, color pArrow = clrOrange);
      bool setOrderStopAndProfit(int pTicket, double pStopPoints, double pProfitPoints = 0, int pMinPoints = 10, bool absoluteLevel = false);

      static void setMagicNumber(int pMagic);
      static int getMagicNumber();

      void goLong(string pSymbol, double pLotSize, double pStopLoss = 0, double pTakeProfit = 0);
      void goShort(string pSymbol, double pLotSize, double pStopLoss = 0, double pTakeProfit = 0); 
      
      static void setSlippage(int pSlippage);    

      int positionDirection();
      bool isLong();
      bool isShort();


};

int OrderHandler::_magicNumber = 0;
int OrderHandler::_slippage = 10;
bool OrderHandler::_uniDirectional = true;
bool OrderHandler::_singleOrderPerDirection = true;
OrderCounter OrderHandler::_counter = OrderCounter();
ticket_tracker OrderHandler::_tickets = {0,0};


//+------------------------------------------------------------------+
//| Market order functions                                           |
//+------------------------------------------------------------------+

int OrderHandler::openMarketOrder(string pSymbol, int pType, double pVolume, string pComment, color pArrow)
{
	int retryCount = 0;
	int ticket = 0;
	int errorCode = 0;
	
	double orderPrice = 0;
	
	string orderType = OrderTypeToString(pType);
	string errDesc;
	
	// Retry order sending with new prices until max tries reached
	while(retryCount <= MAX_RETRIES) 
	{
		WaitForReadyContext();
		
      orderPrice = getOrderPrice(pType,pSymbol);

		// Place market order
      if( isNoActiveOrdersForType(pType) ){
         ticket = OrderSend(pSymbol,pType,pVolume,orderPrice,_slippage,0,0,pComment,_magicNumber,0,pArrow);

         // Error handling
         if(ticket == -1)
         {
            // Order error
            errorCode = GetLastError();
            errDesc = ErrorDescription(errorCode);
            
            // Retry check
            if( UnrecovableError(errorCode) )
            {
               Alert("Open ",orderType," order: Error ",errorCode," - ",errDesc);
               Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
               break;
            }
            else
            {
               retryCount++;
               if(retryCount > MAX_RETRIES)
               {
                  // Max tries reached
                  Alert("Open ",orderType," order: Max retries exceeded. Error ",errorCode," - ",errDesc);
                  Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
               } else {
                  Print("Server error detected, retrying...");
                  Sleep(RETRY_DELAY);
               }
            }
         } else
         {
            // Order successful
            Comment(orderType," order #",ticket," opened on ",pSymbol);
            Print(orderType," order #",ticket," opened on ",pSymbol);
            break;
         } 
      }
		
		
   }
   
   
   
   return(ticket);
}  


int OrderHandler::openBuyOrder(string pSymbol,double pVolume,string pComment="Buy order",color pArrow=32768)
{
   if(_uniDirectional)
      closeAllSellOrders();

   int ticket = openMarketOrder(pSymbol, OP_BUY, pVolume, pComment, pArrow);
   return(ticket);
}


int OrderHandler::openSellOrder(string pSymbol,double pVolume,string pComment="Sell order",color pArrow=255)
{
   if(_uniDirectional)
      closeAllBuyOrders();

   int ticket = openMarketOrder(pSymbol, OP_SELL, pVolume, pComment, pArrow);
   return(ticket);
}

void OrderHandler::goLong( string pSymbol, double pLotSize, double pStopLoss = 0, double pTakeProfit = 0 ){
   if( (_singleOrderPerDirection && _tickets.buy == 0) || !_singleOrderPerDirection)
   {
      
      _tickets.buy = openBuyOrder(pSymbol,pLotSize);
      _tickets.sell = 0;
      setLongStopLossAndProfit(pStopLoss,pTakeProfit);
   }
}

void OrderHandler::goShort( string pSymbol, double pLotSize, double pStopLoss = 0, double pTakeProfit = 0 ){
   if( (_singleOrderPerDirection && _tickets.sell == 0) || !_singleOrderPerDirection)
   {
      _tickets.buy = 0;
      _tickets.sell = openSellOrder(pSymbol,pLotSize);
      setShortStopLossAndProfit(pStopLoss,pTakeProfit);
   }
}

void OrderHandler::setShortStopLossAndProfit(double pStopLoss = 0, double pTakeProfit = 0, bool absolute = false){
   if(pStopLoss != 0 || pTakeProfit != 0)
         setOrderStopAndProfit(_tickets.sell,pStopLoss,pTakeProfit, absolute);

}

void OrderHandler::setLongStopLossAndProfit(double pStopLoss = 0, double pTakeProfit = 0, bool absolute = false){
   if(pStopLoss != 0 || pTakeProfit != 0)
         setOrderStopAndProfit(_tickets.buy,pStopLoss,pTakeProfit, absolute);
         
}



//+------------------------------------------------------------------+
//| Close market orders                                              |
//+------------------------------------------------------------------+

bool OrderHandler::closeMarketOrder(int pTicket,double pVolume=0.000000,color pArrow=255)
{
   int retryCount = 0;
   int errorCode = 0;
   
   double closePrice = 0;
   double closeVolume = 0;
   
   bool isOrderClosed = false;
   string errDesc;

   bool isOrderSelected = selectOrder(pTicket);
   
   // Close entire order if pVolume not specified, or if pVolume is greater than order volume
   closeVolume = pVolume == 0 || pVolume > OrderLots() ? OrderLots() : pVolume;
   
   // Try close order with new price until max tries reached
	while(retryCount <= MAX_RETRIES && isOrderSelected)    
	{
      WaitForReadyContext();
      closePrice = getOrderPrice( OrderType(), OrderSymbol(), true);
      isOrderClosed = OrderClose(pTicket,closeVolume,closePrice,_slippage,pArrow);
      
      if( isOrderClosed )
      {
         // Order successfully closed
   	   Comment("Order #",pTicket," closed");
   	   Print("Order #",pTicket," closed");
   	   break;
      } else
   	{
         errorCode = GetLastError();
         errDesc = ErrorDescription(errorCode);
      	
      	if( UnrecovableError(errorCode) )
   		{
   			Alert("Close order #",pTicket,": Error ",errorCode," - ",errDesc);
   			Print("Price: ",closePrice,", Volume: ",closeVolume);
   			break;
   		} else
   		{
            retryCount++;
            if(retryCount > MAX_RETRIES){
               Alert("Close order #",pTicket,": Max retries exceeded. Error ",errorCode," - ",errDesc);
               Print("Price: ",closePrice,", Volume: ",closeVolume);
            } else 
            {
               Print("Server error detected, retrying...");
   			   Sleep(RETRY_DELAY);
            }
   		}
   	} 
   }
   
   
	
	return(isOrderClosed);
}

bool OrderHandler::closeMarketOrders(CLOSE_MARKET_TYPE pCloseType)
{
   bool error = false;
   bool closeOrder = false;
   
   // Loop through open order pool from oldest to newest
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      bool isOrderSelected = OrderSelect(order,SELECT_BY_POS);

      if(isOrderSelected){
         int orderType = OrderType();
         int orderMagicNumber = OrderMagicNumber();
         int orderTicket = OrderTicket();
         double orderVolume = OrderLots();
         
         // Determine if order type matches pCloseType
         if( (pCloseType == CLOSE_ALL_MARKET && (orderType == OP_BUY || orderType == OP_SELL)) 
            || (pCloseType == CLOSE_BUY && orderType == OP_BUY) 
            || (pCloseType == CLOSE_SELL && orderType == OP_SELL) )
         {
            closeOrder = true;
         }
         else closeOrder = false;
         
         // Close order if pCloseType and magic number match currently selected order
         if(closeOrder == true && orderMagicNumber == _magicNumber)
         {
            bool isClosed = closeMarketOrder(orderTicket,orderVolume);
            if( !isClosed )
            {
               Print("Close multiple orders: ",OrderTypeToString(orderType)," #",orderTicket," not closed");
               error = true;
            }
            else order--;
         }
      }
      
   }
   
   return(error);
}


bool OrderHandler::closeAllBuyOrders(void)
{
   bool result = closeMarketOrders(CLOSE_BUY);
   return(result);
}


bool OrderHandler::closeAllSellOrders(void)
{
   bool result = closeMarketOrders(CLOSE_SELL);
   return(result);
}


bool OrderHandler::closeAllMarketOrders(void)
{
   bool result = closeMarketOrders(CLOSE_ALL_MARKET);
   return(result);
}

//+------------------------------------------------------------------+
//| Modify orders                                                    |
//+------------------------------------------------------------------+

bool OrderHandler::modifyOrder(int pTicket, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, color pArrow = clrOrange)
{
   int retryCount = 0;
   int errorCode = 0;
   
	bool isOrderModified = false;
	
	string errDesc;
	
	while(retryCount <= MAX_RETRIES)
	{
		WaitForReadyContext();
		
		isOrderModified = OrderModify(pTicket, pPrice, pStop, pProfit, pExpiration, pArrow);
		errorCode = GetLastError();
		errDesc = ErrorDescription(errorCode);
		
		// Error handling - Ignore error code 1
		if( !isOrderModified && errorCode != ERR_NO_RESULT)
		{
			if( UnrecovableError(errorCode) )
			{
				Alert("Modify order #",pTicket,": Error ",errorCode," - ", errDesc);
				Print("Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
				break;
			} else
			{
            // Retry on error
            retryCount++;
            if(retryCount > MAX_RETRIES)
            {
               Alert("Modify order #",pTicket,": Max retries exceeded. Error ",errorCode," - ",errDesc);
               Print("Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
            } else 
            {
               Print("Server error detected, retrying...");
               Sleep(RETRY_DELAY);
            }

			}
		} else
		{
         Comment("Order #",pTicket," modified");
         Print("Order #",pTicket," modified");
         break;
		} 
   }
   
   

	return(isOrderModified);
}


// Modify order stop loss and take profit by point values or absolue if set to true
bool OrderHandler::setOrderStopAndProfit(int pTicket, double pStopPoints, double pProfitPoints = 0, int pMinPoints = 10, bool absoluteLevel = false)
{
   if(pStopPoints == 0 && pProfitPoints == 0) return false;
   
   bool result = OrderSelect(pTicket,SELECT_BY_TICKET);
   
   if(result == false)
   {
      Print("Modify stops: #",pTicket," not found!");
      return false;
   }
   
   double orderType = OrderType();
   double orderOpenPrice = OrderOpenPrice();
   string orderSymbol = OrderSymbol();
   
   double stopLoss = 0;
   double takeProfit = 0;
   
   if(orderType == OP_BUY)
   {
      stopLoss = absoluteLevel ? pStopPoints : BuyStopLoss(orderSymbol,(int)pStopPoints,orderOpenPrice);
      if(stopLoss != 0) stopLoss = AdjustBelowStopLevel(orderSymbol,stopLoss,pMinPoints);
      
      takeProfit = absoluteLevel ? pProfitPoints : BuyTakeProfit(orderSymbol,(int)pProfitPoints,orderOpenPrice);
      if(takeProfit != 0) takeProfit = AdjustAboveStopLevel(orderSymbol,takeProfit,pMinPoints);
   }
   else if(orderType == OP_SELL)
   {
      stopLoss = absoluteLevel ? pStopPoints : SellStopLoss(orderSymbol,(int)pStopPoints,orderOpenPrice);
      if(stopLoss != 0) stopLoss = AdjustAboveStopLevel(orderSymbol,stopLoss,pMinPoints);
      
      takeProfit = absoluteLevel ? pProfitPoints : SellTakeProfit(orderSymbol,(int)pProfitPoints,orderOpenPrice);
      if(takeProfit != 0) takeProfit = AdjustBelowStopLevel(orderSymbol,takeProfit,pMinPoints);
   }
   
   result = modifyOrder(pTicket,0,stopLoss,takeProfit);
   return(result);
}




//+------------------------------------------------------------------+
//| Order handling props                                             |
//+------------------------------------------------------------------+

static void OrderHandler::setMagicNumber(int pMagic)
{
   if(_magicNumber != 0)
   {
      Alert("Magic number changed! Any orders previously opened by this expert advisor will no longer be handled!");
   }
   
   _magicNumber = pMagic;
   _counter.setMagicNumber(pMagic);
}

static int OrderHandler::getMagicNumber(void)
{
   return(_magicNumber);
}


static void OrderHandler::setSlippage(int pSlippage)
{
   _slippage = pSlippage;
}


// Market price for order of given type
// > close existing order gives opposite MODE
double OrderHandler::getOrderPrice(int pType, string pSymbol, bool isClose = false){
   double orderPrice = 0.0;
	if(pType == OP_BUY) 
   {
      orderPrice = MarketInfo(pSymbol, isClose ? MODE_BID : MODE_ASK);
   } else if(pType == OP_SELL)
   {
      orderPrice = MarketInfo(pSymbol, isClose ? MODE_ASK : MODE_BID);
   } 
   return(orderPrice);
}

// Check if existing order count for given type
bool OrderHandler::isNoActiveOrdersForType(int pType){
   return( (pType == OP_BUY && _counter.buyOrders() == 0) 
      || (pType == OP_SELL && _counter.sellOrders() == 0) );
}


// Select order for ticket
bool OrderHandler::selectOrder(int pTicket){
   bool isOrderSelected = OrderSelect(pTicket,SELECT_BY_TICKET);
   
   if( !isOrderSelected )
   {
      int errorCode = GetLastError();
      string errDesc = ErrorDescription(errorCode);
      Alert("Close order: Error selecting order #",pTicket,". Error ",errorCode," - ",errDesc);
   }
   return(isOrderSelected);
}


int OrderHandler::positionDirection(){
   int direction = 0;
   if(_tickets.buy > 1){
      direction = 1;
   } else if(_tickets.sell > 1){
      direction = -1;
   }
   return(direction);
}

bool OrderHandler::isLong(){
   return(positionDirection() > 0);
}

bool OrderHandler::isShort(){
   return(positionDirection() < 0);
}


