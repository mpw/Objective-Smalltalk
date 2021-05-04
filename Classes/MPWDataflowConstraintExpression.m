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

@implementation MPWDataflowConstraintExpression

-(MPWBinding*)bindingForIdentifier:(MPWIdentifierExpression*)expr context:aContext
{
    return [[expr identifier] bindingWithContext:aContext];
}

-(id)evaluateIn:(id)aContext
{
    if ( [lhs isKindOfClass:[MPWIdentifierExpression class]] ) {
        MPWBinding *lhb=[self bindingForIdentifier:lhs context:aContext];
        STSimpleDataflowConstraint* constraint=nil;
        if ([rhs isKindOfClass:[MPWIdentifierExpression class]] )  {
            MPWBinding *rhb=[self bindingForIdentifier:(MPWIdentifierExpression*)rhs context:aContext];
            constraint = [STSimpleDataflowConstraint constraintWithSource:rhb target:lhb];
            if ( [rhb respondsToSelector:@selector(store)]) {
                MPWLoggingStore *sourceStore = [rhb store];
                if ( [sourceStore isKindOfClass:[MPWLoggingStore class]]) {
                    [sourceStore setLog:constraint];
                }
            }
        } else  if ([rhs isKindOfClass:[MPWExpression class]] )  {
            return nil;
        }
        return constraint;
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
    [compiler evaluateScriptString:@"scheme:l := MPWLoggingStore storeWithSource: MPWDictStore store."];
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


+testSelectors
{
    return @[
        @"testExpressionReturnsDataflowConstraint",
        @"testConstraintIsUsable",
        @"testConstraintCanBeAutomated",
        @"testAutomatedConstraintCanBeDefaultScheme",
//        @"testRHSCanBeExpression",
    ];
}

@end
