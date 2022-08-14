//
//  STMessagePortDescriptor.m
//  Arch-S
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "STMessagePortDescriptor.h"
#import <MPWFoundation/MPWFoundation.h>
#import "STMessageConnector.h"
//#import <objc/Protocol.h>

@implementation STMessagePortDescriptor

objectAccessor(MPWPropertyBinding*, target, setTarget)
boolAccessor(sendsMessages, setSendsMessages)
boolAccessor(isSettable, setIsSettable)
objectAccessor(Protocol*, messageProtocol, setMessageProtocol)

-initWithTarget:aTarget key:aKey protocol:aProtocol sends:(BOOL)sends
{
    self=[super init];
//    NSLog(@"for %p target: %@ key: %@",self,aTarget,aKey);
    [self setTarget:[MPWPropertyBinding valueForName:aKey ? aKey : @"self"]];
    [self setIsSettable:aKey != nil];
    [[self target] bindToTarget:aTarget];
    [self setMessageProtocol:aProtocol];
    [self setSendsMessages:sends];

//    NSLog(@"sends: %d protocol: %@",sends,aProtocol);
    return self;
}

-(id)targetObject
{
    return [[self target] value];
}


-(BOOL)receivesMessages
{
    return ![self sendsMessages];
}


-(BOOL)connect:(STMessagePortDescriptor*)other
{
    STMessageConnector *connector=[[STMessageConnector new] autorelease];
    connector.source=self;
    connector.target=other;
    connector.protocol=[self messageProtocol];
    
    return [connector connect];
}

-(NSDictionary*)ports
{
    return @{
        @"IN": self,
        @"OUT": self,
    };
}


-(NSString *)description{
    id theTarget=[[self target] target];
    return [NSString stringWithFormat:@"<%@:%p: target: %@:%p message: %@ key:%@>",
            [self class],self,[theTarget class],theTarget,NSStringFromSelector(self.message),[[self target] name]];
}

@end




@implementation STMessagePortDescriptor(testing)

+_createInputPortDescriptorForStream:(MPWWriteStream*)s1
{
    return [[[self alloc] initWithTarget:s1 key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

+_createOutputPortDescriptorForStream:(MPWWriteStream*)s1
{
    return [[[self alloc] initWithTarget:s1 key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
}

+_createOutputPortDescriptorForStreamWithIncompatibleProtool:(MPWWriteStream*)s1
{
    return [[[self alloc] initWithTarget:s1 key:@"target" protocol:@protocol(NSObject) sends:YES] autorelease];
}

+(void)testConnectMPWFilter
{
    MPWFilter *sourceFilter=[MPWFilter stream];
    MPWFilter *targetFilter=[MPWFilter stream];
  
    STMessagePortDescriptor *targetPortDescriptor=[self _createInputPortDescriptorForStream:targetFilter];

    EXPECTFALSE([targetPortDescriptor sendsMessages], @"input port sends messages");
    EXPECTFALSE([targetPortDescriptor isSettable], @"input port is settable");
    EXPECTTRUE([targetPortDescriptor receivesMessages], @"input port receives messages");
    IDEXPECT([[targetPortDescriptor target] value], targetFilter, @"input target");
    
    STMessagePortDescriptor *sourcePortDescriptor=[self _createOutputPortDescriptorForStream:sourceFilter];

    
    EXPECTTRUE([sourcePortDescriptor sendsMessages], @"output port sends messages");
    EXPECTTRUE([sourcePortDescriptor isSettable], @"output port is settable");
    EXPECTFALSE([sourcePortDescriptor receivesMessages], @"output port receives messages");

    EXPECTTRUE([sourcePortDescriptor connect:targetPortDescriptor],@"connected the streams");
    EXPECTFALSE([targetPortDescriptor  connect:sourcePortDescriptor],@"connected the streams");

    EXPECTNIL([(MPWFilter*)[targetFilter target] lastObject], @"nothing in target before write");
    [sourceFilter writeObject:@"hi"];
    IDEXPECT([(MPWFilter*)[targetFilter target] lastObject], @"hi", @"target written");
    

}

+(void)testCannotConnectTwoInputs
{
    MPWFilter *s1=[MPWFilter stream];
    MPWFilter *s2=[MPWFilter stream];
    
    STMessagePortDescriptor *input1=[self _createInputPortDescriptorForStream:s1];
    STMessagePortDescriptor *input2=[self _createInputPortDescriptorForStream:s2];
    EXPECTFALSE([input1 connect:input2], @"connect two input ports");
}


+(void)testCannotConnectIncompatibleProtocols
{
    MPWFilter *s1=[MPWFilter stream];
    MPWFilter *s2=[MPWFilter stream];
    
    STMessagePortDescriptor *input1=[self _createInputPortDescriptorForStream:s1];
    STMessagePortDescriptor *output=[self _createOutputPortDescriptorForStreamWithIncompatibleProtool:s2];
    EXPECTFALSE([input1 connect:output], @"connect incompatible protocols");
}


+(NSArray*)testSelectors
{
    return @[ @"testConnectMPWFilter"
    , @"testCannotConnectTwoInputs"
    , @"testCannotConnectIncompatibleProtocols"
    ];
}

@end
