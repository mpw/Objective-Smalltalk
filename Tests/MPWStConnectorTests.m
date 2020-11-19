//
//  MPWStConnectorTests.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.20.
//

#import "MPWStConnectorTests.h"
#import "MPWExpression.h"

@implementation MPWStConnectorTests

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStConnectorTests(testing) 

+(void)testConnectFilters
{
    TESTEXPR( (@"filter adder |{  ^object + 3. }.  filter multiplier |{  ^object * 3. }.  pipe ← adder -> multiplier. pipe writeObject:10. pipe finalTarget lastObject."), @(39) );

}

+(NSArray*)testSelectors
{
   return @[
       @"testConnectFilters",
   ];
}

@end
