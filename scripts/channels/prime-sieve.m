#import <Foundation/Foundation.h>
#import <MPWFoundation/MPWFoundation.h>



@interface Source : MPWStreamSource {
    long max;
}
longAccessor_h( max, setMax )
@end

@implementation Source 
longAccessor( max, setMax )
    -(void) run {

         for (long i=2;i<max;i++ ) {
          [self.target writeObject:@(i)];
	 }
      }


@end

@interface Filterdiv : MPWFilter  {
   long divisor;
}

longAccessor_h( divisor, setDivisor )
@end

@implementation Filterdiv 
longAccessor( divisor, setDivisor )

-(void)writeObject:aNumber {
   long num=[aNumber longValue];
   if ( ! ((num % divisor) == 0) )  {
       [self.target writeObject:@(num)];
   }
}

@end

@interface Sievefilter : MPWFilter {
     id currentfilter;
     id lastfilter;
}

idAccessor_h( currentfilter, setCurrentfilter )

@end

@implementation Sievefilter


idAccessor( currentfilter, setCurrentfilter )

  -initWithTarget:aTarget {
	self = [super initWithTarget:aTarget];
        lastfilter = self;
        currentfilter = [[Filterdiv alloc]  initWithTarget:self];
        [currentfilter setDivisor:2];
        return self;
     }
     -(void)addFilterForNumber:(long)aNumber {
        id newfilter = [[Filterdiv alloc]  initWithTarget:self];
        [newfilter setDivisor:aNumber];
        [currentfilter setTarget:newfilter];
        currentfilter = newfilter;
     }
     -(void)writeObject:aNumberObject {
        long aNumber=[aNumberObject longValue];
        [self addFilterForNumber:aNumber];
        [self.target writeObject:aNumberObject];
    }

@end

int main(int argc, char *argv[]) { 
    int max=2000;
    id source = [Source new];
    if ( argc > 1 ) {
	max=atoi(argv[1]);
    }
    [source setMax:max];
    id sieve  = [Sievefilter new];
    [sieve setTarget:[[MPWPrintLiner alloc] initWithTarget:[MPWByteStream Stdout]]]; 
    [source setTarget:[sieve currentfilter]];
    [source run];
    return 0;
}
