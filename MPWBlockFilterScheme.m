//
//  MPWBlockFilterScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import "MPWBlockFilterScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWBlockFilterScheme

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

-(id)_bindingForName:(NSString *)variableName inContext:(id)aContext
{
    NSLog(@"original path: %@",variableName);
    if ( [self identifierFilter]){
        variableName=((FilterBlock)identifierFilter)(variableName);
    }
    NSLog(@"mapped path: %@",variableName);
    return [super bindingForName:variableName inContext:aContext];
}

+filterWithSource:aSource idFilter:idFilter valueFilter:vFilter
{
    return [[[self alloc] initWithSource:aSource identifierFilter:idFilter valueFilter:vFilter] autorelease];
}

-_baseBindingForBinding:aBinding
{
    //    NSLog(@"-[%@ valueForBinding: %@]",self,[aBinding path]);
    if (  [aBinding scheme] != [self source] ) {
        //        NSLog(@"modifying non var-scheme later");
        aBinding=[self _bindingForName:[aBinding path] inContext:[aBinding defaultContext]];
    }
    //    MPWBinding *binding = [self bindingForName:[aBinding path] inContext:nil];
    return aBinding;
}


-valueForBinding:(MPWGenericBinding*)aBinding
{
    aBinding = [self _baseBindingForBinding:aBinding];
//    NSLog(@"path: %@",[aBinding path]);
    id value=[[self source] valueForBinding:aBinding];
    if ( valueFilter){
//        NSLog(@"will filter: %p/%@",value,[value class]);
        value=((FilterBlock)valueFilter)(value);
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