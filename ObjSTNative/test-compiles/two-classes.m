#import <Foundation/Foundation.h>

@interface FirstClass : NSObject {}

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter;
@end

@implementation FirstClass

-(NSArray*)components:(NSString*)s splitInto:(NSString*)delimiter
{
    return [s componentsSeparatedByString:delimiter];
}
 
@end

@interface SecondClass : NSObject {}
@end

@implementation SecondClass
-hi { return self; }
-there { return self; }
-more { return self; }
@end
