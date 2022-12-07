/*

   OCO Part 1

   Copyright 2022, Orchard Forex
   https://www.orchardforex.com

*/

#property copyright "Copyright 2013-2022, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"

#property strict

input int    InpTradeCounter   = 5;    // How many trade pairs to place
input int    InpTradeGapPoints = 500;  // How far from opening price to place trades
input int    InpSLTPPoints     = 50;   // SL/TP points, really just for demonstration
input double InpVolume         = 0.01; // Lot size

int          TradeCounter;
double       TradeGap;
double       SLTP;

struct SOCOPair
{
   int ticket1;
   int ticket2;
   SOCOPair() {}
   SOCOPair( int t1, int t2 ) {
      ticket1 = t1;
      ticket2 = t2;
   }
};

SOCOPair OCOPairs[];

int    OnInit( void ) {

   TradeCounter = InpTradeCounter;
   TradeGap     = PointsToDouble( InpTradeGapPoints );
   SLTP         = PointsToDouble( InpSLTPPoints );

   return ( INIT_SUCCEEDED );
}

void OnTick( void ) {

	OCOClose();
	
   // Only trade until counter reaches zero
   if ( TradeCounter <= 0 ) return;

   // This part so we only trade once per bar
   static datetime previousTime = 0;
   datetime        currentTime  = iTime( Symbol(), Period(), 0 );
   if ( currentTime == previousTime ) return;
   previousTime     = currentTime;

   int buyTicket  = OpenOrder( ORDER_TYPE_BUY_STOP );
   int sellTicket = OpenOrder( ORDER_TYPE_SELL_STOP );

   OCOAdd( buyTicket, sellTicket );
   TradeCounter--;
}

int OpenOrder( ENUM_ORDER_TYPE type ) {

   double price;
   double tp;
   double sl;
   if ( type % 2 == ORDER_TYPE_BUY ) {
      price = SymbolInfoDouble( Symbol(), SYMBOL_ASK ) + TradeGap;
      tp    = price + SLTP;
      sl    = price - SLTP;
   }
   else {
      price = SymbolInfoDouble( Symbol(), SYMBOL_BID ) - TradeGap;
      tp    = price - SLTP;
      sl    = price + SLTP;
   }

   int ticket = OrderSend( Symbol(), type, InpVolume, price, 0, sl, tp );

   return ticket;
}

bool   CloseOrder( int ticket ) {

	return OrderDelete( ticket );
	
}

double PointsToDouble( int points ) {

   double point = SymbolInfoDouble( Symbol(), SYMBOL_POINT );
   return ( point * points );
}

void OCOAdd( int ticket1, int ticket2 ) {

   if ( ticket1 <= 0 || ticket2 <= 0 ) return;
   int      count = ArraySize( OCOPairs );
   SOCOPair pair( ticket1, ticket2 );
   ArrayResize( OCOPairs, count + 1 );
   OCOPairs[count] = pair;
}

void OCOClose( ) {

   for ( int i = ArraySize( OCOPairs ) - 1; i >= 0; i-- ) {
      if ( !OrderSelect(OCOPairs[i].ticket1, SELECT_BY_TICKET)
      		|| (OrderType()==ORDER_TYPE_BUY || OrderType()==ORDER_TYPE_SELL)
      		|| OrderCloseTime()>0 ) {
         CloseOrder( OCOPairs[i].ticket2 );
         OCORemove( i );
         continue;
      }
      if ( !OrderSelect(OCOPairs[i].ticket2, SELECT_BY_TICKET)
      		|| (OrderType()==ORDER_TYPE_BUY || OrderType()==ORDER_TYPE_SELL)
      		|| OrderCloseTime()>0 ) {
         CloseOrder( OCOPairs[i].ticket1 );
         OCORemove( i );
      }
   }
}

void OCORemove( int index ) {

	int count = ArraySize(OCOPairs);
	for (int i=index; i<count-1; i++) {
		OCOPairs[i] = OCOPairs[i+1];
	}
	ArrayResize(OCOPairs, count-1);
   return;
}
