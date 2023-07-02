//
//  STPropertyMethodHeader.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 02.07.23.
//

#import "STPropertyMethodHeader.h"

@implementation STPropertyMethodHeader

-(id)initWithTemplate:(MPWReferenceTemplate*)template verb:(MPWRESTVerb)verb
{
    NSArray *formals=[template formalParameters];
    NSMutableString *s=[@"method" mutableCopy];
    for (NSString *paramName in formals) {
        [s appendFormat:@"Arg:%@ ",paramName];
    }
    [s appendString:@"ref:theRef "];
    if ( verb == MPWRESTVerbPUT ) {
        [s appendString:@"value:newValue "];
    }

    self=[super initWithString:s];
    
    return self;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPropertyMethodHeader(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
