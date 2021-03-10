//
//  MPWComplexLiteralExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 07.02.21.
//

#import "MPWComplexLiteralExpression.h"
#import "MPWEvaluator.h"

@implementation MPWComplexLiteralExpression


-(id <MPWStorage>)builderForContext:(MPWEvaluator*)aContext
{
    return (id <MPWStorage>)[aContext schemeForName:@"builder"];
}

-(Class)classForContext:(MPWEvaluator*)aContext
{
    id <MPWStorage> builder = [self builderForContext:aContext];
    NSAssert2(builder!= nil, @"builder for context: %@ schemes: %@",aContext,[aContext schemeForName:@"scheme"]);
    NSString *className = self.literalClassName;
    if (!className) {
        className = @"NSMutableDictionary";
    }
    Class finalClass=[builder at:className];
    if (!finalClass) {
//        NSLog(@"builder %@ from context %@ did not deliver a class for name '%@'",builder,aContext,className);
    }
    return finalClass;
}

-factoryForContext:(MPWEvaluator*)aContext
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

+(id)factoryForContext:(MPWEvaluator*)aContext
{
    return [self factory];
}

@end
