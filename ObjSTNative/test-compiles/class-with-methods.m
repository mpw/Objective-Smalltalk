#import <Foundation/Foundation.h>

@interface Hi : NSObject {}

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter;
-(int)double:(int)input;
-(int)mulByAddition:(int)input factor:(int)factor;
@end

@implementation Hi

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter
{
    return [s componentsSeparatedByString:delimiter];
}

-(int)double:(int)input
{
  return input*2;
}

-(int)mulByAddition:(int)input factor:(int)factor
{
   for (int i=0;i<factor;i++) {
	input+=factor;
   }
   return input;
}
 
@end
