//
//  MPWPlistScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/6/12.
//
//

#import "MPWPlistScheme.h"
#import "MPWGenericBinding.h"
#import "MPWVARBinding.h"


@implementation MPWPlistScheme

idAccessor(plist, setPlist)

-localVarsForContext:aContext
{
    return plist;
}


//--- copy of superclass

-bindingForName:(NSString*)variableName inContext:aContext
{
	id localVars = [self localVarsForContext:aContext];
	id binding=nil;
	if ( [variableName rangeOfString:@"/"].location != NSNotFound ) {
		binding= [[[MPWVARBinding alloc] initWithBaseObject:localVars path:variableName] autorelease];
		//		NSLog(@"kvbinding %@ ",variableName);
	} else {
		id value = [localVars objectForKey:variableName];
        if ( value ) {
            return [MPWBinding bindingWithValue:value];
        }
	}
	return binding;
}




@end

@implementation MPWPlistScheme(testing)

+(void)testBasicSetupAndEval
{
    MPWPlistScheme *s=[self scheme];
    NSDictionary *d=@{ @"theAnswer": @"52" };
    [s setPlist:d];
    MPWBinding *b=[s bindingForName:@"theAnswer" inContext:nil];
    IDEXPECT([b class], [MPWBinding class],@"class of binding");
    IDEXPECT([b value], @"52", @"theAnswer");
    
}

+testSelectors
{
    return @[
             @"testBasicSetupAndEval",
             ];
}

@end
