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
    if ( [rhs isKindOfClass:[MPWIdentifierExpression class]] &&
        [lhs isKindOfClass:[MPWIdentifierExpression class]] ) {
        MPWBinding *lhb=[self bindingForIdentifier:lhs context:aContext];
        MPWBinding *rhb=[self bindingForIdentifier:(MPWIdentifierExpression*)rhs context:aContext];
        return [STSimpleDataflowConstraint constraintWithSource:rhb target:lhb];
    } else {
        [NSException raise:@"typecheck" format:@"Both LHS and RHS of |= dataflow constraint must be identifiers"];
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

+testSelectors
{
    return @[
        @"testExpressionReturnsDataflowConstraint",
        @"testConstraintIsUsable",
        @"testConstraintIsUsable",
    ];
}

@end
