//
//  STMessageConnector.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.02.21.
//

#import "STMessageConnector.h"

@implementation STMessageConnector

-(instancetype)initWithSelector:(SEL)newSelector
{
    self=[super init];
    self.selector=newSelector;
    return self;
}

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
    [_source release];
    [_target release];
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
