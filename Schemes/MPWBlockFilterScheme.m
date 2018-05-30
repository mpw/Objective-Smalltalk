//
//  MPWBlockFilterScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import "MPWBlockFilterScheme.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWBlockFilterScheme

idAccessor(identifierFilter, setIdentifierFilter)
idAccessor( valueFilter, setValueFilter)

-(instancetype)initWithSource:(MPWAbstractStore*)sourceStore identifierFilter:idFilter valueFilter:vFilter
{
    self=[super initWithSource:sourceStore];
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

-(MPWGenericReference*)mapReference:(MPWGenericReference*)aReference
{
    if ( [self identifierFilter]){
        NSString *variableName = [aReference path];
        variableName =((FilterBlock)identifierFilter)(variableName);
        aReference = [self referenceForPath:variableName];
    }
    return aReference;
}
-mapRetrievedObject:anObject
{
    if ( valueFilter){
        anObject=((FilterBlock)valueFilter)(anObject);
    }
    return anObject;
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
