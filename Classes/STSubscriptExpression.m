//
//  STSubscriptExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 29.07.21.
//

#import "STSubscriptExpression.h"
#import "MPWMessageExpression.h"

@interface STSubscriptExpression()


@end

@implementation STSubscriptExpression
{
    MPWMessageExpression *getter;
    MPWMessageExpression *setter;
}

lazyAccessor(MPWMessageExpression*, getter, setGetter, computeGetter)
lazyAccessor(MPWMessageExpression*, setter, setSetter, computeSetter)

-(MPWMessageExpression*)computeGetter
{
    MPWMessageExpression *expr=[[MPWMessageExpression new] autorelease];
    expr.selector=@selector(at:);
    expr.receiver=self.receiver;
    expr.args=@[ self.subscript];
    return expr;
}

-(MPWMessageExpression*)computeSetter
{
    MPWMessageExpression *expr=[[MPWMessageExpression new] autorelease];
    expr.selector=@selector(at:put:);
    expr.receiver=self.receiver;
    expr.args=[[@[ self.subscript, @"placeholder"] mutableCopy] autorelease];
    return expr;
}

-evaluateAssignmentOf:value in:aContext
{
    MPWMessageExpression *s=[self setter];
    s.args=@[ setter.args.firstObject, value];
    [s evaluateIn:aContext];
    return value;
}

-(id)evaluateIn:(id)aContext
{
    return [[self getter] evaluateIn:aContext];
}

-(void)addToVariablesRead:(NSMutableSet *)variableList
{
    [self.receiver addToVariablesRead:variableList];
    [self.subscript addToVariablesRead:variableList];
}

-(void)dealloc
{
    [_receiver release];
    [_subscript release];
    [getter release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STSubscriptExpression(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
