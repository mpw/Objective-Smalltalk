//
//  MPWComplexLiteralExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 07.02.21.
//

#import "MPWComplexLiteralExpression.h"
#import "STEvaluator.h"

@implementation MPWComplexLiteralExpression


-(id <MPWStorage>)builderForContext:(STEvaluator*)aContext
{
    return (id <MPWStorage>)[aContext schemeForName:@"builder"];
}

-(NSString*)defaultLiteralClassName
{
    return @"NSMutableDictionary";
}

-(Class)classForContext:(STEvaluator*)aContext
{
    id <MPWStorage> builder = [self builderForContext:aContext];
    NSAssert2(builder!= nil, @"builder for context: %@ schemes: %@",aContext,[aContext schemeForName:@"scheme"]);
    NSString *className = self.literalClassName;
    if (!className) {
        className = [self defaultLiteralClassName];
    }
    Class finalClass=[builder at:className];
    if (!finalClass) {
        [NSException raise:@"classnotfound" format:@"Class '%@' not found in literal expression",className];
    }
    return finalClass;
}

-factoryForContext:(STEvaluator*)aContext
{
    return [[self classForContext:aContext] factoryForContext:aContext];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWComplexLiteralExpression(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			];
}

@end


@implementation NSObject(factory)

+(id)factory
{
    return self;
}

+(id)factoryForContext:(STEvaluator*)aContext
{
    return [self factory];
}

@end
