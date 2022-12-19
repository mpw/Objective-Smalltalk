#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

@interface IfTrueIfFalseTester : NSObject {}
-tester:cond;

@end
@implementation IfTrueIfFalseTester 

-tester:cond { 
    id trueValue=@(2);
    id falseValue=@(3);
    return [cond ifTrue:^{ return trueValue; } ifFalse:^{ return falseValue; }];
}

@end 


int main( void ) {
   [MPWBlockContext new];
   id b=[IfTrueIfFalseTester new];
   id result=[b tester:@(true)];
   NSLog(@"reusult: %@",result);
   return 0;
}
