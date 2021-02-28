//
//  STTargetActionSenderPort.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 26.02.21.
//

#import "STTargetActionSenderPort.h"
#import "STTargetActionConnector.h"

@interface STTargetActionSenderPort()

@property (strong,nonatomic) id control;

@end
@implementation STTargetActionSenderPort


-(BOOL)sendsMessages
{
    return YES;
}


-initWithControl:aControl
{
    self=[super init];
    self.control=aControl;
    return self;
}

-(id)targetObject
{
    return self.control;
}

-(BOOL)receivesMessages
{
    return ![self sendsMessages];
}


-(BOOL)connect:(STMessagePortDescriptor*)other
{
    STTargetActionConnector *connector=[[[STTargetActionConnector alloc] initWithSelector:other.message] autorelease];
    connector.source=(id)self;
    connector.target=other;
    if ( other.messageProtocol == @protocol(Streaming) ) {
        connector.message = @selector(writeTarget:);
    }
    return [connector connect];
}


@end

