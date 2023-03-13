//
//  MPWStConnectorTests.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.20.
//

#import "MPWStConnectorTests.h"
#import "STExpression.h"
#import "MPWStTests.h"

@implementation MPWStConnectorTests

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStConnectorTests(testing) 

+(void)testConnectFilters
{
    TESTEXPR( (@"filter adder |{  ^object + 3. }.  filter multiplier |{  ^object * 3. }.  pipe ← adder -> multiplier. pipe writeObject:10. pipe finalTarget lastObject."), @(39) );

}

+(void)testConnectStores
{
    TESTEXPR( (@"scheme:cache := MPWCachingStore store. scheme:site := MPWDictStore store. scheme:cache -> scheme:site. site:hi := 'there'.  cache:hi. "), @"there" );

}

+(NSArray*)testSelectors
{
   return @[
       @"testConnectFilters",
       @"testConnectStores",
   ];
}

@end
