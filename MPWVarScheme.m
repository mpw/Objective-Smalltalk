//
//  MPWVarScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWVarScheme.h"
#import "MPWVARBinding.h"

@implementation MPWVarScheme

-localVarsForContext:aContext
{
	return [aContext localVars];
}



-bindingForName:(NSString*)variableName inContext:aContext
{
	id localVars = [self localVarsForContext:aContext];
	id binding=nil;
	if ( [variableName rangeOfString:@"/"].location != NSNotFound ) {
		binding= [[[MPWVARBinding alloc] initWithBaseObject:localVars path:variableName] autorelease];
		//		NSLog(@"kvbinding %@ ",variableName);
	} else {
		binding = [localVars objectForKey:variableName];
	}
	return binding;
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

