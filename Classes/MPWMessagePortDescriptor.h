//
//  MPWMessagePortDescriptor.h
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWValueAccessor;

@interface MPWMessagePortDescriptor : NSObject
{
    MPWValueAccessor    *target;
    BOOL                isSettable;
    BOOL                sendsMessages;
    Protocol            *messageProtocol;
}

-initWithTarget:aTarget key:aKey protocol:aProtocol sends:(BOOL)sends;

boolAccessor_h(sendsMessages, setSendsMessages)
boolAccessor_h(isSettable, setIsSettable)

-(BOOL)receivesMessages;
-(BOOL)connect:(MPWMessagePortDescriptor*)other;

@end
