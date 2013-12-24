//
//  MPWVarScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWVarScheme.h"
#import "MPWVARBinding.h"
#import "MPWEvaluator.h"

@implementation MPWVarScheme

-(Class)bindingClass
{
    return [MPWVARBinding class];
}

-bindingForName:(NSString*)variableName inContext:aContext
{
    NSString *firstName=variableName;
    MPWBinding *theBinding=nil;
    NSString *remainder=nil;
    NSRange firstPathSeparator=[variableName rangeOfString:@"/"];
    BOOL isCompound = firstPathSeparator.location !=  NSNotFound;
    if ( isCompound ) {
        firstName=[variableName substringToIndex:firstPathSeparator.location];
        remainder=[variableName substringFromIndex:firstPathSeparator.location+1];
    }
    theBinding=[aContext bindingForLocalVariableNamed:firstName];
    if ( isCompound) {
		theBinding= [[[[self bindingClass] alloc] initWithBaseObject:[theBinding value] path:remainder] autorelease];
    }
    return theBinding;
#if 0
	id localVars = [self localVarsForContext:aContext];
	id binding=nil;
	if ( [variableName rangeOfString:@"/"].location != NSNotFound ) {
		binding= [[[[self bindingClass] alloc] initWithBaseObject:localVars path:variableName] autorelease];
		//		NSLog(@"kvbinding %@ ",variableName);
	} else {
		binding = [localVars objectForKey:variableName];
        if ( !binding && [variableName isEqual:@"context"] ) {
            return [MPWBinding bindingWithValue:aContext];
        }
	}
	return binding;
#endif
}

-(id)valueForBinding:aBinding
{
    return [[self bindingForName:[aBinding name] inContext:[aBinding defaultContext]] value ];
}

@end

@implementation NSArray(mykvc)


-valueForUndefinedKey:(NSString*)aKey
{
	if ( isdigit( [aKey characterAtIndex:0] )) {
		return [self objectAtIndex:[aKey intValue]];
	} else {
		return [super valueForUndefinedKey:aKey];
	}
}


@end

