//
//  MPWFastSuperMessage.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 27.03.21.
//

#import "MPWFastSuperMessage.h"
#import <objc/message.h>

@implementation MPWFastSuperMessage

-sendTo:receiver withArguments:(id*)argbuf count:(int)argCount
{
#ifndef GS_API_LATEST
    struct objc_super superSend={
        receiver, self.superclassOfTarget
    };
    id result = ((IMP4)objc_msgSendSuper)( (id)&superSend, selector, argbuf[0],argbuf[1],argbuf[2],argbuf[3] );
    return result;
#else
#warning super messaging not implemented in GNUstep
	[NSException raise:@"notimplemeted" format:@"super messagigng not implemented in GNUstep"];
	return nil;
#endif
}



@end


#import <MPWFoundation/DebugMacros.h>

@interface _MPWSuperSendTestSuperClass : NSObject
-result;
@end

@implementation _MPWSuperSendTestSuperClass

-result { return @"super"; }

@end

@interface _MPWSuperSendTestSubClass : _MPWSuperSendTestSuperClass
@end

@implementation _MPWSuperSendTestSubClass

-result { return @"sub"; }

@end


@implementation MPWFastSuperMessage(testing) 

+(void)testSuperSend
{
    id args[10];
    MPWFastSuperMessage *msg=[MPWFastSuperMessage messageWithSelector:@selector(result) typestring:"@@:"];
    msg.superclassOfTarget=[_MPWSuperSendTestSuperClass class];
    _MPWSuperSendTestSubClass *target=[[_MPWSuperSendTestSubClass new] autorelease];
    id result=[msg sendTo:target withArguments:args count:0];
    IDEXPECT( result, @"super", @"super send should get superclass result");
}

+(NSArray*)testSelectors
{
   return @[
			@"testSuperSend",
			];
}

@end
