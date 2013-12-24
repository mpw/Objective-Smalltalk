//
//  MPWConnectToDefault.m
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "MPWConnectToDefault.h"
#import "MPWMessagePortDescriptor.h"
#import "MPWFilterScheme.h"

@implementation MPWConnectToDefault

idAccessor( rhs, setRhs )
idAccessor( lhs, setLhs )

-(id)evaluateIn:(id)aContext
{
    id left=[[[self lhs] evaluateIn:aContext] defaultComponentInstance];
    id right=[[[self rhs] evaluateIn:aContext]defaultComponentInstance];
    
//    NSLog(@"left: %@",left);
//    NSLog(@"right: %@",right);
    
    id input=[right ports][@"IN"];
    id output=[right ports][@"OUT"];
//    NSLog(@"input: %@",input);
//    NSLog(@"output: %@",output);
    if ( [input connect:output]) {
//        NSLog(@"did connect");
        return [input sendsMessages] ? right : left;
    } else {
//        NSLog(@"did not connect");
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
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:nil sends:NO] autorelease];
}

-defaultOutputPort
{
    return nil;
}

-(NSDictionary*)ports
{
    return @{ @"IN": [self defaultInputPort],
              @"OUT": [self defaultOutputPort],
              };
}

@end

@implementation MPWStream(connecting)


-defaultOutputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:@"target" protocol:@protocol(Streaming) sends:YES] autorelease];
}

-defaultInputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

+defaultComponentInstance
{
    return [self stream];
}

@end

@implementation MPWScheme(connecting)

-defaultOutputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Scheme) sends:NO] autorelease];
}

@end

@implementation MPWFilterScheme(connecting)

-defaultInputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:@"source" protocol:@protocol(Scheme) sends:YES] autorelease];
}

@end
