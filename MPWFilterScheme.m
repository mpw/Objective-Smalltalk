//
//  MPWFilterScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import "MPWFilterScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWFilterScheme

idAccessor(identifierFilter, setIdentifierFilter)
idAccessor( valueFilter, setValueFilter)
objectAccessor(MPWScheme, source, setSource)

-initWithSource:(MPWScheme*)sourceScheme identifierFilter:idFilter valueFilter:vFilter
{
    self=[super init];
    [self setSource:sourceScheme];
    [self setValueFilter:vFilter];
    [self setIdentifierFilter:idFilter];
    return self;
}

-(id)bindingForName:(NSString *)variableName inContext:(id)aContext
{
    if ( [self identifierFilter]){
        variableName=((FilterBlock)identifierFilter)(variableName);
    }
    return [super bindingForName:variableName inContext:aContext];
}

+filterWithSource:aSource idFilter:idFilter valueFilter:vFilter
{
    return [[[self alloc] initWithSource:aSource identifierFilter:idFilter valueFilter:vFilter] autorelease];
}

-valueForBinding:(MPWGenericBinding*)aBinding
{
    id value=[[self source] valueForBinding:aBinding];
    if ( valueFilter){
        value=((FilterBlock)valueFilter)(value);
    }
    return value;
}

@end

#import "MPWStCompiler.h"

@implementation MPWFilterScheme(tests)

+(void)testSimpleValueFilter
{
    id compiler=[[MPWStCompiler new] autorelease];
    [compiler evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme.  base:/hi := 'Hello World'."];
    [compiler evaluateScriptString:@"scheme:len := MPWFilterScheme filterWithSource:scheme:base idFilter:nil valueFilter:[ :value | value length stringValue.]."];
    id result=[compiler evaluateScriptString:@"len:hi"];
    INTEXPECT([result intValue], 11, @"length of hello world");
}

+(void)testSimpleVIdentifierFilter
{
    id compiler=[[MPWStCompiler new] autorelease];
    [compiler evaluateScriptString:@"scheme:base := MPWTreeNodeScheme scheme.  base:/hi.txt := 'Hello World'."];
    [compiler evaluateScriptString:@"scheme:txt := MPWFilterScheme filterWithSource:scheme:base idFilter:[:id | id,'.txt'.] valueFilter:nil."];
    id result=[compiler evaluateScriptString:@"txt:hi"];
    IDEXPECT(result, @"Hello World", @"hello world");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testSimpleValueFilter",
            @"testSimpleVIdentifierFilter",
            nil];
}

@end