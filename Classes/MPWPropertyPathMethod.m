//
//  MPWPropertyPathGetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import "MPWPropertyPathMethod.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWReferenceTemplate.h>
#import "MPWPropertyPathDefinition.h"
#import "MPWMethodHeader.h"

@interface MPWPropertyPathMethod()

@property (nonatomic, strong) MPWTemplateMatchingStore *store;
@property (nonatomic, strong) NSString *declarationString;

@end

@implementation MPWPropertyPathMethod
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



-(instancetype)initWithPropertyPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths verb:(MPWRESTVerb)newVerb
{
    static struct {
        MPWRESTVerb verb;
        int         numExtraParams;
        NSString    *declstring;
    } defaults[] = {
        {MPWRESTVerbGET, 1,@"at:aReference"},
        {MPWRESTVerbPUT, 2,@"<void>at:aReference put:newValue"},
    };
    if ( self=[super init] ) {
        int whichDefault=-1;
        for (int i=0;i<2;i++) {
            if ( newVerb == defaults[i].verb) {
                whichDefault=i;
                break;
            }
        }
        NSAssert1(whichDefault>=0, @"unsupported REST Verb: %d",newVerb);
        
        self.store = [MPWTemplateMatchingStore store];
        [self setupStoreWithPaths:newPaths verb:newVerb];
        self.methodHeader=[MPWMethodHeader methodHeaderWithString:defaults[whichDefault].declstring];
        numExtraparams = defaults[whichDefault].numExtraParams;
        self.declarationString = defaults[whichDefault].declstring;
    }
    return self;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    int numExtras=numExtraparams;
    id extraParameters[numExtras+2];
    [parameters getObjects:extraParameters range:NSMakeRange(0,numExtras)];
    id ref = extraParameters[0];
    return [self.store at:ref for:target with:extraParameters count:numExtras];
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
