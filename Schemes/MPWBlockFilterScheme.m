//
//  MPWBlockFilterScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import "MPWBlockFilterScheme.h"
#import <MPWFoundation/MPWGenericReference.h>

@implementation MPWBlockFilterScheme

idAccessor(identifierFilter, setIdentifierFilter)
idAccessor( valueFilter, setValueFilter)

-initWithSource:(MPWScheme*)sourceScheme identifierFilter:idFilter valueFilter:vFilter
{
    self=[super init];
    [self setSource:sourceScheme];
    [self setValueFilter:vFilter];
    [self setIdentifierFilter:idFilter];
    return self;
}


+filterWithSource:aSource idFilter:idFilter valueFilter:vFilter
{
    return [[[self alloc] initWithSource:aSource identifierFilter:idFilter valueFilter:vFilter] autorelease];
}

-filterReference:aReference
{
    if ( [self identifierFilter]){
        NSString *variableName = [aReference path];
        variableName =((FilterBlock)identifierFilter)(variableName);
        aReference = [self referenceForPath:variableName];
    }
    return aReference;
}

-(id)objectForReference:(id)aReference
{
    aReference = [self filterReference:aReference];
    id value=[[self source] objectForReference:aReference];
    if ( valueFilter){
        NSLog(@"before filtering: %@",value);
        value=((FilterBlock)valueFilter)(value);
        NSLog(@"after filtering: %@",value);
    }
    return value;
}

@end

#import "MPWStCompiler.h"

@implementation MPWBlockFilterScheme(tests)


+(void)testSimpleValueFilter
{
    id compiler=[[MPWStCompiler new] autorelease];
    [compiler evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme.  base:/hi := 'Hello World'."];
    [compiler evaluateScriptString:@"scheme:len := MPWBlockFilterScheme filterWithSource:scheme:base idFilter:nil valueFilter:[ :value | value length stringValue.]."];
    id result=[compiler evaluateScriptString:@"len:hi"];
    INTEXPECT([result intValue], 11, @"length of hello world");
}

+(void)testSimpleIdentifierFilter
{
    id compiler=[[MPWStCompiler new] autorelease];
    [compiler evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme.  base:/hi.txt := 'Hello World'."];
    [compiler evaluateScriptString:@"scheme:txt := MPWBlockFilterScheme filterWithSource:scheme:base idFilter:[:id | id,'.txt'.] valueFilter:nil."];
    id result=[compiler evaluateScriptString:@"txt:hi"];
    IDEXPECT(result, @"Hello World", @"hello world");
}

+(void)testIdentifierAndValueFilter
{
    id compiler=[[MPWStCompiler new] autorelease];
    [compiler evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme.  base:/hi.txt := 'Hello World'."];
    [compiler evaluateScriptString:@"scheme:txt := MPWBlockFilterScheme filterWithSource:scheme:base idFilter:[:id | id,'.txt'.] valueFilter:[ :value | value length stringValue.]."];
    id result=[compiler evaluateScriptString:@"txt:hi"];
    INTEXPECT([result intValue], 11, @"length of hello world");
}

+(void)testFilterWorksWithCache
{
    id compiler=[[MPWStCompiler new] autorelease];
    [compiler evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme.  base:/hi.txt := 'Hello World'."];
    [compiler evaluateScriptString:@"scheme:txt := (MPWBlockFilterScheme filterWithSource:scheme:base idFilter:[:id | id,'.txt'.] valueFilter:[ :value | value length stringValue.]) cachedBy:MPWTreeNodeScheme scheme."];
    id result=[compiler evaluateScriptString:@"txt:hi"];
    INTEXPECT([result intValue], 11, @"length of hello world");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testSimpleValueFilter",
            @"testSimpleIdentifierFilter",
            @"testIdentifierAndValueFilter",
           @"testFilterWorksWithCache",
            nil];
}

@end
