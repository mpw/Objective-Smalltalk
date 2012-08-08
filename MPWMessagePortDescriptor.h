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

boolAccessor_h(sendsMessages, setSendsMessages)
boolAccessor_h(isSettable, setIsSettable)

-(BOOL)receivesMessages;
@end
