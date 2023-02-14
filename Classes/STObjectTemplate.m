//
//  STObjectTemplate.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 13.02.21.
//

#import "STObjectTemplate.h"
#import "STEvaluator.h"

@implementation STObjectTemplate

-(id)evaluateIn:(STEvaluator*)aContext
{
    MPWScheme *scheme=[aContext schemeForName:@"template"];
    [scheme at:self.literalClassName put:self.literal];
    return self;
}


-(void)dealloc
{
    [_literalClassName release];
    [_literal release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STObjectTemplate(testing) 

+(void)someTest
{
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
