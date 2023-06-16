#include <stdlib.mqh>
	  

//+------------------------------------------------------------------+
//| Internal functions                                               |
//+------------------------------------------------------------------+

bool RecovableError(int pErrorCode)
{
	// Retry on these error codes
	switch(pErrorCode)
	{
		case ERR_BROKER_BUSY:
		case ERR_COMMON_ERROR:
		case ERR_NO_ERROR:
		case ERR_NO_CONNECTION:
		case ERR_NO_RESULT:
		case ERR_SERVER_BUSY:
		case ERR_NOT_ENOUGH_RIGHTS:
      case ERR_MALFUNCTIONAL_TRADE:
      case ERR_TRADE_CONTEXT_BUSY:
      case ERR_TRADE_TIMEOUT:
      case ERR_REQUOTE:
      case ERR_TOO_MANY_REQUESTS:
      case ERR_OFF_QUOTES:
      case ERR_PRICE_CHANGED:
      case ERR_TOO_FREQUENT_REQUESTS:
		
		return(true);
	}
	
	return(false);
}

// Dont retry on unrecovable errors
bool UnrecovableError(int pErrorCode){
	return !RecovableError(pErrorCode);
}


string OrderTypeToString(int pType)
{
	string orderType;
	if(pType == OP_BUY) orderType = "Buy";
	else if(pType == OP_SELL) orderType = "Sell";
	else if(pType == OP_BUYSTOP) orderType = "Buy stop";
	else if(pType == OP_BUYLIMIT) orderType = "Buy limit";
	else if(pType == OP_SELLSTOP) orderType = "Sell stop";
	else if(pType == OP_SELLLIMIT) orderType = "Sell limit";
	else orderType = "Invalid order type";
	return(orderType);
}





//+------------------------------------------------------------------+
//| Stop loss & take profit calculation                              |
//+------------------------------------------------------------------+

double BuyStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice - (pStopPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double SellStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice + (pStopPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double BuyTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice + (pProfitPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);
}


double SellTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice - (pProfitPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);
}


//+------------------------------------------------------------------+
//| Stop level verification                                         |
//+------------------------------------------------------------------+

// Check stop level
bool CheckAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice >= stopPrice + addPoints) return(true);
	else return(false);
}


bool CheckBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice <= stopPrice - addPoints) return(true);
	else return(false);
}


// Adjust price to stop level
double AdjustAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice > stopPrice + addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice + addPoints;
		Print("Price adjusted above stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}


double AdjustBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice < stopPrice - addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice - addPoints;
		Print("Price adjusted below stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}


void WaitForReadyContext(){
	while(IsTradeContextBusy()) Sleep(10);
}


// Definition of close types
enum CLOSE_MARKET_TYPE
{
    CLOSE_BUY,
    CLOSE_SELL,
    CLOSE_ALL_MARKET
};


struct ticket_tracker 
{
	int buy;
	int sell;
};