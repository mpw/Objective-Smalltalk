//
//  STProtocolScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 21.02.21.
//

#import "STProtocolScheme.h"

@implementation STProtocolScheme

-(id)at:(id<MPWIdentifying>)aReference
{
    return objc_getProtocol( [[aReference path] UTF8String]);
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STProtocolScheme(testing) 

+(void)testCanRetrieveNSObjectScheme
{
    STProtocolScheme *s=[self store];
    id nsobject=s[@"NSObject"];
    IDEXPECT( nsobject, @protocol(NSObject), @"NSObject scheme");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCanRetrieveNSObjectScheme",
			];
}

@end
