//
//  MPWPropertyPathGetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import "MPWPropertyPathGetter.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWReferenceTemplate.h>
#import "MPWPropertyPathDefinition.h"
#import "MPWMethodHeader.h"

@interface MPWPropertyPathGetter()

@property (nonatomic, strong) MPWTemplateMatchingStore *store;

@end

@implementation MPWPropertyPathGetter
{
    int         numExtraparams;
}
 
-(void)setupStoreWithPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths verb:(MPWRESTVerb)theVerb
{
    for ( MPWPropertyPathDefinition *def in newPaths) {
        MPWScriptedMethod *method = [def methodForVerb:theVerb];
        if ( method ) {
            self.store[def.propertyPath] = method;
        }
    }
}

-(MPWRESTVerb)restVerb
{
    return MPWRESTVerbGET;
}

-(instancetype)initWithPropertyPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths verb:(MPWRESTVerb)newVerb numExtraParams:(int)newNumExtraParams
{
    if ( self=[super init] ) {
        self.store = [MPWTemplateMatchingStore store];
        [self setupStoreWithPaths:newPaths verb:newVerb];
        self.methodHeader=[MPWMethodHeader methodHeaderWithString:[self declarationString]];
        numExtraparams = newNumExtraParams;
    }
    return self;
}

CONVENIENCEANDINIT(getter, WithPropertyPathDefinitions:newPaths)
{
    return [self initWithPropertyPaths:newPaths verb:[self restVerb] numExtraParams:[self numberOfExtraParameters]];
}


-(int)numberOfExtraParameters
{
    return 1;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    int numExtras=numExtraparams;
    id extraParameters[numExtras+2];
    [parameters getObjects:extraParameters range:NSMakeRange(0,numExtras)];
    id ref = extraParameters[0];
    return [self.store at:ref for:target with:extraParameters count:numExtras];
}

-declarationString
{
    return @"at:aReference";
}

-(void)setContext:(id)newVar
{
    [super setContext:newVar];
    [self.store setContext:newVar];
}

-(void)dealloc
{
    [_store release];
    [super dealloc];
}

-(NSString*)script
{
    return @" 'property path'. ";
}

-(BOOL)isPropertyPathDefs
{
    return YES;
}

@end
