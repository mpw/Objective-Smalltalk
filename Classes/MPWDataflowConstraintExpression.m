//
//  MPWDataflowConstraintExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/31/15.
//
//

#import "MPWDataflowConstraintExpression.h"
#import "STSimpleDataflowConstraint.h"
#import "MPWIdentifierExpression.h"

@implementation MPWAbstractStore(constraintCreation)

-(MPWLoggingStore*)syncToTarget:(id <MPWStorage>)target
{
    MPWRESTCopyStream *copier = [[MPWRESTCopyStream alloc] initWithSource:self target:target];
    MPWLoggingStore *logger = [self logger];
    [logger setLog:copier];
    return logger;
}

@end

@implementation MPWIdentifierExpression(constraintCreation)


-(id)syncToTarget:(MPWIdentifierExpression*)target inContext:aContext
{
    STSimpleDataflowConstraint* constraint=nil;
    MPWBinding *sourceBinding=[[self identifier] bindingWithContext:aContext];
    MPWBinding *targetBinding=[[target identifier] bindingWithContext:aContext];
    if ( [[sourceBinding value] conformsToProtocol:@protocol(MPWStorage) ]) {
        return [[sourceBinding value] syncToTarget:[targetBinding value]];
    }
    constraint = [STSimpleDataflowConstraint constraintWithSource:sourceBinding target:targetBinding];
    if ( [sourceBinding respondsToSelector:@selector(store)]) {
        MPWLoggingStore *sourceStore = [sourceBinding store];
        if ( [sourceStore isKindOfClass:[MPWLoggingStore class]]) {
            [sourceStore setLog:constraint];
        }
    }
    return constraint;
}

@end

@implementation MPWExpression(constraintCreation)

-(STSimpleDataflowConstraint*)syncToTarget:(MPWIdentifierExpression*)target inContext:aContext
{
     [NSException raise:@"unsupported" format:@"Constraints on expressions not supperted yet"];
    return nil;
}

@end


@implementation MPWDataflowConstraintExpression


-(id)evaluateIn:(id)aContext
{
    if ( [lhs isKindOfClass:[MPWIdentifierExpression class]] ) {
        return [rhs syncToTarget:lhs inContext:aContext];
    }  else {
        [NSException raise:@"typecheck" format:@"LHS of |= dataflow constraint must be identifier"];
    }
    return nil;
    
}

@end



@implementation MPWDataflowConstraintExpression(testing)


+(void)testExpressionReturnsDataflowConstraint
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"a ← 3. b ← 5."];
    STSimpleDataflowConstraint *s=[compiler evaluateScriptString:@"a |= b."];
    EXPECTTRUE([s isKindOfClass:[STSimpleDataflowConstraint class]],@"should return a dataflow constraint");
}

+(void)testConstraintIsUsable
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"a ← 3. b ← 5."];
    STSimpleDataflowConstraint *s=[compiler evaluateScriptString:@"a |= b."];
    [s update];
    IDEXPECT( [compiler evaluateScriptString:@"a"],@5, @"did update");
}

+(void)testConstraintCanBeAutomated
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"scheme:l := #{} logger."];
    [compiler evaluateScriptString:@"l:a ← 3. l:b ← 5."];
    [compiler evaluateScriptString:@"constraint := (l:a |= l:b)."];
    [compiler evaluateScriptString:@"l:b := 42"];
    IDEXPECT( [compiler evaluateScriptString:@"l:a"],@42, @"did update");
}

+(void)testAutomatedConstraintCanBeDefaultScheme
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"scheme:l := MPWLoggingStore storeWithSource: MPWDictStore store."];
    [compiler evaluateScriptString:@"scheme:default := scheme:l."];
    [compiler evaluateScriptString:@"a ← 3. b ← 5."];
    [compiler evaluateScriptString:@"constraint := (a |= b)."];
    [compiler evaluateScriptString:@"b := 42"];
    IDEXPECT( [compiler evaluateScriptString:@"a"],@42, @"did update");
}

+(void)testRHSCanBeExpression
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"scheme:l := MPWLoggingStore storeWithSource: MPWDictStore store."];
    [compiler evaluateScriptString:@"scheme:default := scheme:l."];
    [compiler evaluateScriptString:@"a ← 3. b ← 5. c ← 7"];
    [compiler evaluateScriptString:@"constraint := (a |= b+c)."];
    [compiler evaluateScriptString:@"b := 42"];
    IDEXPECT( [compiler evaluateScriptString:@"a"],@49, @"did update a when b changed");
    [compiler evaluateScriptString:@"c := 1"];
    IDEXPECT( [compiler evaluateScriptString:@"a"],@43, @"did update a when c changed");
}

+(void)testCanConstrainEntireStores
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler evaluateScriptString:@"scheme:source := MPWDictStore store logger."];
    [compiler evaluateScriptString:@"scheme:target := MPWDictStore store."];
    [compiler evaluateScriptString:@"source:a ← 3. source:b ← 5."];
    [compiler evaluateScriptString:@"target:a ← 12. target:b ← 14."];
    [compiler evaluateScriptString:@"scheme:constrained := scheme:target |= scheme:source."];
    [compiler evaluateScriptString:@"scheme:source := scheme:constrained."];
    [compiler evaluateScriptString:@"source:a := 42"];
    IDEXPECT( [compiler evaluateScriptString:@"target:a"],@42, @"a in source target");
    [compiler evaluateScriptString:@"source:b := 1"];
    IDEXPECT( [compiler evaluateScriptString:@"target:b"],@1, @"did update b in target");
}


+testSelectors
{
    return @[
        @"testExpressionReturnsDataflowConstraint",
        @"testConstraintIsUsable",
        @"testConstraintCanBeAutomated",
        @"testAutomatedConstraintCanBeDefaultScheme",
        @"testCanConstrainEntireStores",
//        @"testRHSCanBeExpression",
    ];
}

@end
