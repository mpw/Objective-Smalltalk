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
    
    id input=[right defaultInputPort];
    id output=[left defaultOutputPort];
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


@end

@implementation MPWStream(connecting)


-defaultOutputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:@"target" protocol:nil sends:YES] autorelease];
}

+defaultComponentInstance

{
    return [self stream];
}



@end

@implementation MPWFilterScheme(connecting)

-defaultInputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:@"source" protocol:nil sends:YES] autorelease];
}

-defaultOutputPort
{
    return [[[MPWMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:nil sends:NO] autorelease];
}




@end

