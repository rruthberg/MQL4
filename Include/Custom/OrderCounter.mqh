//+------------------------------------------------------------------+
//| Order counts                                                     |
//+------------------------------------------------------------------+

class OrderCounter
{
   private:  
      enum COUNT_ORDER_TYPE
      {
         COUNT_BUY,
         COUNT_SELL,
         COUNT_BUY_STOP,
         COUNT_SELL_STOP,
         COUNT_BUY_LIMIT,
         COUNT_SELL_LIMIT,
         COUNT_MARKET,
         COUNT_PENDING,
         COUNT_ALL
      };
      
      int ordersByType(COUNT_ORDER_TYPE pType);

      int magicNumber;
 
      
   public:
      int buyOrders();
      int sellOrders();
      int buyStopOrders();
      int sellStopOrders();
      int buyLimitOrders();
      int sellLimitOrders();
      int totalMarketOrders();
      int totalPendingOrders();
      int totalOrders();
      void setMagicNumber(int pMagic);

};


int OrderCounter::ordersByType(COUNT_ORDER_TYPE pType)
{
   // Order counts
   int buy = 0, sell = 0, buyStop = 0, sellStop = 0, 
      buyLimit = 0, sellLimit = 0, totalOrders = 0;
   
   // Loop through open order pool from oldest to newest
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      // Select order
      bool result = OrderSelect(order,SELECT_BY_POS);
      
      int orderType = OrderType();
      int orderMagicNumber = OrderMagicNumber();
      
      // Add to order count if magic number matches
      if(orderMagicNumber == magicNumber)
      {
         switch(orderType)
         {
            case OP_BUY:
               buy++;
               break;
               
            case OP_SELL:
               sell++;
               break;
               
            case OP_BUYLIMIT:
               buyLimit++;
               break;
               
            case OP_SELLLIMIT:
               sellLimit++;
               break;   
               
            case OP_BUYSTOP:
               buyStop++;
               break;
               
            case OP_SELLSTOP:
               sellStop++;
               break;          
         }
         
         totalOrders++;
      }
   }
   
   // Return order count based on pType
   int returnTotal = 0;
   switch(pType)
   {
      case COUNT_BUY:
         returnTotal = buy;
         break;
         
      case COUNT_SELL:
         returnTotal = sell;
         break;
         
      case COUNT_BUY_LIMIT:
         returnTotal = buyLimit;
         break;
         
      case COUNT_SELL_LIMIT:
         returnTotal = sellLimit;
         break;
         
      case COUNT_BUY_STOP:
         returnTotal = buyStop;
         break;
         
      case COUNT_SELL_STOP:
         returnTotal = sellStop;
         break;
         
      case COUNT_MARKET:
         returnTotal = buy + sell;
         break;
         
      case COUNT_PENDING:
         returnTotal = buyLimit + sellLimit + buyStop + sellStop;
         break;   
         
      case COUNT_ALL:
         returnTotal = totalOrders; 
         break;        
   }
   
   return(returnTotal);
}


int OrderCounter::buyOrders(void)
{
   int total = ordersByType(COUNT_BUY);
   return(total);
}

int OrderCounter::sellOrders(void)
{
   int total = ordersByType(COUNT_SELL);
   return(total);
}

int OrderCounter::buyLimitOrders(void)
{
   int total = ordersByType(COUNT_BUY_LIMIT);
   return(total);
}

int OrderCounter::sellLimitOrders(void)
{
   int total = ordersByType(COUNT_SELL_LIMIT);
   return(total);
}

int OrderCounter::buyStopOrders(void)
{
   int total = ordersByType(COUNT_BUY_STOP);
   return(total);
}

int OrderCounter::sellStopOrders(void)
{
   int total = ordersByType(COUNT_SELL_STOP);
   return(total);
}

int OrderCounter::totalMarketOrders(void)
{
   int total = ordersByType(COUNT_MARKET);
   return(total);
}

int OrderCounter::totalPendingOrders(void)
{
   int total = ordersByType(COUNT_PENDING);
   return(total);
}

int OrderCounter::totalOrders(void)
{
   int total = ordersByType(COUNT_ALL);
   return(total);
}

void OrderCounter::setMagicNumber(int pMagic){
   magicNumber = pMagic;
}