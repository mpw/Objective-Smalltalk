//
//  MPWConnectToDefault.m
//  Arch-S
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "MPWConnectToDefault.h"
#import "STMessagePortDescriptor.h"
#import <MPWFoundation/MPWStreamSource.h>
#import "MPWScheme.h"
#import "STMessageConnector.h"

@implementation MPWConnectToDefault

idAccessor( rhs, setRhs )
idAccessor( lhs, setLhs )

id st_connect_components( id left, id right ) {
    if ( [right isKindOfClass:[STConnector class]]) {
        STConnector *connector=(STConnector*)right;
        left=[left defaultComponentInstance];
        NSDictionary *leftPorts = [left ports];
        id source=leftPorts[@"OUT"];
        [connector setSource:source];
        if ( [connector isCompatible]) {
            [connector connect];
            return left;;
        } else {
            return connector;
        }
    } else if ( [left isKindOfClass:[STConnector class]]) {
        STConnector *connector=(STConnector*)left;
        right=[right defaultComponentInstance];
        NSDictionary *rightPorts = [right ports];
        id target=rightPorts[@"IN"];
        [connector setTarget:target];
        if ( [connector isCompatible]) {
            [connector connect];
            return [[connector source] target];
        } else {
            return connector;
        }
    } else {
        left=[left defaultComponentInstance];
        NSDictionary *leftPorts = [left ports];
        NSDictionary *rightPorts = nil;
        id source=leftPorts[@"OUT"];
        id target=right;
        if ( object_getClass( right ) != object_getClass(@protocol(NSObject))) {
            right=[right defaultComponentInstance];
            rightPorts = [right ports];
            target=rightPorts[@"IN"];
        } else {
            target=right;
            source=left;
        }
        
        if ( [source  connect:target]) {
            return [source sendsMessages] ? left : right;
        } else {
            NSLog(@"did not connect %@ to %@, lefports: %@ -> %@",target,source,leftPorts,rightPorts);
            return nil;
        }    }
    
    
}


-(id)evaluateIn:(id)aContext
{
    id left=[[self lhs] evaluateIn:aContext];
    id right=[[self rhs] evaluateIn:aContext];
    
    return st_connect_components( left, right );
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

@implementation MPWFilter(connecting)

-defaultOutputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"finalTarget" protocol:@protocol(Streaming) sends:YES] autorelease];
}



@end

@implementation NSDictionary(ports)   

-ports
{
    return self;
}

@end

@implementation MPWBinding(connecting)


-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

@end

@implementation MPWWriteStream(connecting)


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
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"finalTarget" protocol:@protocol(Streaming) sends:YES] autorelease];
}


@end



@implementation MPWFileBinding(connecting)

-defaultOutputPort
{
    return [[self source] defaultOutputPort];
}

//-defaultInputPort
//{
//    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"writeStream" protocol:@protocol(Streaming) sends:NO] autorelease];
//}
//

@end


@implementation MPWLoggingStore(connecting)

-(BOOL)sendsMessages
{
    return YES;
}

-(BOOL)connect:other
{
    if ( [other class] == [@protocol(NSObject) class] ) {
        MPWNotificationStream *s = [[[MPWNotificationStream alloc] initWithNotificationProtocol: other shouldPostOnMainThread:YES] autorelease];
        self.log = s;
        return YES;
    } else {
        return [super connect:other];
    }
}

@end

