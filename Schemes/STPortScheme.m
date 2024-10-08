//
//  STPortScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 26.02.21.
//

#import "STPortScheme.h"
#import "STMessagePortDescriptor.h"

@implementation STPortScheme

-(id)at:(id<MPWIdentifying>)aReference
{
    NSArray *components=[aReference pathComponents];
    if ( components.count >= 1  ) {
        id base=[self.source at:components.firstObject];
        if (components.count == 1) {
            return [base ports];
        } else if ( components.count == 2) {
            SEL message=NSSelectorFromString(components.lastObject);
            STMessagePortDescriptor *port=[STMessagePortDescriptor inputPortFor:base withProtocol:nil key:@"self"];
            port.message=message;
            return port;
        }
    }
    return nil;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPortScheme(testing) 

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
