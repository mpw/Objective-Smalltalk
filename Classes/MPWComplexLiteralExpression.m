//
//  MPWComplexLiteralExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 07.02.21.
//

#import "MPWComplexLiteralExpression.h"

@implementation MPWComplexLiteralExpression

-(Class)literalClass
{
    Class theLiteralClass=Nil;
    if ( self.literalClassName ) {
//        NSLog(@"set literal class name: '%@'",self.literalClassName);
        theLiteralClass=NSClassFromString(self.literalClassName);
//        NSLog(@"literal class: %@",self.literalClass);
        if ( !theLiteralClass ) {
            [NSException raise:@"undefinedclass" format:@"Literal Class %@ undefined for dictionary literal",self.literalClassName];
        }
    }
    return theLiteralClass;
}

-(id <MPWStorage>)builderForContext:(MPWEvaluator*)aContext
{
    return [aContext schemeForName:@"builder"];
}

-(Class)classForContext:(MPWEvaluator*)aContext
{
    id <MPWStorage> builder = [self builderForContext:aContext];
    NSAssert2(builder!= nil, @"builder for context: %@ schemes: %@",aContext,[aContext schemeForName:@"scheme"]);
    NSString *className = self.literalClassName;
    if (!className) {
        className = @"NSMutableDictionary";
    }
//    Class finalClass=self.literalClass;
    Class finalClass=[builder at:className];
    if (!finalClass) {
        NSLog(@"builder %@ from context %@ did not deliver a class for name '%@'",builder,aContext,className);
        finalClass=[NSMutableDictionary class];
    }
    return finalClass;
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
