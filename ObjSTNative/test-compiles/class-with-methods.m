#import <Foundation/Foundation.h>

@interface Hi : NSObject { 
   int factor;
}

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter;
-(int)double:(int)input;
-(int)mulByAddition:(int)input factor:(int)factor;
@property int factor;
@property (strong,nonatomic) id someProperty;

@end

@implementation Hi

@synthesize factor=factor;

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter
{
    return [s componentsSeparatedByString:delimiter];
}

-(int)double:(int)input
{
  return input*2;
}

-(int)mulByAddition:(int)input factor:(int)lfactor
{
   for (int i=0;i<lfactor;i++) {
	input+=lfactor;
   }
   return input;
}

 
-(int)mulByAddition:(int)input
{
   return [self mulByAddition:input factor:factor];
}
@end
