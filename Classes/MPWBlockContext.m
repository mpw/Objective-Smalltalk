//
//  MPWBlockContext.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBlockContext.h"
#import "MPWStatementList.h"
#import "MPWEvaluator.h"
#import <MPWFoundation/MPWBlockFilterStream.h>

@implementation MPWBlockContext

idAccessor( block, setBlock )
idAccessor( context, setContext )

-initWithBlock:aBlock context:aContext
{
	self=[super init];
	[self setBlock:aBlock];
	[self setContext:aContext];
	return self;
}

+blockContextWithBlock:aBlock context:aContext
{
	return [[[self alloc] initWithBlock:aBlock context:aContext] autorelease];
}

-evaluateIn:aContext
{
	if ( aContext ) {
		return [aContext evaluate:[[self block] statements]];
	} else {
		return [[[self block] statements] evaluateIn:aContext];
	}
}

-invokeWithArgs:(va_list)args
{
    for ( NSString *paramName in [[self block] arguments] ) {
        [[self context] bindValue:va_arg(args, id) toVariableNamed:paramName];
    }
    return [self value];
}

-value
{
	return [self evaluateIn:[self context]];
}

-value:anObject
{
    if ( [[[self block] arguments] count]>0) {
        [[self context] bindValue:anObject toVariableNamed:[[[self block] arguments] objectAtIndex:0]];
    }
	return [self value];
}

-(void)drawOnContext:aContext
{
    [self value:aContext];
}

-whileTrue:anotherBlock
{
    id retval=nil;
	while ( [[self value] boolValue] ) {
		retval=[anotherBlock value];
	}
    return retval;
}

-copyWithZone:aZone
{
    return [self retain];
}

-(void)dealloc
{
	[block release];
	[context release];
	[super dealloc];
}



-defaultComponentInstance

{
    MPWBlockFilterStream *s=[MPWBlockFilterStream stream];
    [s setBlock:self];
    return s;
}




@end

#import "MPWStCompiler.h"

@implementation MPWBlockContext(tests)

+(void)testObjcBlocksWithNoArgsAreMapped
{
    IDEXPECT([MPWStCompiler evaluate:@"a:=0. #( 1 2 3 4 ) enumerateObjectsUsingBlock:[ a := a+1. ]. a."], [NSNumber numberWithInt:4], @"just counted the elements in an array using block enumeration");
}

+(void)testObjcBlocksWithObjectArgsAreMapped
{
    IDEXPECT([MPWStCompiler evaluate:@"a:=0. #( 1 2 3 4 ) enumerateObjectsUsingBlock:[ :obj |  a := a+obj. ]. a."], [NSNumber numberWithInt:10], @"added the elements in an array using block enumeration");
}

+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:
            @"testObjcBlocksWithNoArgsAreMapped",
            @"testObjcBlocksWithObjectArgsAreMapped",
            nil];
}

@end
