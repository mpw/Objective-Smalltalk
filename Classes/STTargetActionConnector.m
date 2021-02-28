//
//  STTargetActionConnector.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 25.02.21.
//

#import "STTargetActionConnector.h"
#import "STMessagePortDescriptor.h"
#import "STTargetActionSenderPort.h"

@implementation STTargetActionConnector

-(BOOL)isCompatible {
    return self.source != nil && self.target != nil;
}
-(BOOL)connect {
    id <TargetActionSource> theControl=[[self source] targetObject];
    id theTargetObject=[[[self target] target] target];
    [theControl setTarget:theTargetObject action:self.message];
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

-defaultOutputPort
{
    return self;
}

-defaultInputPort
{
    return self;
}

@end

@implementation NSObject(targetAction)

-(STTargetActionConnector*)actionFor:(SEL)message
{
    STTargetActionConnector *at=[[[STTargetActionConnector alloc] initWithSelector:message] autorelease];
    at.target=[self defaultInputPort];
    return at;
}

-(STMessagePortDescriptor*)portFor:(SEL)message
{
    STMessagePortDescriptor *port=[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:nil sends:NO];
    port.message=message;
    return port;
}

@end

