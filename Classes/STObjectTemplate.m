//
//  STObjectTemplate.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 13.02.21.
//

#import "STObjectTemplate.h"
#import "MPWEvaluator.h"

@implementation STObjectTemplate

-(id)evaluateIn:(MPWEvaluator*)aContext
{
    MPWScheme *scheme=[aContext schemeForName:@"template"];
    [scheme at:self.className put:self.literal];
    return self;
}


-(void)dealloc
{
    [_className release];
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
