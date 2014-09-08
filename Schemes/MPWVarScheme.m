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
#import "MPWIdentifier.h"

@implementation MPWVarScheme
-(Class)bindingClass
{
    return [MPWVARBinding class];
}

-(MPWBinding *)bindingForName:(NSString *)variableName inContext:(id)aContext
{
    MPWBinding *binding = [aContext cachedBindingForName:variableName];
    if (!binding)  {
        binding=[self createBindingForName:variableName inContext:aContext];
        [aContext cacheBinding:binding forName:variableName];
    }
    return binding;
}


-createBindingForName:(NSString*)variableName inContext:aContext
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
    [theBinding setIdentifier:[MPWIdentifier identifierWithName:firstName]];
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


-(NSArray*)childrenOf:(MPWBinding*)binding inContext:aContext
{
    NSArray *allNames=[[aContext localVars] allKeys];
    NSMutableArray *bindings=[NSMutableArray array];
    for ( NSString *variableName in allNames) {
        [bindings addObject:[self bindingForName:variableName inContext:aContext]];
    }
    return bindings;
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

