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
