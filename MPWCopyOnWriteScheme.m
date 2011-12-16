//
//  MPWCopyOnWriteScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 12/9/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MPWCopyOnWriteScheme.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWStCompiler.h"

@implementation MPWCopyOnWriteScheme

objectAccessor(MPWScheme, readOnly, setReadOnly)
objectAccessor(MPWScheme, readWrite, setReadWrite)

-valueForBinding:aBinding
{
    id result=nil;
   result=[[self readWrite] valueForBinding:aBinding];
    if ( !result ) {
        result=[[self readOnly] valueForBinding:aBinding];
    }
    return result;
}

-(void)setValue:newValue forBinding:aBinding
{
    [[self readWrite] setValue:newValue forBinding:aBinding];
}


-(void)dealloc
{
    [readOnly release];
    [readWrite release];
    [super dealloc];
}

@end

@implementation MPWCopyOnWriteScheme(testing)

+_testInterpreterWithCOW
{
    MPWStCompiler *interpreter=[[MPWStCompiler new] autorelease];
    [interpreter evaluateScriptString:@" site := MPWTreeNodeScheme scheme."];
    [interpreter evaluateScriptString:@" scheme:cms := site "];
    [interpreter evaluateScriptString:@" cms:/hi := 'hello world' "];
    [interpreter evaluateScriptString:@" scheme:cow := MPWCopyOnWriteScheme scheme."];
    [interpreter evaluateScriptString:@" scheme:cow setReadOnly:site."];
    [interpreter evaluateScriptString:@" writer :=  MPWTreeNodeScheme scheme."];
    [interpreter evaluateScriptString:@" scheme:write :=  writer."];
    [interpreter evaluateScriptString:@" scheme:cow setReadWrite: writer."];
    

    return interpreter;
}


+(void)testReadFromBase
{
    MPWStCompiler *interpreter = [self _testInterpreterWithCOW];
    IDEXPECT([interpreter evaluateScriptString:@" cow:/hi "],@"hello world",@"read of base via cow");
}


+(void)testCopyOverridesBase
{
    MPWStCompiler *interpreter = [self _testInterpreterWithCOW];
    [interpreter evaluateScriptString:@" write:/hi := 'hello bozo' "];
    IDEXPECT([interpreter evaluateScriptString:@" write:/hi "],@"hello bozo",@"read of writer");
    IDEXPECT([interpreter evaluateScriptString:@" cow:/hi "],@"hello bozo",@"read of writer via cow");
}


+(void)testWriteOnCOWDoesntAffectBase
{
    MPWStCompiler *interpreter = [self _testInterpreterWithCOW];
    [interpreter evaluateScriptString:@" cow:/hi := 'hello bozo' "];
    IDEXPECT([interpreter evaluateScriptString:@" cow:/hi "],@"hello bozo",@"read of writer via cow");
    IDEXPECT([interpreter evaluateScriptString:@" write:/hi "],@"hello bozo",@"read of writer via cow");
    IDEXPECT([interpreter evaluateScriptString:@" cms:/hi "],@"hello world",@"read of base");
}

+testSelectors
{
    return [NSArray arrayWithObjects:   
            @"testReadFromBase",
            @"testCopyOverridesBase",
            @"testWriteOnCOWDoesntAffectBase",
            nil];
}

@end