//
//  MPWBlockExpression.m
//  Arch-S
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWBlockExpression.h"
#import "MPWBlockContext.h"
#import <MPWFoundation/NSNil.h>
#import "MPWIdentifier.h"
#import "MPWStatementList.h"

@implementation MPWBlockExpression

idAccessor( statements, setStatements )
idAccessor( declaredArguments, setDeclaredArguments )

-initWithStatements:newStatements arguments:newArgNames
{
	self=[super init];
	[self setStatements:newStatements];
	[self setDeclaredArguments:newArgNames];
	return self;
}

-statementArray
{
    id statements = [self statements];
    while ( [statements isKindOfClass:[MPWStatementList class]]) {
        statements=[statements statements];
    }
    return statements;
}

+blockWithStatements:newStatements arguments:newArgNames
{
	return [[[self alloc] initWithStatements:newStatements arguments:newArgNames] autorelease];
}

-evaluateIn:aContext
{
	return [MPWBlockContext blockContextWithBlock:self context:aContext];
}

-(void)addToVariablesWritten:(NSMutableSet*)variablesWritten
{
	[statements addToVariablesWritten:variablesWritten];
}

-(void)addToVariablesRead:(NSMutableSet*)variablesRead
{
	[statements addToVariablesRead:variablesRead];
}



-(NSArray*)implicitUsedArguments
{
    NSMutableArray *implicits=[NSMutableArray array];
    for ( MPWIdentifier *identifier in [self variablesRead]) {
        if ( [[identifier identifierName] hasPrefix:@"$"] ) {
            [implicits addObject:[identifier identifierName]];
        }
    }
    return implicits;
}

-(NSArray*)addUnusedImplicitArguments:(NSArray*)usedImplicitarguments
{
    int maxArgNo=-1;
    for (NSString *implicitArgName in usedImplicitarguments) {
        int argNo=[[implicitArgName substringFromIndex:1] intValue];
        maxArgNo=MAX(maxArgNo,argNo);
    }
    NSMutableArray *args=[NSMutableArray array];
    for (int i=0;i<=maxArgNo;i++) {
        [args addObject:[NSString stringWithFormat:@"$%d",i]];
    }
    return args;
}

-(NSArray*)arguments
{
    NSArray *arguments=[self declaredArguments];
    if ( arguments.count == 0) {
        arguments=[self implicitUsedArguments];
        arguments=[self addUnusedImplicitArguments:arguments];
    }
    return arguments;
}


-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: statements: %@ arguments: %@>",[self class],self,statements,[self arguments]];
}


-(void)dealloc
{
	[statements release];
	[declaredArguments release];
	[super dealloc];
}

@end

#import "STCompiler.h"
#import "MPWClassDefinition.h"
#import "MPWScriptedMethod.h"



@implementation MPWBlockExpression(testing)

+(void)testComputeBlockCaptures
{
    NSString *code = @"class __STTestBlockCaptureComputation1 {  -main:args {  var a. a := 10. { a - 10. } value. } }";
    STCompiler *compiler = [STCompiler compiler];
    MPWClassDefinition *theClass = [compiler compile:code];
    MPWScriptedMethod *method=theClass.methods.firstObject;
    
    EXPECTNOTNIL( method, @"got a method");
}

+testSelectors
{
    return @[
        @"testComputeBlockCaptures",
    ];
}

@end

