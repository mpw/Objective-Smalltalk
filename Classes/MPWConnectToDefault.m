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
#import "STMessageConnector.h"

@implementation MPWConnectToDefault

idAccessor( rhs, setRhs )
idAccessor( lhs, setLhs )

-(id)evaluateIn:(id)aContext
{
    id left=[[self lhs] evaluateIn:aContext];
    id right=[[self rhs] evaluateIn:aContext];
    
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
        right=[right defaultComponentInstance];
        NSDictionary *leftPorts = [left ports];
        NSDictionary *rightPorts = [right ports];
        
        id target=rightPorts[@"IN"];
        id source=leftPorts[@"OUT"];
        
        if ( [source  connect:target]) {
            return [source sendsMessages] ? left : right;
        } else {
            NSLog(@"did not connect %@ to %@,ports: %@ -> %@",target,source,leftPorts,rightPorts);
            return nil;
        }    }
    
    
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
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
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
