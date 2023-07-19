#include <stdlib.mqh>
#include <Math\Stat\Math4.mqh>
	  

//+------------------------------------------------------------------+
//| Math and Statistical helper functions                            |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Computes the semideviation of the values in array[]              |
//+------------------------------------------------------------------+
bool MathSemiDeviation(const double &price[], double &result[],const double &means[], int position, int period)
  {
    double posDev = 0.0;
    double negDev = 0.0;
    int posSize = 0;
    int negSize = 0;

    int size=ArraySize(price);
    int sizeResult=ArraySize(result);

    if(size < 2 || sizeResult < 2 || size < period || position >= size)
    {
      return(false);
    }

    double mean=means[position];

   for(int i=0; i<period; i++){
    if(price[position-i] > mean){
        posDev += MathPow(price[position-i]-mean,2);
        posSize +=1;
    } else {
        negDev += MathPow(price[position-i]-mean,2);
        negSize +=1;
    }
   }

   result[0] = posSize > 1 ? MathSqrt(posDev/(posSize-1)) : 0.0;
   result[1] = negSize > 1 ? MathSqrt(negDev/(negSize-1)) : 0.0;   

   return(true);
  }