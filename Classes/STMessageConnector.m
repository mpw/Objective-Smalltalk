//
//  STMessageConnector.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.02.21.
//

#import "STMessageConnector.h"
#import "STMessagePortDescriptor.h"


@implementation STMessageConnector

-(BOOL)isCompatible
{
    return self.source.isSettable && self.source.sendsMessages
            && self.target.receivesMessages &&
            self.protocol == [self.source messageProtocol] &&
            self.protocol == [self.target messageProtocol];
}

-(BOOL)connect
{
    if ( [self isCompatible] ) {
        [[self.source target] setValue:[[self.target target] value]];
        return YES;
    }
    return NO;
}

-(void)dealloc
{
    [_protocol release];
    [super dealloc];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMessageConnector(testing) 

//--- test in STMessagePortDescriptor tests this

+(NSArray*)testSelectors
{
   return @[
			];
}

@end
