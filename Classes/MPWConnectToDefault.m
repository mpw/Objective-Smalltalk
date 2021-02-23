//
//  MPWConnectToDefault.m
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "MPWConnectToDefault.h"
#import "STMessagePortDescriptor.h"
#import <MPWFoundation/MPWStreamSource.h>
#import "MPWScheme.h"

// FIXME:   need some tests for this!
//          (just had a hard-to-find bug where I was getting the IN/OUT
//          ports both from the right-hand-side...)

@implementation MPWConnectToDefault

idAccessor( rhs, setRhs )
idAccessor( lhs, setLhs )

-(id)evaluateIn:(id)aContext
{
    id left=[[[self lhs] evaluateIn:aContext] defaultComponentInstance];
    id right=[[[self rhs] evaluateIn:aContext] defaultComponentInstance];
    
    NSDictionary *leftPorts = [left ports];
    NSDictionary *rightPorts = [right ports];
//    NSLog(@"connect: left: %@",left);
//    NSLog(@"connect: right: %@",right);
    
    id target=rightPorts[@"IN"];
    id source=leftPorts[@"OUT"];
//    NSLog(@"input port: %@",input);
//    NSLog(@"output port: %@",output);
    if ( [source  connect:target]) {
//        NSLog(@"did connect");
        return [source sendsMessages] ? left : right;
    } else {
        NSLog(@"did not connect %@ to %@,ports: %@ -> %@",target,source,leftPorts,rightPorts);
        return nil;
    }
}

-(void)dealloc
{
    [lhs release];
    [rhs release];
    [super dealloc];
}

@end


@implementation NSObject(connecting)

-defaultComponentInstance
{
    return self;
}

+defaultComponentInstance

{
    return [[self new] autorelease];
}

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:nil sends:NO] autorelease];
}

-defaultOutputPort
{
    return nil;
}

-(NSDictionary*)ports
{
    NSMutableDictionary *ports=[NSMutableDictionary dictionary];
    if ( [self defaultInputPort]) {
        ports[@"IN"]=[self defaultInputPort];
    }
    if ( [self defaultOutputPort]) {
        ports[@"OUT"]=[self defaultOutputPort];
    }
//    NSLog(@"ports for %@: %@",self,ports);
    return ports;
}

@end

@implementation MPWWriteStream(connecting)


-defaultOutputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
}

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

+defaultComponentInstance
{
    return [self stream];
}

@end


@implementation MPWStreamSource(connecting)

-defaultOutputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
}


@end



@implementation MPWFileBinding(connecting)

-defaultOutputPort
{
    return [[self source] defaultOutputPort];
}

//-defaultInputPort
//{
//    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"sink" protocol:@protocol(Streaming) sends:NO] autorelease];
//}
//

@end
