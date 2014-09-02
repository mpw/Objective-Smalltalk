//
//  MPWIdentifier.m
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWIdentifier.h"
#import "MPWEvaluator.h"
#import "MPWScheme.h"

@implementation MPWIdentifier

idAccessor( scheme, setScheme )
idAccessor( schemeName, setSchemeName )
idAccessor( identifierName, setIdentifierName )

-initWithName:(NSString*)name
{
    self=[super init];
    [self setIdentifierName:name];
    return self;
}

+identifierWithName:(NSString*)name
{
    return [[[self alloc] initWithName:name] autorelease];
}

-schemeWithContext:aContext
{
	id theScheme=[self scheme];
    if ( theScheme == nil ) {
        [NSException raise:@"invalidscheme" format:@"scheme %@ could not be evaluated", [self schemeName]];
    }
//	NSAssert1( theScheme!=nil , );
	return theScheme;
}

-pathComponents
{
	return [[self identifierName] componentsSeparatedByString:@"/"];
}

-evaluatedPathComponentsInContext:aContext
{
	NSMutableArray *evaluated = [NSMutableArray array];
	for ( id component in [self pathComponents] ) {
        id evaluatedComponent=component;
		if ( [component hasPrefix:@"{"] && [component hasSuffix:@"}"] ) {
			NSString *nested=[component substringWithRange:NSMakeRange(1, [component length]-2)];
			evaluatedComponent=[aContext evaluateScriptString:nested];
			evaluatedComponent = [[evaluatedComponent  stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}
        NSAssert3(evaluatedComponent!=nil, @"component '%@' of %@ in evaluated in %@ nil",component, [self identifierName],aContext);
		[evaluated addObject:evaluatedComponent];
	}
	return evaluated;
	
}

-(MPWBinding*)bindingWithContext:aContext
{
    return [[self scheme] bindingWithIdentifier:self withContext:aContext];
}

-evaluatedIdentifierNameInContext:aContext
{
#if 0
    return identifierName;
#else
	return [[self evaluatedPathComponentsInContext:aContext] componentsJoinedByString:@"/"];
#endif
}

-evaluateIn:aContext
{	
	return [[self schemeWithContext:aContext] evaluateIdentifier:self withContext:aContext];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: schemeName: %@ identifierName: %@>",
            [self class],self,[self schemeName],[self identifierName]];
    }

-(void)dealloc
{
	[scheme release];
	[schemeName release];
	[identifierName release];
	[super dealloc];
}

@end
