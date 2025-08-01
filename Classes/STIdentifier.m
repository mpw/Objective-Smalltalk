//
//  STIdentifier.m
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "STIdentifier.h"
#import "STEvaluator.h"
#import "MPWScheme.h"

@implementation STIdentifier



-initWithName:(NSString*)name
{
    return [super initWithPath:name];
}

+identifierWithName:(NSString*)name
{
    return [[[self alloc] initWithName:name] autorelease];
}


-(NSArray*)componentsOfPath:(NSString*)path
{
    NSArray *rawComponents = [path componentsSeparatedByString:@"/"];
    NSMutableArray  *results=[NSMutableArray array];
    NSMutableString *current=nil;
    for ( NSString *component in rawComponents) {
        if ( [component hasPrefix:@"{"]) {
            current=[[component mutableCopy] autorelease];
            component=nil;
        }
        if ( current && component) {
            [current appendString:@"/"];
            [current appendString:component];
            component=nil;
        }
        if ( [current hasSuffix:@"}"]) {
            component=current;
            current=nil;
        }
        if ( component ){
            [results addObject:component];
        }
    }
    return results;
}

-evaluatedPathComponentsInContext:aContext
{
	NSMutableArray *evaluated = [NSMutableArray array];
	for ( id component in [self pathComponents] ) {
        id evaluatedComponent=component;
		if ( [component hasPrefix:@"{"] && [component hasSuffix:@"}"] ) {
			NSString *nested=[component substringWithRange:NSMakeRange(1, [component length]-2)];

#if 0
            STIdentifier *nestedIdentifier=[STIdentifier identifierWithName:nested];
            evaluatedComponent=[aContext at:nestedIdentifier];
#else
            evaluatedComponent=[aContext evaluateScriptString:nested];
#endif
			evaluatedComponent = [[evaluatedComponent  stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}
        NSAssert3(evaluatedComponent!=nil, @"component '%@' of %@ in evaluated in %@ nil",component, [self identifierName],aContext);
		[evaluated addObject:evaluatedComponent];
	}
	return evaluated;
	
}

-(MPWReference*)bindingWithContext:aContext
{
    return [[aContext schemeForName:[self schemeName]] bindingWithIdentifier:self withContext:aContext];
}

-(NSUInteger)length
{
    NSLog(@"-[STIdentifier length] on %@ -> %@",self,[NSThread callStackSymbols]);
    return [[self name] length];
}

-(NSUInteger)lengthOfBytesUsingEncoding:(int)encoding
{
    NSLog(@"-[STIdentifier lengthOfBytesUsingEncoding:%d] on %@ -> %@",encoding,self,[NSThread callStackSymbols]);
    return [[self name] lengthOfBytesUsingEncoding:encoding];
}

-(int)characterAtIndex:(NSUInteger)theIndex
{
    NSLog(@"-[STIdentifier characterAtIndex:%ld] on %@ -> %@",theIndex,self,[NSThread callStackSymbols]);
    return [[self name] characterAtIndex:theIndex];
}

-(void)getCString:(char*)buffer maxLength:(NSUInteger)maxLen encoding:(int)encoding
{
    NSLog(@"-[STIdentifier getCString:maxLength:encoding:] on %@ -> %@",self,[NSThread callStackSymbols]);
    [[self name] getCString:buffer maxLength:maxLen encoding:encoding];
}

-evaluatedIdentifierNameInContext:aContext
{
#if 0
    return identifierName;
#else
	return [[self evaluatedPathComponentsInContext:aContext] componentsJoinedByString:@"/"];
#endif
}

-resolveRescursiveIdentifierWithContext:aContext
{
    STIdentifier *evaluatedIdentifier = [[[[self class] alloc] initWithPathComponents:[self evaluatedPathComponentsInContext:aContext] scheme:[self schemeName]] autorelease];
//    [evaluatedIdentifier setScheme:[self scheme]];
    return evaluatedIdentifier;
}


-evaluateIn:aContext
{
    MPWScheme *evaluatedScheme = [aContext schemeForName:[self schemeName]];
//    NSLog(@"did get scheme (%@) from context %p/%@: schmes: %p evaluated: %@",[self schemeName],aContext,[aContext class],[aContext schemes],evaluatedScheme);
    if (!evaluatedScheme) {
//        NSLog(@"%@ not found in aContext schemes: %@",[self schemeName],[aContext schemes]);
        [NSException raise:@"unknownscheme" format:@"scheme with name '%@' not found",[self schemeName]];
    }
    
    STIdentifier *evaluatedIdentifier = [self resolveRescursiveIdentifierWithContext:aContext];
//    NSLog(@"evaluatedScheme: %@ evaluatedIdentifier:  %@ context: %@",evaluatedScheme,evaluatedIdentifier,aContext);
	return [evaluatedScheme evaluateIdentifier:evaluatedIdentifier withContext:aContext];
}

-(NSUInteger)hash
{
    return ([[self schemeName] hash] << 1) ^ [[self identifierName] hash];
}

-(BOOL)isEqual:(id)object
{
    id myScheme=[self schemeName];
    id otherScheme=[object schemeName];
    id myName=[self identifierName];
    id otherName=[object identifierName];
    return
    ((myScheme == otherScheme) || [myScheme isEqual:otherScheme]) &&
    ((myName == otherName) || [myName isEqual:otherName]);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: schemeName: %@ identifierName: %@>",
            [self class],self,[self schemeName],[self identifierName]];
    }


-identifier { return self; }

@end

#import <MPWFoundation/DebugMacros.h>

@implementation STIdentifier(testing)

+(void)testNestedIdentifierPathComponents
{
    IDEXPECT( [[self identifierWithName:@"a/{var:c/d}"] pathComponents], (@[ @"a", @"{var:c/d}"]), @"components");
    IDEXPECT( [[self identifierWithName:@"{b}"] pathComponents], (@[ @"{b}"]), @"components");
}


+testSelectors
{
    return @[
             @"testNestedIdentifierPathComponents",
             ];
}

@end

