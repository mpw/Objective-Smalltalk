//
//  STMessagePortDescriptor.h
//  Arch-S
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import <ObjectiveSmalltalk/STPort.h>
#import <MPWFoundation/MPWFoundation.h>

@class MPWPropertyBinding;

@interface STMessagePortDescriptor : STPort
{
    MPWPropertyBinding    *target;
    BOOL                isSettable;
    BOOL                sendsMessages;
    Protocol            *messageProtocol;
}

-initWithTarget:aTarget key:aKey protocol:aProtocol sends:(BOOL)sends;

boolAccessor_h(sendsMessages, setSendsMessages)
boolAccessor_h(isSettable, setIsSettable)

@property (assign) SEL message;

-(BOOL)receivesMessages;
-(BOOL)connect:(STMessagePortDescriptor*)other;
-(Protocol*)messageProtocol;
-target;

@end
