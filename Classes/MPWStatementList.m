//
//  MPWStatementList.m
//  Arch-S
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWStatementList.h"
#import "STEvaluator.h"
#import "MPWObjCGenerator.h"

@implementation MPWStatementList

objectAccessor( NSMutableArray*, statements, setStatements )

+statementList
{
	return [[[self alloc] init] autorelease];
}

-(void)accumulateLocalVars:(NSMutableArray*)vars
{
    for (STExpression *statement in statements) {
        [statement accumulateLocalVars:vars];
    }
}


-init
{
	self=[super init];
	[self setStatements:[NSMutableArray array]];
	return self;
}

-(void)addStatement:aStatement
{
    if ( [aStatement isKindOfClass:[NSArray class]]) {
        for ( id singleSatement in aStatement) {
            [self addStatement:singleSatement];
        }
    }
	[statements addObject:aStatement];
}

-evaluateIn:aContext
{
	if ( [statements count] > 1 ) {
		[[aContext do] evaluate:[[statements subarrayWithRange:NSMakeRange(0,[statements count]-1 )] each]];
	}
	return [aContext evaluate:[statements lastObject]];
}

-(void)addToVariablesWritten:(NSMutableSet*)variablesWritten
{
	[[statements do] addToVariablesWritten:variablesWritten];
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[[statements do] addToVariablesRead:variablesRead];
}


-(void)generateObjectiveCOn:aGenerator
{
    [aGenerator writeStatements:[self statements]];
}


-compileIn:aContext
{
	return self;
}

-(void)accumulateBlocks:(NSMutableArray*)blocks
{
    for ( id statement in [self statements] ) {
        [statement accumulateBlocks:blocks];
    }
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: %@>",[self class],self,statements];
}

-(void)dealloc
{
	[statements release];
	[super dealloc];
}

@end
