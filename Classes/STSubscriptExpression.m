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
}

lazyAccessor(MPWMessageExpression, getter, setGetter, computeGetter)

-(MPWMessageExpression*)computeGetter
{
    MPWMessageExpression *expr=[[MPWMessageExpression new] autorelease];
    expr.selector=@selector(at:);
    expr.receiver=self.receiver;
    expr.args=@[ self.subscript];
    return expr;
}

-(id)evaluateIn:(id)aContext
{
    return [[self getter] evaluateIn:aContext];
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
