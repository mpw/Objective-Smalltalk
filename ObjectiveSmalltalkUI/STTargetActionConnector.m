//
//  STTargetActionConnector.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 25.02.21.
//

#import "STTargetActionConnector.h"

@implementation STTargetActionConnector

-(BOOL)isCompatible {
    return self.source != nil && self.target != nil;
}
-(BOOL)connect {
    NSControl *theControl=[[[self source] target] target];
    id theTargetObject=[[[self target] target] target];
    [theControl setTarget:theTargetObject];
    [theControl setAction:self.message];
    return YES;
}



-(instancetype)initWithSelector:(SEL)newSelector
{
    self=[super init];
    self.message=newSelector;
    return self;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: source: %@ target: %@ message: %@>",self.class,self,self.source,self.target,NSStringFromSelector(self.message)];
}

@end

@implementation NSControl(ports)

-defaultOutputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
}



@end
