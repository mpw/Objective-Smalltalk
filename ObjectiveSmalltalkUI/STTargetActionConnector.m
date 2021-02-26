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
    NSControl *theControl=[[self source] targetObject];
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

-defaultOutputPort
{
    return self;
}

-defaultInputPort
{
    return self;
}

@end

@implementation NSControl(ports)

-defaultOutputPort
{
    return [[[STTargetActionSenderPort alloc] initWithControl:self] autorelease];
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

@interface TextFieldContinuity : NSObject

@end

@implementation TextFieldContinuity


+(void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *changedField = [notification object];
    if (changedField.isContinuous) {
        [changedField.target performSelector:changedField.action withObject:changedField];
    }
}



@end

@implementation NSTextField(continuous)


-(void)setContinuous:(BOOL)continuous
{
    [super setContinuous:continuous];
    if ( continuous) {
        self.delegate = (id)[TextFieldContinuity class];
    } else {
        if ( self.delegate == [TextFieldContinuity class]) {
            self.delegate=nil;
        }
    }
}

@end
