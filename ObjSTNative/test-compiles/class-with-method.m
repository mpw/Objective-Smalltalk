#import <Foundation/Foundation.h>

@interface Hi : NSObject {}

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter;
@end

@implementation Hi

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter
{
    return [s componentsSeparatedByString:delimiter];
}
 
@end
