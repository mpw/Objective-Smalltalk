//
//  MPWMessagePortDescriptor.m
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "MPWMessagePortDescriptor.h"
#import <MPWFoundation/MPWValueAccessor.h>

@implementation MPWMessagePortDescriptor

objectAccessor(MPWValueAccessor, target, setTarget)
boolAccessor(sendsMessages, setSendsMessages)
boolAccessor(isSettable, setIsSettable)
objectAccessor(Protocol, messageProtocol, setMessageProtocol)

-initWithTarget:aTarget key:aKey protocol:aProtocol sends:(BOOL)sends
{
    self=[super init];
    [self setTarget:[MPWValueAccessor valueForName:aKey ? aKey : @"self"]];
    [self setIsSettable:aKey != nil];
    [[self target] bindToTarget:aTarget];
    [self setMessageProtocol:aProtocol];
    [self setSendsMessages:sends];
    return self;
}


-(BOOL)receivesMessages
{
    return ![self sendsMessages];
}


-(BOOL)isCompatible:(MPWMessagePortDescriptor*)other
{
    return 
    ([self isSettable] != [other isSettable]) &&
        ([self sendsMessages] != [other sendsMessages]) &&
    [[self messageProtocol] isEqual:[other messageProtocol]];
}

-(BOOL)connect:(MPWMessagePortDescriptor*)other
{
    id connectionTarget=nil,source=nil;
//    NSLog(@"connect: %@ to %@",self,other);
    if ( [self isCompatible:other] ) {
        if ( [self isSettable] && ![other isSettable]) {
            connectionTarget=self;
            source=other;
        } else if ( [other isSettable] && ![self isSettable]) {
            connectionTarget=other;
            source=self;
        }
        if ( connectionTarget && source ) {
            [[connectionTarget target] setValue:[[source target] value]];
            return YES;
        }
    }
    return NO;

}

-(NSString *)description{
    id theTarget=[[self target] target];
    return [NSString stringWithFormat:@"<%@:%p: %@:%p key:%@>",
            [self class],self,[theTarget class],theTarget,[[self target] name]];
}

@end




@implementation MPWMessagePortDescriptor(testing)

+_createInputPortDescriptorForStream:(MPWStream*)s1
{
    return [[[self alloc] initWithTarget:s1 key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

+_createOutputPortDescriptorForStream:(MPWStream*)s1
{
    return [[[self alloc] initWithTarget:s1 key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
}

+_createOutputPortDescriptorForStreamWithIncompatibleProtool:(MPWStream*)s1
{
    return [[[self alloc] initWithTarget:s1 key:@"target" protocol:@protocol(NSObject) sends:YES] autorelease];
}

+(void)testConnectMPWStream
{
    MPWStream *s1=[MPWStream stream];
    MPWStream *s2=[MPWStream stream];
  
    MPWMessagePortDescriptor *input=[self _createInputPortDescriptorForStream:s2];

    EXPECTFALSE([input sendsMessages], @"input port sends messages");
    EXPECTFALSE([input isSettable], @"input port is settable");
    EXPECTTRUE([input receivesMessages], @"input port receives messages");
    IDEXPECT([[input target] value], s2, @"input target");
    
    MPWMessagePortDescriptor *output=[self _createOutputPortDescriptorForStream:s1];

    
    EXPECTTRUE([output sendsMessages], @"output port sends messages");
    EXPECTTRUE([output isSettable], @"output port is settable");
    EXPECTFALSE([output receivesMessages], @"output port receives messages");

    EXPECTTRUE([input connect:output],@"connected the streams");
    
    EXPECTNIL([[s2 target] lastObject], @"nothing in target before write");
    [s1 writeObject:@"hi"];
    IDEXPECT([[s2 target] lastObject], @"hi", @"target written");
    

}

+(void)testCannotConnectTwoInputs
{
    MPWStream *s1=[MPWStream stream];
    MPWStream *s2=[MPWStream stream];
    
    MPWMessagePortDescriptor *input1=[self _createInputPortDescriptorForStream:s1];
    MPWMessagePortDescriptor *input2=[self _createInputPortDescriptorForStream:s2];
    EXPECTFALSE([input1 connect:input2], @"connect two input ports");
}


+(void)testCannotConnectIncompatibleProtocols
{
    MPWStream *s1=[MPWStream stream];
    MPWStream *s2=[MPWStream stream];
    
    MPWMessagePortDescriptor *input1=[self _createInputPortDescriptorForStream:s1];
    MPWMessagePortDescriptor *output=[self _createOutputPortDescriptorForStreamWithIncompatibleProtool:s2];
    EXPECTFALSE([input1 connect:output], @"connect incompatible protocols");
}


+(NSArray*)testSelectors
{
    return @[ @"testConnectMPWStream"
    , @"testCannotConnectTwoInputs"
    , @"testCannotConnectIncompatibleProtocols"
    ];
}

@end